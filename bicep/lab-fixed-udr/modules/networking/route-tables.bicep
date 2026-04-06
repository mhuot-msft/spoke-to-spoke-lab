param location string
param allowedSshSourceIp string = ''
param tags object = {}

// UDR fix: replace the catch-all 0.0.0.0/0 → VirtualNetworkGateway with
// specific routes only for spoke-to-spoke traffic. Internet and other traffic
// uses default system routes instead of being forced through the gateway.

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
    routes: concat([
      {
        name: 'to-spoke-adls'
        properties: {
          addressPrefix: '10.102.0.0/16'
          nextHopType: 'VirtualNetworkGateway'
        }
      }
    ], sshReturnRoute)
  }
}

resource rtAdls 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'rt-adls'
  location: location
  tags: tags
  properties: {
    routes: [
      {
        name: 'to-spoke-dbrx'
        properties: {
          addressPrefix: '10.101.0.0/16'
          nextHopType: 'VirtualNetworkGateway'
        }
      }
    ]
  }
}

output rtDbrxId string = rtDbrx.id
output rtAdlsId string = rtAdls.id
