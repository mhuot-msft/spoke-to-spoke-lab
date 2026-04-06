// Grafana role assignments — Monitoring Reader + Reader at resource group scope
// Separated from grafana.bicep because principalId is a runtime value

param principalId string

var monitoringReaderRoleId = '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
var readerRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

resource monitoringReaderRg 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, monitoringReaderRoleId)
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringReaderRoleId)
    principalType: 'ServicePrincipal'
  }
}

resource readerRg 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, readerRoleId)
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
    principalType: 'ServicePrincipal'
  }
}
