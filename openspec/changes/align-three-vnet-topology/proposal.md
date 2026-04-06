## Why

The current lab uses a two-spoke model (DBX spoke + ADLS spoke with co-located PEs), but the real customer topology has **three VNets**: a Databricks spoke, a hub, and a **dedicated Private Endpoint VNet** that centralizes all private endpoints. Traffic flows DBX → Hub Gateway → PE VNet → ADLS, hairpinning through the gateway. The customer's fix was direct peering between DBX spokes and the PE VNet. Aligning the lab to this three-VNet model makes the demonstration directly relatable to the production scenario.

## What Changes

- **Add a third VNet** (`vnet-spoke-pe`, 10.103.0.0/16) as a dedicated PE spoke hosting DFS and Blob private endpoints for the ADLS storage account
- **Move private endpoints** out of vnet-spoke-adls into vnet-spoke-pe — the ADLS spoke becomes a storage-only VNet with no PE subnet
- **Add hub-to-PE-spoke peering** with gateway transit, matching the existing hub-to-spoke pattern
- **Update UDRs** to include the PE spoke subnet in forced tunneling
- **Update private DNS zone** links to include the new PE VNet
- **Restructure all three Bicep configurations** (broken, direct-peering, adjacent-pe) to reflect the three-VNet model
- **Update Fix 1 (Direct Peering)** to peer DBX spoke directly to PE spoke (matching the real-world fix)
- **Update Fix 2 (Adjacent PE)** to deploy PEs in the DBX spoke, bypassing both the gateway and the PE VNet
- **Rerun all validation tests** and update REPORT.md, screenshots, and PDF with three-VNet results
- **Update diagrams and README** to reflect the new architecture

## Capabilities

### New Capabilities
- `pe-spoke-vnet`: Dedicated Private Endpoint VNet (10.103.0.0/16) with PE subnet hosting centralized private endpoints for storage services

### Modified Capabilities
- `hub-spoke-lab`: Architecture changes from two-spoke to three-VNet model; peering, UDR, and DNS requirements updated to include the PE spoke; traffic path becomes DBX → Gateway → PE VNet → ADLS in the broken state

## Impact

- **Bicep modules**: New spoke VNet module for PE VNet; existing spoke-adls module loses PE subnet; new peering pair (hub ↔ PE spoke); route table updates
- **All three Bicep configurations** (`lab-current/`, `lab-fixed-direct-peering/`, `lab-fixed-adjacent-pe/`) must be restructured
- **Dashboard**: No panel changes needed (same metrics), but screenshots must be recaptured
- **Report**: Architecture diagrams, effective routes, metric tables, and screenshots all need updating
- **DNS**: Private DNS zone links expand from 3 VNets to 4 (hub + 3 spokes)
- **Testing**: Full 3-state retest required after infrastructure changes
