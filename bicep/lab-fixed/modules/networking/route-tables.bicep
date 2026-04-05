// FIXED: No default-to-gateway route. Spoke-to-spoke traffic uses direct peering
// with system routes — no VPN gateway in the data path.

param location string
param tags object
param allowedSshSourceIp string = ''

resource rtDbrx 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'rt-dbrx'
  location: location
  tags: tags
  properties: {
    routes: !empty(allowedSshSourceIp)
      ? [
          {
            name: 'ssh-return'
            properties: {
              addressPrefix: '${allowedSshSourceIp}/32'
              nextHopType: 'Internet'
            }
          }
        ]
      : []
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
