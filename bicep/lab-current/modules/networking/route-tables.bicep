param location string
param allowedSshSourceIp string = ''
param tags object = {}

var defaultRoute = [
  {
    name: 'default-to-gateway'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopType: 'VirtualNetworkGateway'
    }
  }
]

var sshReturnRoute = allowedSshSourceIp != '' ? [
  {
    name: 'ssh-return'
    properties: {
      addressPrefix: '${allowedSshSourceIp}/32'
      nextHopType: 'Internet'
    }
  }
] : []

resource rtDbrx 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'rt-dbrx'
  location: location
  tags: tags
  properties: {
    routes: concat(defaultRoute, sshReturnRoute)
  }
}

resource rtAdls 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'rt-adls'
  location: location
  tags: tags
  properties: {
    routes: defaultRoute
  }
}

output rtDbrxId string = rtDbrx.id
output rtAdlsId string = rtAdls.id
