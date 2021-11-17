param CustomDomain string
param AppServiceName string

@secure()
param FrontendCertificatePfxBase64 string
@secure()
param FrontendCertificatePassword string

resource appService 'Microsoft.Web/sites@2021-02-01' existing = {
  name: AppServiceName
}

var appGatewayName = 'appgateway'
var httpListenerName = 'defaultHttpListener'
var appserviceBackendName = 'appservicebackend'
var httpSettingsName = 'httpsettingsname'
var requestRoutingRuleName = 'requestRoutingRuleName'
var appServiceBackendProbeName = 'appServiceBackendProbe'
var frontendIpConfigName = 'frontendIpConfig'
var frontendHttpsPortName = 'frontendHttpPort'
var appGatewaySubnetName = 'appgatewaysubnet'
var gatewayCertificateName = 'appgatewaycertname'

resource appGatewayVnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: 'appgatewayvnet'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/23'
      ]
    }
    subnets: [
      {
        name: appGatewaySubnetName
        properties: {
          addressPrefix: '10.1.0.0/24'
        }
      }
    ]
  }
}

resource appGatewayIpAddress 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: 'appGatewayIp'
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2021-03-01' = {
  name: appGatewayName
  location: resourceGroup().location
  dependsOn: [
    appGatewayIpAddress
  ]
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 10
    }
    gatewayIPConfigurations: [
      {
        name: 'gatewayIpConfiguration'
        properties: {
          subnet: {
            id: '${appGatewayVnet.id}/subnets/${appGatewaySubnetName}'
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: frontendIpConfigName
        properties: {
          publicIPAddress: {
            id: appGatewayIpAddress.id
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: gatewayCertificateName
        properties: {
          data: FrontendCertificatePfxBase64
          password: FrontendCertificatePassword
        }
      }
    ]
    frontendPorts: [
      {
        name: frontendHttpsPortName
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appServiceBackend'
        properties: {
          backendAddresses: [
            {
              fqdn: appService.properties.defaultHostName
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: httpSettingsName
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 30
          hostName: CustomDomain
          probe: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/probes/${appServiceBackendProbeName}'
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'defaultHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/frontendIPConfigurations/${frontendIpConfigName}'
          }
          frontendPort: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/frontendPorts/${frontendHttpsPortName}'
          }
          protocol: 'Https'
          hostNames: []
          requireServerNameIndication: false
          sslCertificate: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/sslCertificates/${gatewayCertificateName}'
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: requestRoutingRuleName
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/httpListeners/${httpListenerName}'
          }
          priority: null
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/backendAddressPools/${appserviceBackendName}'
          }
          backendHttpSettings: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName)}/backendHttpSettingsCollection/${httpSettingsName}'
          }
        }
      }
    ]
    probes: [
      {
        name: appServiceBackendProbeName
        properties: {
          host: CustomDomain
          interval: 30
          minServers: 0
          path: '/'
          protocol: 'Https'
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          match: {
            statusCodes: [
              '200-401'
            ]
          }
        }
      }
    ]
  }
}
