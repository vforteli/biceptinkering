param AppName string
param DeployRedis bool = false
param CustomDomain string = ''

var appServiceName = '${AppName}-appservice'
var redisCacheName = '${AppName}-rediscache'
var serverFarmName = '${AppName}-asp'
var storageAccountName = '${AppName}storage'
var signalRRoleDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/420fcaa2-552c-430f-98ca-3264be4806c7'
var storageDataContributorRoleDefinitionId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var signalrServiceName = '${AppName}-signalr'

resource backendSignalRRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: '${guid(resourceGroup().id, signalrServiceName, signalRRoleDefinitionId, 'foo')}'
  scope: signalrService
  properties: {
    principalId: reference(appService.id, '2018-02-01', 'Full').identity.principalId
    roleDefinitionId: signalRRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    appService
    signalrService
  ]
}

resource backendStorageAccountRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: '${guid(resourceGroup().id, appServiceName, storageDataContributorRoleDefinitionId, 'foo')}'
  scope: storageAccount
  properties: {
    principalId: reference(appService.id, '2018-02-01', 'Full').identity.principalId
    roleDefinitionId: storageDataContributorRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    appService
    storageAccount
  ]
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: '${AppName}appvnet'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/23'
      ]
    }
    subnets: [
      {
        name: 'appsubnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: resourceGroup().location
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
  }
}

resource serverFarm 'Microsoft.Web/serverfarms@2020-12-01' = {
  location: resourceGroup().location
  name: serverFarmName
  kind: 'linux'
  properties: {
    targetWorkerSizeId: 6
    reserved: true
    targetWorkerCount: 1
  }
  sku: {
    tier: 'PremiumV3'
    name: 'P1V3'
  }
}

resource appService 'Microsoft.Web/sites@2020-12-01' = {
  name: appServiceName
  location: resourceGroup().location
  dependsOn: [
    serverFarm
  ]
  tags: {}
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'app,linux'
  properties: {
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|3.1'
      httpLoggingEnabled: true
      detailedErrorLoggingEnabled: true
      appSettings: [
        {
          name: 'SignalRConnectionString'
          value: 'Endpoint=https://${signalrServiceName}.service.signalr.net;AuthType=aad;'
        }
        {
          name: 'StorageAccountConnectionString'
          value: storageAccount.properties.primaryEndpoints.dfs
        }
      ]
      webSocketsEnabled: true
      ftpsState: 'Disabled'
      http20Enabled: true
      use32BitWorkerProcess: false
      phpVersion: 'OFF'
      alwaysOn: true
    }
    serverFarmId: serverFarm.id
  }

  resource networkConfig 'networkConfig@2021-02-01' = {
    name: 'virtualNetwork'
    dependsOn: [
      vnet
      appService
    ]
    properties: {
      swiftSupported: true
      subnetResourceId: vnet.properties.subnets[0].id
    }
  }

  resource config 'config@2021-02-01' = {
    name: 'web'
    dependsOn: [
      appService
      networkConfig
    ]
    properties: {
      vnetRouteAllEnabled: true
    }
  }
}

module customDomain 'customDomainModule.bicep' = if (length(CustomDomain) > 0) {
  name: 'customDomain'
  params: {
    AppServiceName: appService.name
    CustomDomain: CustomDomain
    ServerFarmId: serverFarm.id
  }
}

resource redisCache 'Microsoft.Cache/redis@2020-06-01' = if (DeployRedis) {
  name: redisCacheName
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'Basic'
      family: 'C'
      capacity: 0
    }
    enableNonSslPort: false
    publicNetworkAccess: 'Enabled'
    minimumTlsVersion: '1.2'
  }
}

resource signalrService 'Microsoft.SignalRService/signalR@2020-07-01-preview' = {
  location: resourceGroup().location
  name: signalrServiceName
  sku: {
    name: 'Free_F1'
    tier: 'Free'
    capacity: 1
  }
  kind: 'SignalR'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    tls: {
      clientCertEnabled: false
    }
    features: [
      {
        flag: 'ServiceMode'
        value: 'Default'
        properties: {}
      }
      {
        flag: 'EnableConnectivityLogs'
        value: 'True'
        properties: {}
      }
      {
        flag: 'EnableMessagingLogs'
        value: 'False'
        properties: {}
      }
    ]
    cors: {
      allowedOrigins: [
        '*'
      ]
    }
    upstream: {}
    networkACLs: {
      defaultAction: 'Deny'
      publicNetwork: {
        allow: [
          'ServerConnection'
          'ClientConnection'
        ]
      }
      privateEndpoints: []
    }
  }
}

output RedisCacheConnectionString string = DeployRedis ? listKeys(redisCache.id, '2020-06-01').primaryKey : ''
output SignalRConnectionString string = listKeys(signalrService.id, '2020-07-01-preview').primaryKey
