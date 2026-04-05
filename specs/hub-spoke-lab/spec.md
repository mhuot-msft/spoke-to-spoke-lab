# hub-spoke-lab Specification

## Purpose

Deploy an Azure hub-and-spoke lab environment that reproduces the behavior of spoke-to-spoke traffic hairpinning through a VPN gateway. Provide instrumentation via Grafana to prove the traffic path and measure gateway saturation, then validate remediation options.

## Context

A customer with an ExpressRoute Ultra gateway in a hub-and-spoke topology is seeing maxed-out PPS and throughput metrics. Databricks workloads in one spoke are hitting ADLS Gen2 in another spoke, and all that traffic is flowing through the ER gateway. This lab simulates the same pattern using a VPN gateway so we can demonstrate the problem and test fixes without needing an ExpressRoute circuit.

## Requirements

### Requirement: Hub VNet with VPN Gateway

The system SHALL deploy a hub VNet (10.100.0.0/16) containing a GatewaySubnet (10.100.0.0/27) with a VPN Gateway (VpnGw1 SKU).

#### Scenario: Gateway deploys successfully

- GIVEN the Bicep template is deployed
- WHEN the deployment completes
- THEN a VPN gateway named vpn-gw-hub exists in vnet-hub
- AND the gateway SKU is VpnGw1

### Requirement: Spoke VNet for Databricks simulation

The system SHALL deploy a spoke VNet (10.101.0.0/16) containing a workload subnet (10.101.1.0/24) with a Linux VM running Ubuntu 22.04 LTS (Standard_B2s).

#### Scenario: VM deploys with SSH access

- GIVEN the Bicep template is deployed
- WHEN the deployment completes
- THEN vm-dbrx exists in vnet-spoke-dbrx with a public IP
- AND nsg-dbrx allows SSH (port 22) inbound from a parameterized source IP only

### Requirement: Spoke VNet for ADLS Gen2

The system SHALL deploy a spoke VNet (10.102.0.0/16) containing a workload subnet (10.102.1.0/24), a private endpoint subnet (10.102.2.0/24), a storage account with hierarchical namespace enabled (ADLS Gen2), and a private endpoint for the DFS service.

#### Scenario: Storage accessible only via private endpoint

- GIVEN the storage account is deployed
- WHEN a request is made to the DFS endpoint
- THEN the request resolves to the private endpoint IP in subnet-pe (10.102.2.0/24)
- AND public network access is disabled on the storage account

### Requirement: VNet peering with gateway transit

The system SHALL peer both spokes to the hub with gateway transit enabled on the hub side and "Use Remote Gateway" enabled on each spoke side.

#### Scenario: Peering configured correctly

- GIVEN both peerings are deployed
- WHEN the effective routes on nic-dbrx are inspected
- THEN routes for 10.102.0.0/16 show next hop type as VirtualNetworkGateway

### Requirement: Forced tunneling via UDRs

The system SHALL deploy route tables on both spoke subnets with a default route (0.0.0.0/0) pointing to VirtualNetworkGateway as next hop.

#### Scenario: Default route forces traffic through gateway

- GIVEN rt-dbrx is associated with subnet-dbrx
- WHEN vm-dbrx sends traffic to any destination not matching a more specific route
- THEN traffic is directed to the VPN gateway in the hub

### Requirement: Private DNS zone for DFS

The system SHALL deploy a private DNS zone (privatelink.dfs.core.windows.net) linked to all three VNets, with an A record for the storage account's DFS endpoint pointing to the private endpoint IP.

#### Scenario: DNS resolution returns private IP

- GIVEN the private DNS zone is linked to vnet-spoke-dbrx
- WHEN vm-dbrx resolves <storageaccount>.dfs.core.windows.net
- THEN the resolved IP is in the 10.102.2.0/24 range

### Requirement: Traffic generation script

The system SHALL include a bash script that installs azcopy on vm-dbrx, generates a 1GB test file, and loops upload/download cycles against the ADLS Gen2 storage account to simulate sustained Databricks-to-ADLS traffic.

#### Scenario: Traffic generates sustained load

- GIVEN the script is running on vm-dbrx
- WHEN azcopy cycles are executing
- THEN VPN gateway metrics (AverageBandwidth, InboundFlowsCount, TunnelPeakPackets) increase measurably

### Requirement: Grafana dashboard

The system SHALL include a Grafana dashboard JSON definition that monitors VPN gateway metrics (S2S bandwidth, flows, tunnel bytes, peak PPS), VM network metrics (Network In/Out Total), and storage account metrics (Ingress, Egress, Transactions) using the Azure Monitor data source with template variables for subscription, resource group, and resource names.

#### Scenario: Dashboard shows correlated metrics

- GIVEN the Grafana dashboard is imported and configured
- WHEN the traffic generation script is running
- THEN all panels show correlated increases in gateway throughput, VM network output, and storage ingress
