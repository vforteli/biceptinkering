param AppName string

var datalakeName = '${AppName}dl'
var databricksName = '${AppName}databricks'
var vnetName = '${AppName}-vnet'

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/20'
      ]
    }
  }
}

resource datalake 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: datalakeName
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

resource databricks 'Microsoft.Databricks/workspaces@2018-04-01' = {
  name: databricksName
  location: resourceGroup().location
  properties: {
    managedResourceGroupId: resourceGroup().id
  }
  dependsOn: [
    datalake
  ]
}
