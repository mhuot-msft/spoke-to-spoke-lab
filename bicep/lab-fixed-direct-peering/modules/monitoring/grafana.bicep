// Azure Managed Grafana — Standard SKU with system-assigned managed identity

param name string
param location string
param tags object

// Grafana instance
resource grafana 'Microsoft.Dashboard/grafana@2023-09-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    apiKey: 'Disabled'
    deterministicOutboundIP: 'Disabled'
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
    grafanaIntegrations: {
      azureMonitorWorkspaceIntegrations: []
    }
  }
}

output grafanaEndpoint string = grafana.properties.endpoint
output grafanaPrincipalId string = grafana.identity.principalId
