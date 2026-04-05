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

// --- Phase 2: VPN Gateway (20-40 min deployment) ---

module vpnGateway 'modules/networking/vpn-gateway.bicep' = {
  name: 'vpn-gateway'
  params: {
    location: location
    tags: tags
    gatewaySubnetId: hubVnet.outputs.gatewaySubnetId
  }
}

// --- Phase 3: VNet Peering (requires gateway to be provisioned) ---

module peeringDbrx 'modules/networking/peering.bicep' = {
  name: 'peering-hub-dbrx'
  params: {
    hubVnetName: hubVnet.outputs.vnetName
    hubVnetId: hubVnet.outputs.vnetId
    spokeVnetName: spokeDbrxVnet.outputs.vnetName
    spokeVnetId: spokeDbrxVnet.outputs.vnetId
    allowGatewayTransit: true
    useRemoteGateways: true
  }
  dependsOn: [
    vpnGateway
  ]
}

module peeringAdls 'modules/networking/peering.bicep' = {
  name: 'peering-hub-adls'
  params: {
    hubVnetName: hubVnet.outputs.vnetName
    hubVnetId: hubVnet.outputs.vnetId
    spokeVnetName: spokeAdlsVnet.outputs.vnetName
    spokeVnetId: spokeAdlsVnet.outputs.vnetId
    allowGatewayTransit: true
    useRemoteGateways: true
  }
  dependsOn: [
    vpnGateway
  ]
}

// --- Phase 4: Private DNS + Storage ---

module privateDnsZone 'modules/networking/private-dns-zone.bicep' = {
  name: 'private-dns-zone'
  params: {
    tags: tags
    hubVnetId: hubVnet.outputs.vnetId
    spokeDbrxVnetId: spokeDbrxVnet.outputs.vnetId
    spokeAdlsVnetId: spokeAdlsVnet.outputs.vnetId
  }
}

module adlsAccount 'modules/storage/adls-account.bicep' = {
  name: 'adls-account'
  params: {
    location: location
    tags: tags
    storageAccountSuffix: storageAccountSuffix
    subnetPeId: spokeAdlsVnet.outputs.subnetPeId
    privateDnsZoneId: privateDnsZone.outputs.dnsZoneId
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

// --- Outputs ---

output vmPublicIp string = vmDbrx.outputs.vmPublicIp
output storageAccountName string = adlsAccount.outputs.storageAccountName
output dfsEndpoint string = adlsAccount.outputs.dfsEndpoint
