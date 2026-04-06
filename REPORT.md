# Spoke-to-Spoke Lab — Validation Report

## Summary

This report validates the spoke-to-spoke traffic hairpinning problem through a VPN gateway and confirms two independent fixes that eliminate the gateway from the data path:

1. **Direct Peering** — Remove forced tunneling UDR, disable gateway transit, add spoke-to-spoke VNet peering
2. **Adjacent Private Endpoint** — Place private endpoints in the consumer's VNet so traffic stays local (no routing changes needed)

**Test environment**: Azure hub-and-spoke lab in `rg-spoke-to-spoke-lab` (centralus)  
**Test workload**: 1 GB file upload/download cycles between `vm-dbrx` (Spoke 1) and ADLS Gen2 private endpoint (Spoke 2) using azcopy  
**Test duration**: 15 minutes per configuration  
**Date**: 2026-04-05

---

## The Problem: VPN Gateway Hairpin

### Architecture (Broken State)

```
  Spoke 1 (vm-dbrx)          Hub (vnet-hub)          Spoke 2 (ADLS PE)
  10.101.0.0/16               10.100.0.0/16           10.102.0.0/16
       │                           │                       │
       │  UDR: 0.0.0.0/0          │                       │
       │  → VirtualNetworkGateway  │                       │
       │                           │                       │
       └──── peering ─────► VPN Gateway ◄──── peering ─────┘
              (useRemoteGw=true)    │    (allowGwTransit=true)
                                    │
                            ALL spoke-to-spoke
                            traffic hairpins here
```

In this configuration, User-Defined Routes (UDRs) on both spokes force a default route (`0.0.0.0/0 → VirtualNetworkGateway`). Combined with `useRemoteGateways: true` on spoke peerings and `allowGatewayTransit: true` on hub peerings, all spoke-to-spoke traffic is forced through the VPN gateway — even though the spokes are in the same region and could communicate via VNet peering directly.

### Effective Routes (Broken)

```
Source    State    Address Prefix    Next Hop Type            
────────  ───────  ────────────────  ─────────────────────────
Default   Active   10.101.0.0/16     VnetLocal               
Default   Active   10.100.0.0/16     VNetPeering             
User      Active   0.0.0.0/0         VirtualNetworkGateway   ◄── Forces all traffic through gateway
User      Active   68.47.19.27/32    Internet                
Default   Invalid  0.0.0.0/0         Internet                ◄── Overridden by UDR
```

**Key observation**: There is NO route for `10.102.0.0/16` (Spoke 2). Traffic to the ADLS private endpoint falls under the `0.0.0.0/0 → VirtualNetworkGateway` catch-all, forcing it through the VPN gateway.

### Grafana Metrics — Broken State (23:18–23:33 UTC)

| Metric | Observation |
|--------|-------------|
| Gateway Inbound/Outbound Flows | **Ramped from ~500 to ~3,000 flows** — confirms traffic transiting gateway |
| Gateway S2S Bandwidth | Low but active — gateway processing spoke-to-spoke packets |
| VM Network Out | ~20 GB during test — uploading 1 GB files in cycles |
| VM Network In | ~20 GB during test — downloading 1 GB files in cycles |

![Broken state — Gateway and VM metrics](dashboards/broken-top.png)
![Broken state — VM and Storage metrics](dashboards/broken-bottom.png)

---

## Fix 1: Direct Spoke-to-Spoke Peering

### Changes Applied

| Change | Before (Broken) | After (Fixed) |
|--------|-----------------|---------------|
| Route tables | `0.0.0.0/0 → VirtualNetworkGateway` | Route **removed** |
| Hub→Spoke peering | `allowGatewayTransit: true` | `allowGatewayTransit: false` |
| Spoke→Hub peering | `useRemoteGateways: true` | `useRemoteGateways: false` |
| Spoke↔Spoke peering | None | **Direct peering** between vnet-spoke-dbrx ↔ vnet-spoke-adls |
| VPN Gateway | In data path | Still exists but **NOT** in spoke-to-spoke path |

### Architecture (Fixed State)

