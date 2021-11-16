param FunctionPrincipalId string
param AcrName string

var acrPullRoleDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' existing = {
  name: AcrName
}

resource functionPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: '${guid(resourceGroup().id, AcrName, acrPullRoleDefinitionId)}'
  scope: acr
  properties: {
    principalId: FunctionPrincipalId
    roleDefinitionId: acrPullRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}
