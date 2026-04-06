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

#### Scenario: Dashboard panels are legible in a single screenshot

- GIVEN all 6 panels are arranged in a 3×2 grid
- WHEN the dashboard is captured at 1400×1000 viewport in kiosk mode
- THEN all panels fit in a single screenshot with legible text
- AND each panel legend displays min, max, and mean values in table format

#### Scenario: Storage metrics use appropriate time grain

- GIVEN the storage panels query `Microsoft.Storage/storageAccounts/blobServices/default`
- WHEN the time grain is PT5M
- THEN storage ingress and egress are visible during 15-minute test windows

#### Scenario: Gateway panels use fixed Y-axis for cross-state comparison

- GIVEN the gateway panels have Y-axis fixed at 0–3500
- WHEN screenshots are captured across broken, direct peering, and adjacent PE states
- THEN the visual scale is consistent, making flat baselines clearly distinguishable from active traffic

#### Scenario: Test annotations mark begin and end times

- GIVEN a Grafana service account with Editor role exists
- WHEN the grafana-annotate.ps1 script posts annotations via the Grafana API
- THEN vertical markers appear on all panels at test begin and test complete times

### Requirement: Remediation — Direct Spoke-to-Spoke Peering

The system SHALL include an alternative Bicep configuration (`bicep/lab-fixed-direct-peering/`) that adds direct VNet peering between the two spokes and removes the catch-all UDR, so spoke-to-spoke traffic no longer transits the VPN gateway.

#### Scenario: Direct peering eliminates gateway hairpin

- GIVEN the direct peering configuration is deployed
- WHEN vm-dbrx sends traffic to the ADLS private endpoint in spoke-adls
- THEN effective routes on nic-dbrx show 10.102.0.0/16 with next hop type VNetPeering
- AND VPN gateway flow count does not increase above idle baseline during traffic generation
- AND storage ingress/egress metrics increase as expected

### Requirement: Remediation — Adjacent Private Endpoint

The system SHALL include an alternative Bicep configuration (`bicep/lab-fixed-adjacent-pe/`) that deploys private endpoints for the ADLS storage account in the consumer spoke (vnet-spoke-dbrx), so storage data plane traffic stays local to the spoke and bypasses the gateway.

#### Scenario: Adjacent PE bypasses gateway for storage traffic

- GIVEN the adjacent PE configuration is deployed with PEs in subnet-pe-dbrx (10.101.2.0/24)
- WHEN vm-dbrx sends traffic to the ADLS DFS endpoint
- THEN effective routes on nic-dbrx show /32 InterfaceEndpoint routes for PE IPs
- AND the /32 routes override the catch-all 0.0.0.0/0 UDR for storage data plane traffic
- AND VPN gateway flow count remains flat (ancillary traffic only — AAD auth, DNS)
- AND the forced tunneling UDR remains active for all non-PE traffic

### Requirement: Validation report

The system SHALL include a validation report (REPORT.md) documenting the 3-state test sequence (broken, direct peering, adjacent PE) with Grafana screenshots, effective route tables, metric summaries, and a security/compliance analysis of each remediation approach.

#### Scenario: Report proves hairpin in broken state

- GIVEN the broken state is deployed with catch-all UDR and gateway transit
- WHEN 15 minutes of sustained azcopy traffic runs
- THEN the report shows VPN gateway flows increasing from idle to >3,000
- AND effective routes confirm VirtualNetworkGateway next hop for 10.102.0.0/16

#### Scenario: Report proves each fix eliminates gateway saturation

- GIVEN each fix configuration is deployed and tested for 15 minutes
- WHEN the report compares gateway metrics across all three states
- THEN the broken state shows >3,000 gateway flows
- AND the direct peering state shows gateway flows dropping to idle baseline
- AND the adjacent PE state shows gateway flows remaining flat

#### Scenario: Report includes security and compliance analysis

- GIVEN the report contains a security and compliance section
- WHEN the reader evaluates each fix
- THEN the report addresses forced tunneling preservation, central inspection impact, NSG requirements, PE surface area, and compliance fit for each approach
- AND includes a summary comparison table

### Requirement: ExpressRoute and VWAN equivalence notes

The report and README SHALL note that ExpressRoute gateways exhibit the same hairpin behavior as VPN gateways, and that Azure Virtual WAN is an alternative approach (not tested) that provides native spoke-to-spoke routing.

#### Scenario: ER gateway equivalence is documented

- GIVEN the report discusses the broken state
- THEN it includes a callout that ExpressRoute gateways exhibit the same hairpin behavior
- AND the README key findings reference this equivalence

#### Scenario: VWAN alternative is documented

- GIVEN the report conclusion section exists
- THEN it includes a subsection describing VWAN as an untested alternative
- AND notes that VWAN provides native spoke-to-spoke routing without manual peering or UDRs
