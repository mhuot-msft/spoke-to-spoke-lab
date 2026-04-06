# Spoke-to-Spoke Lab

Azure hub-and-spoke lab that demonstrates spoke-to-spoke traffic hairpinning through a VPN gateway, with validated fixes.

> **Gateway type**: This lab uses a VPN gateway, but the same hairpin behavior occurs with **ExpressRoute gateways**. Both support `allowGatewayTransit` / `useRemoteGateways` and both will process spoke-to-spoke traffic when a catch-all UDR forces `0.0.0.0/0 → VirtualNetworkGateway`. The fixes demonstrated here apply equally to ExpressRoute environments.

## Key Findings

Full validation report with Grafana screenshots, effective routes, and metric comparisons: **[REPORT.md](REPORT.md)**

| Configuration | Gateway Flows (Max) | Gateway in data path? | Changes required |
|--------------|--------------------|-----------------------|-----------------|
| **Broken** (catch-all UDR) | **2,956** | Yes — all traffic | — |
| **Fix 1: Direct Peering** ⭐ | 627 (baseline) | **No** | UDR removed, gateway transit disabled, DBX↔PE spoke peering added |
| **Fix 2: Adjacent PE** | 641 (flat) | **No** (storage data bypassed) | PE subnet + 2 private endpoints in consumer VNet |

**Recommended fix**: Direct Peering — removes the gateway from the data path entirely by peering the consumer spoke directly to the PE spoke. Clean, permanent fix with no residual hairpinning.

**Azure Virtual WAN** would also address this issue by providing native spoke-to-spoke routing through the VWAN hub router, but requires migrating from traditional hub-and-spoke and was not tested here.

## Purpose

Reproduces a real-world scenario where Databricks-to-ADLS traffic in a hub-and-spoke topology saturates the gateway (PPS and throughput), with full Grafana instrumentation to prove it.

## Architecture

```mermaid
graph TD
    subgraph hub["Hub VNet (10.100.0.0/16)"]
        vpngw["VPN Gateway\nVpnGw1"]
    end

    subgraph spoke1["DBX Spoke — vnet-spoke-dbrx (10.101.0.0/16)"]
        vm["vm-dbrx\nLinux VM"]
        rt1["rt-dbrx\nUDR"]
    end

    subgraph spoke3["PE Spoke — vnet-spoke-pe (10.103.0.0/16)"]
        pe["PE (DFS + Blob)\nPrivate Endpoints"]
        rt3["rt-pe\nUDR"]
    end

    subgraph spoke2["ADLS Spoke — vnet-spoke-adls (10.102.0.0/16)"]
        adls["ADLS Gen2\nStorage Account"]
    end

    spoke1 -- "VNet Peering\n(use gateway transit)" --> hub
    spoke3 -- "VNet Peering\n(use gateway transit)" --> hub
    spoke2 -- "VNet Peering\n(use gateway transit)" --> hub

    vm -. "azcopy traffic\nhairpin path" .-> vpngw
    vpngw -. "azcopy traffic\nhairpin path" .-> pe
    pe -. "Azure backbone" .-> adls
```

> For the detailed diagram see [diagrams/spoke-to-spoke-lab.excalidraw](diagrams/spoke-to-spoke-lab.excalidraw).

- **Hub VNet** with VPN Gateway (VpnGw1)
- **DBX Spoke** (`vnet-spoke-dbrx`, 10.101.0.0/16) — `vm-dbrx` + `rt-dbrx`
- **PE Spoke** (`vnet-spoke-pe`, 10.103.0.0/16) — DFS + Blob private endpoints + `rt-pe`
- **ADLS Spoke** (`vnet-spoke-adls`, 10.102.0.0/16) — Storage account
- VNet peering with gateway transit forces spoke-to-spoke through the gateway
- UDRs for forced tunneling

## Project Structure

- `bicep/` — Infrastructure as Code (4 configurations: broken + 2 fixes)
  - `lab-current/` — Broken hairpin state
  - `lab-fixed-direct-peering/` — Fix 1: Direct spoke-to-spoke peering
  - `lab-fixed-adjacent-pe/` — Fix 2: Adjacent private endpoints
- `dashboards/` — Grafana dashboard JSON and test screenshots
- `scripts/` — Traffic generation and Grafana annotation scripts
- `diagrams/` — Architecture diagrams
- `openspec/` — OpenSpec config, specs, and change proposals

## Getting Started

1. Deploy a configuration: `az deployment group create --template-file bicep/<config>/main.bicep`
2. Import `dashboards/spoke-to-spoke-lab.json` into Azure Managed Grafana
3. Run azcopy traffic from vm-dbrx to ADLS private endpoint
4. Observe gateway flow metrics in Grafana

## Validation

1. Check effective routes on nic-dbrx — in broken state, `0.0.0.0/0 → VirtualNetworkGateway`
2. Run 15-minute azcopy traffic test and observe gateway flows spike to ~3,000
3. Apply a fix (direct peering or adjacent PE) and observe gateway flows drop to baseline
4. See [REPORT.md](REPORT.md) for complete test results with screenshots
