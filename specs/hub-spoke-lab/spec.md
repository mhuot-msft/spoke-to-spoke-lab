# Hub-Spoke Lab Specification

## Overview
Deploy an Azure hub-and-spoke topology that demonstrates spoke-to-spoke traffic hairpinning through a VPN gateway, with full instrumentation to measure the impact.

## Requirements

### REQ-1: Hub VNet
- VNet: vnet-hub (10.0.0.0/16)
- GatewaySubnet (10.0.0.0/27)
- VPN Gateway (VpnGw1 SKU): vpn-gw-hub

### REQ-2: Spoke 1 VNet (Databricks simulation)
- VNet: vnet-spoke-dbrx (10.1.0.0/16)
- Subnet: subnet-dbrx (10.1.1.0/24)
- Ubuntu 22.04 VM: vm-dbrx (Standard_B2s)
- NSG: nsg-dbrx (allow SSH from deployer IP)
- Public IP: pip-dbrx

### REQ-3: Spoke 2 VNet (ADLS)
- VNet: vnet-spoke-adls (10.2.0.0/16)
- Subnet: subnet-adls (10.2.1.0/24)
- Private endpoint subnet: subnet-pe (10.2.2.0/24)
- Storage account with hierarchical namespace (ADLS Gen2)
- Private endpoint for dfs
- Private DNS zone: privatelink.dfs.core.windows.net linked to all 3 VNets

### REQ-4: VNet Peering with Gateway Transit
- peer-hub-to-dbrx / peer-dbrx-to-hub
  - Hub side: Allow Gateway Transit = true
  - Spoke side: Use Remote Gateway = true
- peer-hub-to-adls / peer-adls-to-hub
  - Hub side: Allow Gateway Transit = true
  - Spoke side: Use Remote Gateway = true

### REQ-5: Forced Tunneling
- Route table rt-dbrx on subnet-dbrx: 0.0.0.0/0 next hop VirtualNetworkGateway
- Route table rt-adls on subnet-adls and subnet-pe: 0.0.0.0/0 next hop VirtualNetworkGateway

### REQ-6: Traffic Generation
- Script on vm-dbrx using azcopy to loop uploads/downloads of 1GB file to ADLS container

### REQ-7: Instrumentation
- Grafana dashboard monitoring:
  - VPN Gateway: S2S bandwidth, tunnel bytes, tunnel PPS, inbound/outbound flows
  - VM: network in/out
  - Storage: ingress, egress, transactions
  - Summary stat panels with color thresholds

### REQ-8: Validation
- Effective routes on nic-dbrx show 10.2.0.0/16 next hop = VirtualNetworkGateway
- VPN gateway metrics spike when traffic script runs
- After applying fix (direct peering or NVA), gateway metrics drop
