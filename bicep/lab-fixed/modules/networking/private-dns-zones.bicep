param tags object
param hubVnetId string
param spokeDbrxVnetId string
param spokeAdlsVnetId string

// --- DFS Private DNS Zone ---

resource dnsZoneDfs 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.dfs.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

resource dfsLinkHub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dnsZoneDfs
  name: 'link-dfs-vnet-hub'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: hubVnetId
    }
    registrationEnabled: false
  }
}

resource dfsLinkDbrx 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dnsZoneDfs
  name: 'link-dfs-vnet-spoke-dbrx'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: spokeDbrxVnetId
    }
    registrationEnabled: false
  }
}

resource dfsLinkAdls 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dnsZoneDfs
  name: 'link-dfs-vnet-spoke-adls'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: spokeAdlsVnetId
    }
    registrationEnabled: false
  }
}

// --- Blob Private DNS Zone ---

resource dnsZoneBlob 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

resource blobLinkHub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dnsZoneBlob
  name: 'link-blob-vnet-hub'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: hubVnetId
    }
    registrationEnabled: false
  }
}

resource blobLinkDbrx 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dnsZoneBlob
  name: 'link-blob-vnet-spoke-dbrx'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: spokeDbrxVnetId
    }
    registrationEnabled: false
  }
}

resource blobLinkAdls 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dnsZoneBlob
  name: 'link-blob-vnet-spoke-adls'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: spokeAdlsVnetId
    }
    registrationEnabled: false
  }
}

output dfsZoneId string = dnsZoneDfs.id
output dfsZoneName string = dnsZoneDfs.name
output blobZoneId string = dnsZoneBlob.id
output blobZoneName string = dnsZoneBlob.name
