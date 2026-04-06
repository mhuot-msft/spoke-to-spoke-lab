## Context

The current lab deploys two spokes (DBX + ADLS with co-located PEs) peered to a hub with a VPN gateway. The real customer topology has a **dedicated PE VNet** — a third spoke that centralizes all private endpoints. Traffic flows DBX → Hub Gateway → PE VNet → ADLS. This change restructures the lab from a two-spoke to a three-VNet spoke model to match the production architecture.

The existing Bicep modules under `bicep/modules/` are shared building blocks. Three self-contained configurations (`lab-current/`, `lab-fixed-direct-peering/`, `lab-fixed-adjacent-pe/`) each have their own `main.bicep` that references these modules.

## Goals / Non-Goals

**Goals:**
- Introduce a third spoke VNet (`vnet-spoke-pe`, 10.103.0.0/16) dedicated to hosting private endpoints
- Move DFS and Blob private endpoints from vnet-spoke-adls into vnet-spoke-pe
- Update all three Bicep configurations to reflect the three-VNet topology
- Ensure the broken state reproduces: DBX → Gateway → PE VNet → ADLS
- Update Fix 1 (Direct Peering) to peer DBX spoke directly to PE spoke (matching the real-world fix)
- Update Fix 2 (Adjacent PE) to deploy PEs in DBX spoke, bypassing both gateway and PE VNet
- Rerun all validation tests and update REPORT.md, screenshots, and PDF
- Update README and architecture diagrams

**Non-Goals:**
- Changing the VPN gateway SKU or hub VNet design
- Adding new monitoring metrics or dashboard panels
- Deploying Azure Firewall or NVA
- Testing VWAN (documented as alternative only)

## Decisions

### Decision 1: PE VNet address space 10.103.0.0/16

**Choice**: Assign 10.103.0.0/16 to the new PE spoke, with subnet-pe at 10.103.2.0/24.

**Rationale**: Follows the existing /16 per-spoke pattern (10.100=hub, 10.101=dbrx, 10.102=adls, 10.103=pe). The PE subnet uses the .2.0/24 position matching the existing PE subnet convention in spoke-adls.

**Alternative**: Use a /24 VNet to minimize address waste. Rejected — consistency with existing VNets is more valuable in a lab environment.

### Decision 2: Separate Bicep module for PE spoke VNet

**Choice**: Create `bicep/modules/networking/spoke-pe-vnet.bicep` as a new module.

**Rationale**: Each VNet has its own module today. The PE VNet has a distinct purpose (hosting PEs) and a different subnet layout (no workload subnet, only PE subnet). A separate module keeps concerns isolated.

**Alternative**: Parameterize spoke-adls-vnet.bicep to optionally include PE subnet. Rejected — the PE VNet is fundamentally different from the ADLS VNet after the split (ADLS loses its PE subnet entirely).

### Decision 3: Remove PE subnet from vnet-spoke-adls

**Choice**: Remove `subnet-pe` (10.102.2.0/24) from spoke-adls-vnet.bicep. The ADLS VNet becomes a storage-hosting VNet with only a workload subnet.

**Rationale**: In the real customer topology, PEs don't live in the same VNet as the storage account. The ADLS storage account itself doesn't need to be in the PE VNet — the PE is a separate networking resource that connects to the storage account's data plane.

### Decision 4: Hub peers with all three spokes

**Choice**: Hub VNet peers with vnet-spoke-dbrx, vnet-spoke-adls, AND vnet-spoke-pe — all with gateway transit enabled in the broken state.

**Rationale**: All three spokes need connectivity through the hub in the broken state. The PE VNet needs gateway transit so that the DBX spoke can reach the PEs via the gateway (the hairpin path).

### Decision 5: Fix 1 peers DBX ↔ PE VNet (not DBX ↔ ADLS)

**Choice**: Direct peering fix creates peering between vnet-spoke-dbrx and vnet-spoke-pe, not between DBX and ADLS.

**Rationale**: This matches the customer's actual fix. The DBX spoke needs to reach the private endpoints, which live in the PE VNet. The ADLS VNet doesn't need direct peering to DBX because no traffic goes there directly — all data plane access is through the PE.

### Decision 6: Route table for PE spoke

**Choice**: Create `rt-pe` with the same catch-all UDR (`0.0.0.0/0 → VirtualNetworkGateway`) and associate it with the PE subnet.

**Rationale**: Consistent with rt-dbrx and rt-adls. Without this, traffic from the PE VNet would not be forced through the gateway, breaking the symmetry of the broken state.

## Risks / Trade-offs

- **[Risk] Existing deployments break** → All three Bicep configs must be updated atomically. Run `az bicep build` on each before deploying.
- **[Risk] DNS resolution changes** → PE IPs move from 10.102.2.x to 10.103.2.x. DNS zone A records must be updated. DNS zone links must include the new PE VNet.
- **[Risk] Gateway deployment time** → VPN gateway takes 20-40 minutes. The gateway itself doesn't change, but redeployments that touch peering/gateway may trigger reprovisioning. Use incremental mode.
- **[Trade-off] More complex lab** → Three VNets are harder to explain than two, but better match the customer scenario — the complexity is justified.
- **[Trade-off] More peering pairs** → 3 hub-spoke peerings instead of 2, plus Fix 1 adds DBX↔PE peering. Additional Azure cost is negligible for a lab.
