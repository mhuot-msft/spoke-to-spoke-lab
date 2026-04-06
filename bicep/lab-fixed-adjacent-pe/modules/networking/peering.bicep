param localVnetName string
param remoteVnetName string
param allowGatewayTransit bool = false
param useRemoteGateways bool = false

resource localVnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: localVnetName
}

resource remoteVnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: remoteVnetName
}

resource localToRemote 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: localVnet
  name: '${localVnetName}-to-${remoteVnetName}'
  properties: {
    remoteVirtualNetwork: {
      id: remoteVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: allowGatewayTransit
  }
}

resource remoteToLocal 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: remoteVnet
  name: '${remoteVnetName}-to-${localVnetName}'
  properties: {
    remoteVirtualNetwork: {
      id: localVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    useRemoteGateways: useRemoteGateways
  }
}
