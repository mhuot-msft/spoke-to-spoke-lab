// Dedicated PE spoke VNet — hosts centralized private endpoints
param location string
param routeTableId string = ''
param tags object = {}

resource spokePeVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-spoke-pe'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.103.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-pe'
        properties: {
          addressPrefix: '10.103.2.0/24'
          routeTable: routeTableId != '' ? { id: routeTableId } : null
        }
      }
    ]
  }
}

output vnetId string = spokePeVnet.id
output vnetName string = spokePeVnet.name
output peSubnetId string = spokePeVnet.properties.subnets[0].id
