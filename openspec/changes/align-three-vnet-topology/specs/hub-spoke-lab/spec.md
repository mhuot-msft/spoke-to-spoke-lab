## MODIFIED Requirements

### Requirement: Spoke VNet for ADLS Gen2

The system SHALL deploy a spoke VNet (10.102.0.0/16) containing a workload subnet (10.102.1.0/24) and a storage account with hierarchical namespace enabled (ADLS Gen2). Private endpoints for the storage account SHALL be hosted in the dedicated PE spoke VNet (`vnet-spoke-pe`), not in vnet-spoke-adls.

#### Scenario: Storage account deploys without PE subnet

- **WHEN** the Bicep template is deployed
- **THEN** vnet-spoke-adls exists with address space 10.102.0.0/16
- **AND** subnet-adls exists at 10.102.1.0/24
- **AND** no PE subnet exists in vnet-spoke-adls
- **AND** the storage account is deployed with public network access disabled

### Requirement: VNet peering with gateway transit

The system SHALL peer all three spokes (dbrx, adls, pe) to the hub with gateway transit enabled on the hub side and "Use Remote Gateway" enabled on each spoke side.

#### Scenario: Peering configured correctly

- **WHEN** all three peerings are deployed
- **THEN** effective routes on nic-dbrx show 10.102.0.0/16 and 10.103.0.0/16 with next hop type VirtualNetworkGateway
- **AND** the PE VNet routes through the gateway in the broken state

### Requirement: Private DNS zone for DFS

The system SHALL deploy a private DNS zone (`privatelink.dfs.core.windows.net`) linked to all four VNets (hub, spoke-dbrx, spoke-adls, spoke-pe), with an A record for the storage account's DFS endpoint pointing to the private endpoint IP in vnet-spoke-pe.

#### Scenario: DNS resolution returns PE VNet private IP

- **WHEN** vm-dbrx resolves <storageaccount>.dfs.core.windows.net
- **THEN** the resolved IP is in the 10.103.2.0/24 range (PE spoke subnet)

### Requirement: Remediation — Direct Spoke-to-Spoke Peering

The system SHALL include an alternative Bicep configuration (`bicep/lab-fixed-direct-peering/`) that adds direct VNet peering between vnet-spoke-dbrx and vnet-spoke-pe, so DBX-to-PE traffic no longer transits the VPN gateway.

#### Scenario: Direct peering eliminates gateway hairpin

- **WHEN** the direct peering configuration is deployed
- **THEN** effective routes on nic-dbrx show 10.103.0.0/16 with next hop type VNetPeering
- **AND** VPN gateway flow count does not increase above idle baseline during traffic generation
- **AND** storage ingress/egress metrics increase as expected

### Requirement: Remediation — Adjacent Private Endpoint

The system SHALL include an alternative Bicep configuration (`bicep/lab-fixed-adjacent-pe/`) that deploys private endpoints for the ADLS storage account in the consumer spoke (vnet-spoke-dbrx), so storage data plane traffic stays local to the DBX spoke and bypasses both the gateway and the PE VNet.

#### Scenario: Adjacent PE bypasses gateway for storage traffic

- **WHEN** the adjacent PE configuration is deployed with PEs in subnet-pe-dbrx (10.101.2.0/24)
- **THEN** effective routes on nic-dbrx show /32 InterfaceEndpoint routes for PE IPs
- **AND** the /32 routes override the catch-all 0.0.0.0/0 UDR for storage data plane traffic
- **AND** VPN gateway flow count remains flat (ancillary traffic only)
- **AND** the forced tunneling UDR remains active for all non-PE traffic

### Requirement: Validation report

The system SHALL include a validation report (REPORT.md) documenting the 3-state test sequence with the three-VNet architecture, including the real-world scenario context (dedicated PE VNet), Grafana screenshots, effective route tables, metric summaries, and security/compliance analysis.

#### Scenario: Report reflects three-VNet architecture

- **WHEN** the report describes the broken state architecture
- **THEN** diagrams show three spokes: DBX, ADLS (no PEs), and PE VNet (with PEs)
- **AND** the traffic path is documented as DBX → Gateway → PE VNet → ADLS

#### Scenario: Report includes real-world scenario context

- **WHEN** the report introduces the problem
- **THEN** it describes the customer's topology with a dedicated PE VNet
- **AND** notes the lab aligns to this three-VNet model
