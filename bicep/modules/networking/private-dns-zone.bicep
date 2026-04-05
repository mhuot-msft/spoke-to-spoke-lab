param tags object
param hubVnetId string
param spokeDbrxVnetId string
param spokeAdlsVnetId string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.dfs.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

resource linkHub 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-vnet-hub'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: hubVnetId
    }
    registrationEnabled: false
  }
}

resource linkDbrx 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-vnet-spoke-dbrx'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: spokeDbrxVnetId
    }
    registrationEnabled: false
  }
}

resource linkAdls 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-vnet-spoke-adls'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: {
      id: spokeAdlsVnetId
    }
    registrationEnabled: false
  }
}

output dnsZoneId string = privateDnsZone.id
output dnsZoneName string = privateDnsZone.name
