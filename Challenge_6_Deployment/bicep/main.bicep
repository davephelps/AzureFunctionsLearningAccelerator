param functionAppName string
param storageAccountName string
param serviceBusNamespaceName string
param servicePlanName string
param location string = resourceGroup().location
param serviceBusNamespaceQualifiedName string = '${serviceBusNamespaceName}.servicebus.windows.net'

module azureFunction 'azureFunction.bicep' = {
  name: 'azureFunctionModule'
  params: {
    functionAppName: functionAppName
    storageAccountName: storageAccountName
    location: location
    serviceBusNamespaceQualifiedName: serviceBusNamespaceQualifiedName
    servicePlanName: servicePlanName
    applicationInsightsName: '${functionAppName}-appInsights'
    functionWorkerRuntime: 'dotnet'  
  }
}

module serviceBus 'serviceBus.bicep' = {
  name: 'serviceBusModule'
  params: {
    serviceBusNamespaceName: serviceBusNamespaceName
    location: location
  }
}

module roleAssignment 'roleAssignment.bicep' = {
  name: 'roleAssignmentModule'
  params: {
    serviceBusNamespaceId: serviceBus.outputs.serviceBusNamespaceId
    managedIdentityId: azureFunction.outputs.managedIdentityId
  }
  dependsOn: [
    azureFunction
    serviceBus
  ]
}

