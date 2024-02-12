param serviceBusNamespaceName string
param location string = resourceGroup().location

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-01-01-preview' = {
  name: '${serviceBusNamespaceName}${uniqueString(resourceGroup().id)}'   
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource sbQueueOrders 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  parent: serviceBusNamespace
  name: 'orders'
}

output serviceBusNamespaceId string = serviceBusNamespace.id
