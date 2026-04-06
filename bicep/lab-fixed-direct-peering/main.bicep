targetScope = 'resourceGroup'

param location string = resourceGroup().location
param adminUsername string
@secure()
param adminPublicKey string
param allowedSshSourceIp string
param storageAccountSuffix string

var tags = {
  SecurityPolicy: 'ignore'
}

// Storage Blob Data Owner built-in role
var storageBlobDataOwnerRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
)

// --- Phase 1: Route Tables + VNets ---

module routeTables 'modules/networking/route-tables.bicep' = {
  name: 'route-tables'
  params: {
    location: location
    tags: tags
    allowedSshSourceIp: allowedSshSourceIp
  }
}

module hubVnet 'modules/networking/hub-vnet.bicep' = {
  name: 'hub-vnet'
  params: {
    location: location
    tags: tags
  }
}

module spokeDbrxVnet 'modules/networking/spoke-dbrx-vnet.bicep' = {
  name: 'spoke-dbrx-vnet'
  params: {
    location: location
    tags: tags
    routeTableId: routeTables.outputs.rtDbrxId
  }
}

module spokeAdlsVnet 'modules/networking/spoke-adls-vnet.bicep' = {
  name: 'spoke-adls-vnet'
  params: {
    location: location
    tags: tags
    routeTableId: routeTables.outputs.rtAdlsId
  }
}

module spokePeVnet 'modules/networking/spoke-pe-vnet.bicep' = {
  name: 'spoke-pe-vnet'
  params: {
    location: location
    tags: tags
    routeTableId: routeTables.outputs.rtPeId
  }
}

// --- Phase 2: VPN Gateway (still deployed, but NOT in spoke-to-spoke data path) ---

module vpnGateway 'modules/networking/vpn-gateway.bicep' = {
  name: 'vpn-gateway'
  params: {
    location: location
    tags: tags
    gatewaySubnetId: hubVnet.outputs.gatewaySubnetId
  }
}

// --- Phase 3: VNet Peering (NO gateway dependency) ---

// Hub ↔ Spoke DBRX — gateway transit disabled
module peeringHubDbrx 'modules/networking/peering.bicep' = {
  name: 'peering-hub-dbrx'
  params: {
    hubVnetName: hubVnet.outputs.vnetName
    hubVnetId: hubVnet.outputs.vnetId
    spokeVnetName: spokeDbrxVnet.outputs.vnetName
    spokeVnetId: spokeDbrxVnet.outputs.vnetId
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// Hub ↔ Spoke ADLS — gateway transit disabled
module peeringHubAdls 'modules/networking/peering.bicep' = {
  name: 'peering-hub-adls'
  params: {
    hubVnetName: hubVnet.outputs.vnetName
    hubVnetId: hubVnet.outputs.vnetId
    spokeVnetName: spokeAdlsVnet.outputs.vnetName
    spokeVnetId: spokeAdlsVnet.outputs.vnetId
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// Hub ↔ Spoke PE — gateway transit disabled
module peeringHubPe 'modules/networking/peering.bicep' = {
  name: 'peering-hub-pe'
  params: {
    hubVnetName: hubVnet.outputs.vnetName
    hubVnetId: hubVnet.outputs.vnetId
    spokeVnetName: spokePeVnet.outputs.vnetName
    spokeVnetId: spokePeVnet.outputs.vnetId
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// FIXED: Direct spoke-to-spoke peering (DBRX ↔ PE VNet)
module peeringDbrxPe 'modules/networking/peering.bicep' = {
  name: 'peering-dbrx-pe'
  params: {
    hubVnetName: spokeDbrxVnet.outputs.vnetName
    hubVnetId: spokeDbrxVnet.outputs.vnetId
    spokeVnetName: spokePeVnet.outputs.vnetName
    spokeVnetId: spokePeVnet.outputs.vnetId
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// --- Phase 4: Private DNS + Storage ---

module privateDnsZones 'modules/networking/private-dns-zones.bicep' = {
  name: 'private-dns-zones'
  params: {
    tags: tags
    hubVnetId: hubVnet.outputs.vnetId
    spokeDbrxVnetId: spokeDbrxVnet.outputs.vnetId
    spokeAdlsVnetId: spokeAdlsVnet.outputs.vnetId
    spokePeVnetId: spokePeVnet.outputs.vnetId
  }
}

module adlsAccount 'modules/storage/adls-account.bicep' = {
  name: 'adls-account'
  params: {
    location: location
    tags: tags
    storageAccountSuffix: storageAccountSuffix
    subnetPeId: spokePeVnet.outputs.peSubnetId
    dfsZoneId: privateDnsZones.outputs.dfsZoneId
    blobZoneId: privateDnsZones.outputs.blobZoneId
  }
}

// --- Phase 5: Compute ---

module vmDbrx 'modules/compute/vm-dbrx.bicep' = {
  name: 'vm-dbrx'
  params: {
    location: location
    tags: tags
    subnetId: spokeDbrxVnet.outputs.subnetId
    adminUsername: adminUsername
    adminPublicKey: adminPublicKey
    allowedSshSourceIp: allowedSshSourceIp
  }
}

// --- Phase 6: Identity ---

module roleAssignment 'modules/identity/role-assignment.bicep' = {
  name: 'role-assignment'
  params: {
    principalId: vmDbrx.outputs.vmPrincipalId
    storageAccountId: adlsAccount.outputs.storageAccountId
    roleDefinitionId: storageBlobDataOwnerRoleId
  }
}

// --- Phase 7: Monitoring ---

module grafana 'modules/monitoring/grafana.bicep' = {
  name: 'grafana'
  params: {
    name: 'grafana-spoke-lab'
    location: location
    tags: tags
  }
}

module grafanaRoles 'modules/monitoring/grafana-roles.bicep' = {
  name: 'grafanaRoles'
  params: {
    principalId: grafana.outputs.grafanaPrincipalId
  }
}

// --- Outputs ---

output vmPublicIp string = vmDbrx.outputs.vmPublicIp
output storageAccountName string = adlsAccount.outputs.storageAccountName
output dfsEndpoint string = adlsAccount.outputs.dfsEndpoint
output grafanaEndpoint string = grafana.outputs.grafanaEndpoint
