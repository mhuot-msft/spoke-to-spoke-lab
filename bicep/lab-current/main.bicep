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

var storageAccountName = 'saadlslab${storageAccountSuffix}'

// Storage Blob Data Owner built-in role
var storageBlobDataOwnerRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
)

// ── Phase 1: Route Tables & Virtual Networks ──────────────────────────────────

module routeTables 'modules/networking/route-tables.bicep' = {
  name: 'routeTables'
  params: {
    location: location
    allowedSshSourceIp: allowedSshSourceIp
    tags: tags
  }
}

module hubVnet 'modules/networking/hub-vnet.bicep' = {
  name: 'hubVnet'
  params: {
    location: location
    tags: tags
  }
}

module spokeDbrxVnet 'modules/networking/spoke-dbrx-vnet.bicep' = {
  name: 'spokeDbrxVnet'
  params: {
    location: location
    routeTableId: routeTables.outputs.rtDbrxId
    tags: tags
  }
}

module spokeAdlsVnet 'modules/networking/spoke-adls-vnet.bicep' = {
  name: 'spokeAdlsVnet'
  params: {
    location: location
    routeTableId: routeTables.outputs.rtAdlsId
    tags: tags
  }
}

module spokePeVnet 'modules/networking/spoke-pe-vnet.bicep' = {
  name: 'spokePeVnet'
  params: {
    location: location
    routeTableId: routeTables.outputs.rtPeId
    tags: tags
  }
}

// ── Phase 2: VPN Gateway ──────────────────────────────────────────────────────

module vpnGateway 'modules/networking/vpn-gateway.bicep' = {
  name: 'vpnGateway'
  params: {
    location: location
    gatewaySubnetId: hubVnet.outputs.gatewaySubnetId
    tags: tags
  }
}

// ── Phase 3: VNet Peering (depends on VPN Gateway) ───────────────────────────

module peeringHubDbrx 'modules/networking/peering.bicep' = {
  name: 'peeringHubDbrx'
  params: {
    localVnetName: hubVnet.outputs.vnetName
    remoteVnetName: spokeDbrxVnet.outputs.vnetName
    allowGatewayTransit: true
    useRemoteGateways: true
  }
  dependsOn: [
    vpnGateway
  ]
}

module peeringHubAdls 'modules/networking/peering.bicep' = {
  name: 'peeringHubAdls'
  params: {
    localVnetName: hubVnet.outputs.vnetName
    remoteVnetName: spokeAdlsVnet.outputs.vnetName
    allowGatewayTransit: true
    useRemoteGateways: true
  }
  dependsOn: [
    vpnGateway
  ]
}

module peeringHubPe 'modules/networking/peering.bicep' = {
  name: 'peeringHubPe'
  params: {
    localVnetName: hubVnet.outputs.vnetName
    remoteVnetName: spokePeVnet.outputs.vnetName
    allowGatewayTransit: true
    useRemoteGateways: true
  }
  dependsOn: [
    vpnGateway
  ]
}

// ── Phase 4: DNS, Storage & Compute ──────────────────────────────────────────

module privateDnsZones 'modules/networking/private-dns-zones.bicep' = {
  name: 'privateDnsZones'
  params: {
    hubVnetId: hubVnet.outputs.vnetId
    spokeDbrxVnetId: spokeDbrxVnet.outputs.vnetId
    spokeAdlsVnetId: spokeAdlsVnet.outputs.vnetId
    spokePeVnetId: spokePeVnet.outputs.vnetId
    tags: tags
  }
}

module adlsAccount 'modules/storage/adls-account.bicep' = {
  name: 'adlsAccount'
  params: {
    location: location
    storageAccountName: storageAccountName
    subnetId: spokePeVnet.outputs.peSubnetId
    dfsZoneId: privateDnsZones.outputs.dfsZoneId
    blobZoneId: privateDnsZones.outputs.blobZoneId
    tags: tags
  }
}

module vmDbrx 'modules/compute/vm-dbrx.bicep' = {
  name: 'vmDbrx'
  params: {
    location: location
    subnetId: spokeDbrxVnet.outputs.subnetId
    adminUsername: adminUsername
    adminPublicKey: adminPublicKey
    allowedSshSourceIp: allowedSshSourceIp
    tags: tags
  }
}

// ── Phase 5: Identity & Role Assignments ─────────────────────────────────────

module roleAssignment 'modules/identity/role-assignment.bicep' = {
  name: 'roleAssignment'
  params: {
    principalId: vmDbrx.outputs.vmPrincipalId
    storageAccountId: adlsAccount.outputs.storageAccountId
    roleDefinitionId: storageBlobDataOwnerRoleId
  }
}

// ── Phase 6: Monitoring ──────────────────────────────────────────────────────

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

// ── Outputs ──────────────────────────────────────────────────────────────────

output vmPublicIp string = vmDbrx.outputs.vmPublicIp
output storageAccountName string = adlsAccount.outputs.storageAccountName
output dfsEndpoint string = adlsAccount.outputs.dfsEndpoint
output grafanaEndpoint string = grafana.outputs.grafanaEndpoint
