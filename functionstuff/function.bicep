param hostingPlanResourceId string
param functionName string
param storageKeySecretUri string
param appInsightsProperties object
param subnetResourceId string
param storageAccountName string

resource FunctionAppName_resource 'Microsoft.Web/sites@2021-01-15' = {
  name: functionName
  kind: 'functionapp,linux,container'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
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
    serverFarmId: hostingPlanResourceId
    clientAffinityEnabled: false
  }
}

// a comment! much amaze
resource FunctionName_default_healthcheck 'Microsoft.Web/sites/functions/keys@2021-01-15' = {
  name: '${functionName}/default/healthcheck'
}

resource FunctionAppName_virtualNetwork 'Microsoft.Web/sites/networkConfig@2021-01-15' = {
  name: '${FunctionAppName_resource.name}/virtualNetwork'
  properties: {
    subnetResourceId: subnetResourceId
    swiftSupported: true
  }
}

resource StorageAccountName_default_contentShareName 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = {
  name: '${storageAccountName}/default/${functionName}'
}

resource FunctionAppName_appsettings 'Microsoft.Web/sites/config@2021-01-15' = {
  name: '${FunctionAppName_resource.name}/appsettings'
  properties: {
    FUNCTIONS_EXTENSION_VERSION: '~3'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
    DOCKER_REGISTRY_SERVER_URL: 'https://mcr.microsoft.com'
    DOCKER_REGISTRY_SERVER_USERNAME: ''
    DOCKER_REGISTRY_SERVER_PASSWORD: ''
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(SecretUri=${storageKeySecretUri})'
    AzureWebJobsStorage: '@Microsoft.KeyVault(SecretUri=${storageKeySecretUri})'
    WEBSITE_CONTENTSHARE: functionName
    WEBSITE_CONTENTOVERVNET: '1'
    WEBSITE_VNET_ROUTE_ALL: '1'
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsProperties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsProperties.ConnectionString
  }
}
