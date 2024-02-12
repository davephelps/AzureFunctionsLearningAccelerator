param functionAppName string
param storageAccountName string
param location string = resourceGroup().location
param servicePlanName string
param applicationInsightsName string
param functionWorkerRuntime string = 'dotnet'
param serviceBusNamespaceQualifiedName string



resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${functionAppName}ManagedIdentity'
  location: location
}

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: servicePlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}



resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'

}

resource functionApp 'Microsoft.Web/sites@2020-06-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }

  properties: { serverFarmId: hostingPlan.id, siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~14'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
        {
          name: 'ServiceBusConnection__clientID'
          value: managedIdentity.properties.clientId
        }
        {
          name: 'ServiceBusConnection__credential'
          value: 'managedIdentity'
        }
        {
          name: 'ServiceBusConnection__fullyQualifiedNamespace'
          value: serviceBusNamespaceQualifiedName
        }

      ]
    } }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

//output principalId string = functionApp.identity.principalId
//output id string = functionApp.id

output managedIdentityId string = managedIdentity.properties.principalId
output functionAppId string = functionApp.id
//output managedIdentity object = managedIdentity
