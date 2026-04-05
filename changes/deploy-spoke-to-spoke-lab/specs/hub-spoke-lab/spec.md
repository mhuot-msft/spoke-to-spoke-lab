# Delta for hub-spoke-lab

## ADDED Requirements

### Requirement: Hub VNet with VPN Gateway

The system SHALL deploy a hub VNet (10.100.0.0/16) containing a GatewaySubnet (10.100.0.0/27) with a VPN Gateway (VpnGw1 SKU).

### Requirement: Spoke VNet for Databricks simulation

The system SHALL deploy a spoke VNet (10.101.0.0/16) containing a workload subnet (10.101.1.0/24) with a Linux VM running Ubuntu 22.04 LTS (Standard_B2s).

### Requirement: Spoke VNet for ADLS Gen2

The system SHALL deploy a spoke VNet (10.102.0.0/16) containing a workload subnet (10.102.1.0/24), a private endpoint subnet (10.102.2.0/24), a storage account with hierarchical namespace enabled (ADLS Gen2), and a private endpoint for the DFS service.

### Requirement: VNet peering with gateway transit

The system SHALL peer both spokes to the hub with gateway transit enabled on the hub side and "Use Remote Gateway" enabled on each spoke side.

### Requirement: Forced tunneling via UDRs

The system SHALL deploy route tables on both spoke subnets with a default route (0.0.0.0/0) pointing to VirtualNetworkGateway as next hop.

### Requirement: Private DNS zone for DFS

The system SHALL deploy a private DNS zone (privatelink.dfs.core.windows.net) linked to all three VNets, with an A record for the storage account's DFS endpoint pointing to the private endpoint IP.

### Requirement: Traffic generation script

The system SHALL include a bash script that installs azcopy on vm-dbrx, generates a 1GB test file, and loops upload/download cycles against the ADLS Gen2 storage account.

### Requirement: Grafana dashboard

The system SHALL include a Grafana dashboard JSON definition that monitors VPN gateway, VM, and storage account metrics using the Azure Monitor data source with template variables.
