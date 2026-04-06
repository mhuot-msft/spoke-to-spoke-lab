## ADDED Requirements

### Requirement: Dedicated PE Spoke VNet

The system SHALL deploy a dedicated Private Endpoint spoke VNet (`vnet-spoke-pe`, 10.103.0.0/16) containing a PE subnet (`subnet-pe`, 10.103.2.0/24) that hosts centralized private endpoints for the ADLS Gen2 storage account (DFS and Blob sub-resources).

#### Scenario: PE VNet deploys with PE subnet

- **WHEN** the Bicep template is deployed
- **THEN** vnet-spoke-pe exists with address space 10.103.0.0/16
- **AND** subnet-pe exists at 10.103.2.0/24
- **AND** private endpoints for DFS and Blob sub-resources are deployed in subnet-pe

### Requirement: Hub-to-PE-spoke peering with gateway transit

The system SHALL peer vnet-spoke-pe to the hub with `allowGatewayTransit: true` on the hub side and `useRemoteGateways: true` on the PE spoke side, matching the existing hub-to-spoke peering pattern.

#### Scenario: PE spoke peering enables gateway transit

- **WHEN** the peering between hub and PE spoke is deployed
- **THEN** the hub→PE peering has allowGatewayTransit set to true
- **AND** the PE→hub peering has useRemoteGateways set to true

### Requirement: Route table for PE spoke

The system SHALL deploy a route table (`rt-pe`) with a default route (`0.0.0.0/0 → VirtualNetworkGateway`) associated with subnet-pe in the PE spoke, consistent with the forced tunneling pattern on other spokes.

#### Scenario: PE spoke traffic forced through gateway

- **WHEN** rt-pe is associated with subnet-pe in vnet-spoke-pe
- **THEN** traffic from the PE subnet without a more specific route is directed to the VPN gateway

### Requirement: Private DNS zone links include PE VNet

The system SHALL link the private DNS zone (`privatelink.dfs.core.windows.net`) to all four VNets: hub, spoke-dbrx, spoke-adls, and spoke-pe.

#### Scenario: DNS zone linked to all VNets

- **WHEN** the private DNS zone is deployed
- **THEN** VNet links exist for vnet-hub, vnet-spoke-dbrx, vnet-spoke-adls, and vnet-spoke-pe
