param location string
param tags object = {}

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-hub'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.100.0.0/27'
        }
      }
    ]
  }
}

output vnetId string = hubVnet.id
output vnetName string = hubVnet.name
output gatewaySubnetId string = hubVnet.properties.subnets[0].id
