param hubVnetId string
param spokeDbrxVnetId string
param spokeAdlsVnetId string
param spokePeVnetId string
param tags object = {}

// ── DFS Private DNS Zone ──
resource dfsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.dfs.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

resource dfsLinkHub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dfsZone
  name: 'link-hub'
  location: 'global'
  properties: {
    virtualNetwork: { id: hubVnetId }
    registrationEnabled: false
  }
}

resource dfsLinkDbrx 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dfsZone
  name: 'link-spoke-dbrx'
  location: 'global'
  properties: {
    virtualNetwork: { id: spokeDbrxVnetId }
    registrationEnabled: false
  }
}

resource dfsLinkAdls 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dfsZone
  name: 'link-spoke-adls'
  location: 'global'
  properties: {
    virtualNetwork: { id: spokeAdlsVnetId }
    registrationEnabled: false
  }
}

resource dfsLinkPe 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dfsZone
  name: 'link-spoke-pe'
  location: 'global'
  properties: {
    virtualNetwork: { id: spokePeVnetId }
    registrationEnabled: false
  }
}

// ── Blob Private DNS Zone ──
resource blobZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

resource blobLinkHub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: blobZone
  name: 'link-hub'
  location: 'global'
  properties: {
    virtualNetwork: { id: hubVnetId }
    registrationEnabled: false
  }
}

resource blobLinkDbrx 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: blobZone
  name: 'link-spoke-dbrx'
  location: 'global'
  properties: {
    virtualNetwork: { id: spokeDbrxVnetId }
    registrationEnabled: false
  }
}

resource blobLinkAdls 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: blobZone
  name: 'link-spoke-adls'
  location: 'global'
  properties: {
    virtualNetwork: { id: spokeAdlsVnetId }
    registrationEnabled: false
  }
}

resource blobLinkPe 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: blobZone
  name: 'link-spoke-pe'
  location: 'global'
  properties: {
    virtualNetwork: { id: spokePeVnetId }
    registrationEnabled: false
  }
}

output dfsZoneId string = dfsZone.id
output blobZoneId string = blobZone.id
