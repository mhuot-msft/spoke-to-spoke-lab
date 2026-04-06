// Adjacent private endpoints — DFS + Blob PEs in the consumer's VNet (spoke-dbrx)
// Placing PEs in the same VNet as the VM bypasses forced tunneling UDRs
// because InterfaceEndpoint /32 routes use VnetLocal, not the default route.

param location string
param tags object
param storageAccountId string
param subnetId string
param dfsZoneId string
param blobZoneId string

resource peDfsLocal 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: 'pe-adls-dfs-local'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pls-adls-dfs-local'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [
            'dfs'
          ]
        }
      }
    ]
  }
}

resource dfsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: peDfsLocal
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'dfs'
        properties: {
          privateDnsZoneId: dfsZoneId
        }
      }
    ]
  }
}

resource peBlobLocal 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: 'pe-adls-blob-local'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pls-adls-blob-local'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource blobZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: peBlobLocal
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob'
        properties: {
          privateDnsZoneId: blobZoneId
        }
      }
    ]
  }
}
