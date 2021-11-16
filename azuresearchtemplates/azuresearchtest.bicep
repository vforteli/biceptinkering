param AppName string

var storageAccountNameName = '${AppName}storage'
var azureSearchServiceName = '${AppName}searchservice'
var storageDataContributorRoleDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource azureSearchStorageAccountRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: '${guid(resourceGroup().id, azureSearchServiceName, storageDataContributorRoleDefinitionId, 'foo')}'
  scope: storageAccount
  properties: {
    principalId: reference(azureSearchService.id, '2021-04-01-preview', 'Full').identity.principalId
    roleDefinitionId: storageDataContributorRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    azureSearchService
    storageAccount
  ]
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountNameName
  location: resourceGroup().location
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: true
    supportsHttpsTrafficOnly: true
  }
  resource inventory 'inventoryPolicies' = {
    name: 'default'
    dependsOn: [
      blobServices
    ]
    properties: {
      policy: {
        type: 'Inventory'
        rules: [
          {
            name: 'manifest'
            destination: 'manifest'
            enabled: true
            definition: {
              format: 'Csv'
              filters: {
                blobTypes: [
                  'blockBlob'
                ]
              }
              objectType: 'Blob'
              schedule: 'Daily'
              schemaFields: [
                'Name'
                'Creation-Time'
                'Last-Modified'
                'Content-Length'
                'BlobType'
                'Metadata'
                'LastAccessTime'
              ]
            }
          }
        ]
        enabled: true
      }
    }
  }
  resource blobServices 'blobServices' = {
    name: 'default'
    resource documentsContainer 'containers' = {
      name: 'documents'
    }
    resource manifestContainer 'containers' = {
      name: 'manifest'
    }
  }
}

resource azureSearchService 'Microsoft.Search/searchServices@2021-04-01-preview' = {
  name: azureSearchServiceName
  location: resourceGroup().location
  sku: {
    name: 'basic'
  }
  properties: {
    partitionCount: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
}
