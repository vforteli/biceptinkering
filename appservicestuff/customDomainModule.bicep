param CustomDomain string
param ServerFarmId string
param AppServiceName string

resource customDomainCertificate 'Microsoft.Web/certificates@2021-02-01' = {
  name: CustomDomain
  location: resourceGroup().location
  properties: {
    canonicalName: CustomDomain
    serverFarmId: ServerFarmId
    domainValidationMethod: 'http-token'
  }
}

resource appService 'Microsoft.Web/sites@2021-02-01' existing = {
  name: AppServiceName
}

resource hostnameBinding 'Microsoft.Web/sites/hostNameBindings@2021-02-01' = {
  parent: appService
  name: CustomDomain
  dependsOn: [
    appService
    customDomainCertificate
  ]
  properties: {
    sslState: 'SniEnabled'
    thumbprint: customDomainCertificate.properties.thumbprint
  }
}
