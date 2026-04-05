param location string
param tags object
param storageAccountSuffix string
param subnetPeId string
param dfsZoneId string
param blobZoneId string

var storageAccountName = 'saadlslab${storageAccountSuffix}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    isHnsEnabled: true
    publicNetworkAccess: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
}

// --- DFS Private Endpoint ---

resource peDfs 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: 'pe-adls-dfs'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetPeId
    }
    privateLinkServiceConnections: [
      {
        name: 'pls-adls-dfs'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'dfs'
          ]
        }
      }
    ]
  }
}

resource dfsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: peDfs
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

// --- Blob Private Endpoint ---

resource peBlob 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: 'pe-adls-blob'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetPeId
    }
    privateLinkServiceConnections: [
      {
        name: 'pls-adls-blob'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource blobZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: peBlob
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

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
output dfsEndpoint string = 'https://${storageAccount.name}.dfs.${environment().suffixes.storage}'
