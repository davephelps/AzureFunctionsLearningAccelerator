param serviceBusNamespaceId string
param managedIdentityId string



resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(serviceBusNamespaceId, managedIdentityId, '090c5cfd-751d-490a-894a-3ce6f1109419')
  //scope: tenant()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '090c5cfd-751d-490a-894a-3ce6f1109419') // Azure Service Bus Data Receiver role
    principalId: managedIdentityId
  }
}


