param principalId string
param storageAccountId string
param roleDefinitionId string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: last(split(storageAccountId, '/'))
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, principalId, roleDefinitionId)
  scope: storageAccount
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    principalType: 'ServicePrincipal'
  }
}
