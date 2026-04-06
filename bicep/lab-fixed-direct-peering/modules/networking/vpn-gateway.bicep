param location string
param tags object
param gatewaySubnetId string

resource pipVpnGw 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-vpn-gw-hub'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-11-01' = {
  name: 'vpn-gw-hub'
  location: location
  tags: tags
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    sku: {
      name: 'VpnGw1AZ'
      tier: 'VpnGw1AZ'
    }
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          publicIPAddress: {
            id: pipVpnGw.id
          }
          subnet: {
            id: gatewaySubnetId
          }
        }
      }
    ]
  }
}

output gatewayId string = vpnGateway.id
output gatewayName string = vpnGateway.name