```
  Spoke 1 (vm-dbrx)          Hub (vnet-hub)          Spoke 2 (ADLS PE)
  10.101.0.0/16               10.100.0.0/16           10.102.0.0/16
       │                           │                       │
       │  No default UDR           │                       │
       │                           │                       │
       ├──── peering ──────────────┤───── peering ─────────┤
       │  (no gateway transit)     │  (no gateway transit) │
       │                           │                       │
       └───────── direct peering ──────────────────────────┘
                  Traffic goes HERE now
                  (bypasses gateway entirely)
```

### Effective Routes (Fixed)

```
Source    State    Address Prefix    Next Hop Type            
────────  ───────  ────────────────  ─────────────────────────
Default   Active   10.101.0.0/16     VnetLocal               
Default   Active   10.100.0.0/16     VNetPeering             
Default   Active   10.102.0.0/16     VNetPeering             ◄── NEW: Direct route to Spoke 2
Default   Active   0.0.0.0/0         Internet                ◄── Default (no more forced tunneling)
User      Active   68.47.19.27/32    Internet                
Default   Active   10.102.2.4/32     InterfaceEndpoint       ◄── DFS private endpoint
Default   Active   10.102.2.5/32     InterfaceEndpoint       ◄── Blob private endpoint
```

**Key observation**: `10.102.0.0/16` now appears as a `VNetPeering` route — traffic to the ADLS private endpoint goes directly via VNet peering without touching the VPN gateway.

### Grafana Metrics — Fixed State (23:36–23:51 UTC)

| Metric | Observation |
|--------|-------------|
| Gateway Inbound/Outbound Flows | **Dropped from ~3,000 to ~700** — gateway no longer processing spoke-to-spoke data |
| Gateway S2S Bandwidth | Flatlined to ~0 B/s — no spoke-to-spoke traffic through gateway |
| VM Network Out | ~18 GB during test — **same throughput** as broken state |
| VM Network In | ~18 GB during test — **same throughput** as broken state |

![Fixed state — Gateway flows drop, VM traffic continues](dashboards/fixed-top.png)
![Fixed state — VM and Storage metrics](dashboards/fixed-bottom.png)

---

## Fix 2: Adjacent Private Endpoint

### Concept

Instead of changing routing or peering, place private endpoints for the storage account **in the consumer's VNet** (vnet-spoke-dbrx). The VM connects to a local PE IP (10.101.2.x) instead of the remote PE in spoke-adls (10.102.2.x).

This works because Azure creates `/32 InterfaceEndpoint` routes for local private endpoints. These are more specific than the `0.0.0.0/0` UDR and use `VnetLocal` next hop — completely bypassing the forced tunneling path through the VPN gateway.

**Key advantage**: No changes to route tables, peering, or gateway transit settings. The existing "broken" routing remains intact, but traffic to the storage account stays local.

### Changes Applied

| Change | Before (Broken) | After (Adjacent PE) |
|--------|-----------------|---------------------|
| Route tables | `0.0.0.0/0 → VirtualNetworkGateway` | **Unchanged** — UDR still active |
| Hub↔Spoke peering | `allowGatewayTransit: true` | **Unchanged** |
| Spoke→Hub peering | `useRemoteGateways: true` | **Unchanged** |
| vnet-spoke-dbrx subnets | `subnet-dbrx` only | Added `subnet-pe` (10.101.2.0/24) |
| Private endpoints | DFS + Blob PEs in spoke-adls only | **Added** DFS + Blob PEs in spoke-dbrx |

### Architecture (Adjacent PE)

```
  Spoke 1 (vm-dbrx)          Hub (vnet-hub)          Spoke 2 (ADLS PE)
  10.101.0.0/16               10.100.0.0/16           10.102.0.0/16
       │                           │                       │
       │  UDR: 0.0.0.0/0          │                       │
       │  → VirtualNetworkGateway  │                       │
       │  (STILL ACTIVE)           │                       │
       ├──── peering ─────► VPN Gateway ◄──── peering ─────┤
       │                                                    │
       │  ┌─────────────────┐                               │
       │  │ subnet-pe       │                               │
       │  │ 10.101.2.0/24   │                               │
       │  │                 │                               │
       │  │ pe-adls-dfs-local  ──── Azure backbone ──► ADLS │
       │  │ pe-adls-blob-local ──── Azure backbone ──► ADLS │
       │  └─────────────────┘                               │
       │                                                    │
       └── VM traffic goes to LOCAL PE (bypasses gateway) ──┘
```

