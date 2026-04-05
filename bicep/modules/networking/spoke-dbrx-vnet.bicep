param location string
param tags object
param routeTableId string = ''

resource spokeDbrxVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-spoke-dbrx'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.101.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-dbrx'
        properties: {
          addressPrefix: '10.101.1.0/24'
          routeTable: !empty(routeTableId) ? { id: routeTableId } : null
        }
      }
    ]
  }
}

output vnetId string = spokeDbrxVnet.id
output vnetName string = spokeDbrxVnet.name
output subnetId string = spokeDbrxVnet.properties.subnets[0].id
