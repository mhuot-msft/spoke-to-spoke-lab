param location string
param routeTableId string = ''
param tags object = {}

resource spokeAdlsVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-spoke-adls'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.102.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-adls'
        properties: {
          addressPrefix: '10.102.1.0/24'
          routeTable: routeTableId != '' ? { id: routeTableId } : null
        }
      }
      {
        name: 'subnet-pe'
        properties: {
          addressPrefix: '10.102.2.0/24'
        }
      }
    ]
  }
}

output vnetId string = spokeAdlsVnet.id
output vnetName string = spokeAdlsVnet.name
output subnetId string = spokeAdlsVnet.properties.subnets[0].id
output peSubnetId string = spokeAdlsVnet.properties.subnets[1].id