### Effective Routes (Adjacent PE)

```
Source    State    Address Prefix    Next Hop Type
────────  ───────  ────────────────  ─────────────────────────
Default   Active   10.101.0.0/16     VnetLocal
Default   Active   10.100.0.0/16     VNetPeering
User      Active   0.0.0.0/0         VirtualNetworkGateway   ◄── UDR STILL ACTIVE
User      Active   68.47.19.27/32    Internet
Default   Invalid  0.0.0.0/0         Internet
Default   Active   10.101.2.4/32     InterfaceEndpoint       ◄── Local DFS PE (/32 overrides UDR)
Default   Active   10.101.2.5/32     InterfaceEndpoint       ◄── Local Blob PE (/32 overrides UDR)
```

**Key observation**: The forced tunneling UDR (`0.0.0.0/0 → VirtualNetworkGateway`) is still active, but the `/32 InterfaceEndpoint` routes for the local PEs at `10.101.2.4` and `10.101.2.5` are more specific and take priority. Traffic to the storage account stays within vnet-spoke-dbrx.

### Grafana Metrics — Adjacent PE (00:11–00:26 UTC)

| Metric | Observation |
|--------|-------------|
| Gateway Inbound/Outbound Flows | **~615-650** — baseline management probes only, identical to idle gateway |
| Gateway S2S Bandwidth | **0 B/s** — flat zero, no data through gateway |
| VM Network Out | ~20 GB during test — **same throughput** as all other tests |
| VM Network In | ~20 GB during test — **same throughput** as all other tests |

![Adjacent PE — Gateway at baseline, VM traffic active](dashboards/adjacent-pe-top.png)
![Adjacent PE — VM and Storage metrics](dashboards/adjacent-pe-bottom.png)

---

## Conclusion

### Comparison of All Three Configurations

| Metric | Broken (Hairpin) | Fix 1 (Direct Peering) | Fix 2 (Adjacent PE) |
|--------|-----------------|----------------------|---------------------|
| Gateway Flows | **~3,000** | ~700 (↓77%) | **~630** (↓79%) |
| Gateway S2S Bandwidth | Active | 0 B/s | **0 B/s** |
| VM Throughput | ~18 GB | ~18 GB | **~20 GB** |
| Routing changes | — | UDR removed, gateway transit disabled | **None** |
| Peering changes | — | Spoke-to-spoke peering added | **None** |
| Infrastructure added | — | None | PE subnet + 2 PEs in consumer VNet |

### Fix 1: Direct Peering
- Removes the gateway from the data path entirely by fixing the routing architecture
- Requires changes to route tables, peering settings, and adding spoke-to-spoke peering
- Best when you want a clean network architecture without forced tunneling

### Fix 2: Adjacent Private Endpoint (Recommended)
- Bypasses the gateway without changing any routing or peering settings
- The forced tunneling UDR remains active, but `/32 InterfaceEndpoint` routes override it
- Minimally invasive — only adds a PE subnet and two private endpoints in the consumer's VNet
- Best when you can't change the existing network architecture (e.g., shared hub managed by a central team)

### Bicep Configurations

All three states are codified as self-contained Bicep deployments:

- **`bicep/lab-current/`** — Reproduces the broken hairpin state
- **`bicep/lab-fixed-direct-peering/`** — Fix 1: Direct spoke-to-spoke peering
- **`bicep/lab-fixed-adjacent-pe/`** — Fix 2: Adjacent private endpoints in consumer VNet

Deploy any configuration with:
```bash
az deployment group create \
  --resource-group rg-spoke-to-spoke-lab \
  --template-file bicep/<config>/main.bicep \
  --parameters adminUsername=<user> adminPublicKey='<key>' \
               allowedSshSourceIp=<ip> storageAccountSuffix=<suffix>
```
