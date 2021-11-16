param AppName string
param FunctionAppName string
param FunctionSubnetName string

@description('description')
param SomeRandomIp string
param HostingPlanName string
param StorageAccountName string
param VNetName string

var appInsightsName_var = '${AppName}-appinsights'
var contentShareName = toLower(FunctionAppName)
var funcNsgName_var = '${AppName}-func-nsg'
var keyVaultName_var = '${AppName}-ke4v'
var logAnalyticsWorkspaceName_var = '${AppName}-laws'
var storageKeySecretName = 'funcstoragekey'

module func 'function.bicep' = {
  name: FunctionAppName
  params: {
    functionName: FunctionAppName
    appInsightsProperties: appInsightsName.properties
    hostingPlanResourceId: HostingPlanName_resource.id
    storageKeySecretUri: keyVaultName_storageKeySecretName.properties.secretUri
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', VNetName_resource.name, FunctionSubnetName)
    storageAccountName: StorageAccountName_resource.name
  }
}

resource HostingPlanName_resource 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: HostingPlanName
  location: resourceGroup().location
  kind: 'linux'
  properties: {
    targetWorkerSizeId: 3
    targetWorkerCount: 1
    reserved: true
    maximumElasticWorkerCount: 20
  }
  sku: {
    tier: 'ElasticPremium'
    name: 'EP1'
  }
}

resource StorageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: StorageAccountName
  location: resourceGroup().location
  kind: 'StorageV2'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: resourceId('Microsoft.Network/virtualNetworks/subnets', VNetName, FunctionSubnetName)
        }
      ]
    }
  }
}

resource StorageAccountName_default_contentShareName 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-04-01' = {
  name: '${StorageAccountName}/default/${contentShareName}'
}

resource VNetName_resource 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: VNetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/22'
      ]
    }
    subnets: [
      {
        name: FunctionSubnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: funcNsgName.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                '*'
              ]
            }
            {
              service: 'Microsoft.AzureActiveDirectory'
              locations: [
                '*'
              ]
            }
            {
              service: 'Microsoft.KeyVault'
              locations: [
                '*'
              ]
            }
            {
              service: 'Microsoft.ContainerRegistry'
              locations: [
                '*'
              ]
            }
            {
              service: 'Microsoft.ServiceBus'
              locations: [
                '*'
              ]
            }
          ]
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
        }
      }
    ]
  }
}

resource appInsightsName 'microsoft.insights/components@2020-02-02-preview' = {
  kind: 'web'
  name: appInsightsName_var
  location: resourceGroup().location
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceName.id
  }
}

resource funcNsgName 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: funcNsgName_var
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'DenyInternet'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowStorage'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Storage.NorthEurope'
          access: 'Allow'
          priority: 510
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRange: '*'
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowSomething'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: SomeRandomIp
          access: 'Allow'
          priority: 515
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRange: '*'
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowAppInsights'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureMonitor'
          access: 'Allow'
          priority: 520
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowKeyVault'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureKeyVault.NorthEurope'
          access: 'Allow'
          priority: 530
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowAppService'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AppService.NorthEurope'
          access: 'Allow'
          priority: 590
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowACR'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureContainerRegistry.NorthEurope'
          access: 'Allow'
          priority: 550
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowMCR'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'MicrosoftContainerRegistry.NorthEurope'
          access: 'Allow'
          priority: 560
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource keyVaultName 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  location: resourceGroup().location
  name: keyVaultName_var
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    accessPolicies: [
      {
        tenantId: reference('Microsoft.Web/sites/${FunctionAppName}', '2020-06-01', 'Full').identity.tenantId
        objectId: reference('Microsoft.Web/sites/${FunctionAppName}', '2020-06-01', 'Full').identity.principalId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}

resource keyVaultName_storageKeySecretName 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVaultName.name}/${storageKeySecretName}'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${StorageAccountName};AccountKey=${listKeys(StorageAccountName_resource.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
  }
}

resource logAnalyticsWorkspaceName 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: logAnalyticsWorkspaceName_var
  location: resourceGroup().location
}
