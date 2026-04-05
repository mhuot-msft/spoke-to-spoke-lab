// Bidirectional VNet peering — generic module.
// Used for hub↔spoke AND spoke↔spoke peering.
// For spoke↔spoke, treat one spoke as "hub" and the other as "spoke".

param hubVnetName string
param hubVnetId string
param spokeVnetName string
param spokeVnetId string
param allowGatewayTransit bool = false
param useRemoteGateways bool = false

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: hubVnetName
}

resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: spokeVnetName
}

resource hubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: hubVnet
  name: 'peer-to-${spokeVnetName}'
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: false
  }
}

resource spokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: spokeVnet
  name: 'peer-to-${hubVnetName}'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: useRemoteGateways
  }
}
