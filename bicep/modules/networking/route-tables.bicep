param location string
param tags object
param allowedSshSourceIp string = ''

resource rtDbrx 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'rt-dbrx'
  location: location
  tags: tags
  properties: {
    routes: concat(
      [
        {
          name: 'default-to-gateway'
          properties: {
            addressPrefix: '0.0.0.0/0'
            nextHopType: 'VirtualNetworkGateway'
          }
        }
      ],
      !empty(allowedSshSourceIp)
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
    )
  }
}

resource rtAdls 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'rt-adls'
  location: location
  tags: tags
  properties: {
    routes: [
      {
        name: 'default-to-gateway'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualNetworkGateway'
        }
      }
    ]
  }
}

output rtDbrxId string = rtDbrx.id
output rtAdlsId string = rtAdls.id
