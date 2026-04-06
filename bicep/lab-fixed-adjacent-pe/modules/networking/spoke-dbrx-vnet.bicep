// Spoke 1 VNet — Adjacent PE fix: includes a PE subnet for local private endpoints
param location string
param routeTableId string = ''
param tags object = {}

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
          routeTable: routeTableId != '' ? { id: routeTableId } : null
        }
      }
      {
        name: 'subnet-pe'
        properties: {
          addressPrefix: '10.101.2.0/24'
        }
      }
    ]
  }
}

output vnetId string = spokeDbrxVnet.id
output vnetName string = spokeDbrxVnet.name
output subnetId string = spokeDbrxVnet.properties.subnets[0].id
output peSubnetId string = spokeDbrxVnet.properties.subnets[1].id
