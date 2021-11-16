param AppName string
param AcrName string

var acrUrl = 'https://${AcrName}.azurecr.io'
var storageDataContributorRoleDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${AppName}appinsights'
  location: resourceGroup().location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: '${AppName}hp'
  location: resourceGroup().location
  kind: 'linux'
  properties: {
    targetWorkerSizeId: 3
    targetWorkerCount: 1
    reserved: true
  }
  sku: {
    tier: 'ElasticPremium'
    name: 'EP1'
  }
}

resource funcStorage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: '${AppName}funcstg'
  location: resourceGroup().location
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'
  identity: {
    type: 'SystemAssigned'
  }

  resource funcContainer 'fileServices@2021-04-01' = {
    name: 'default'

    resource Identifier 'shares@2021-04-01' = {
      name: functionApp.name
    }
  }
}

resource functionApp 'Microsoft.Web/sites@2021-01-15' = {
  name: '${AppName}testfunc'
  kind: 'functionapp,linux,container'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    hostingPlan
    funcStorage
  ]
  properties: {
    siteConfig: {
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/azure-functions/dotnet:3.0-appservice-quickstart'
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      scmIpSecurityRestrictions: [
        {
          ipAddress: 'AzureContainerRegistry'
          action: 'Allow'
          tag: 'ServiceTag'
          priority: 300
          description: 'Allow ACR with ServiceTag'
        }
      ]
      scmIpSecurityRestrictionsUseMain: false
      functionsRuntimeScaleMonitoringEnabled: false
    }
    serverFarmId: hostingPlan.id
    clientAffinityEnabled: false
  }
}

resource functionAppAppsettings 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: functionApp
  dependsOn: [
    appInsights
  ]
  name: 'appsettings'
  properties: {
    FUNCTIONS_EXTENSION_VERSION: '~3'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
    DOCKER_REGISTRY_SERVER_URL: acrUrl
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${funcStorage.name};AccountKey=${listKeys(funcStorage.id, funcStorage.apiVersion).keys[0].value};EndpointSuffix=core.windows.net'
    // AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${funcStorage.name};AccountKey=${listKeys(funcStorage.id, funcStorage.apiVersion).keys[0].value};EndpointSuffix=core.windows.net'
    AzureWebJobsStorage__accountName: funcStorage.name
    WEBSITE_CONTENTSHARE: functionApp.name
    WEBSITE_CONTENTOVERVNET: '1'
    WEBSITE_VNET_ROUTE_ALL: '1'
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
  }
}

resource functionConfigWeb 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: functionApp
  dependsOn: [
    functionAppAppsettings
  ]
  name: 'web'
  properties: {
    acrUseManagedIdentityCreds: true
    linuxFxVersion: 'DOCKER|${AcrName}.azurecr.io/funcbaseextended:1.0.0'
  }
}

resource backendStorageAccountRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: '${guid(resourceGroup().id, funcStorage.id, functionApp.name, storageDataContributorRoleDefinitionId)}'
  scope: funcStorage
  properties: {
    principalId: functionApp.identity.principalId
    roleDefinitionId: storageDataContributorRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    funcStorage
    functionApp
  ]
}

output FunctionPrincipalId string = functionApp.identity.principalId
