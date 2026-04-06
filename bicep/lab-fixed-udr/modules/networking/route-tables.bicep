param location string
param allowedSshSourceIp string = ''
param tags object = {}

// UDR fix: no default-to-gateway catch-all route.
// Without the 0.0.0.0/0 → VirtualNetworkGateway UDR, spoke-to-spoke traffic
// relies on system routes and gateway-learned routes via gateway transit.

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
    routes: sshReturnRoute
  }
}

resource rtAdls 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'rt-adls'
  location: location
  tags: tags
  properties: {
    routes: []
  }
}

output rtDbrxId string = rtDbrx.id
output rtAdlsId string = rtAdls.id
