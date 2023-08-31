resource eventHubNamespace 'Microsoft.EventHub/namespaces@2017-04-01' = {
  name: 'OpenAIEventHubNamespace'
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'Standard'
      tier: 'Standard'
    }
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2017-04-01' = {
  name: '${eventHubNamespace.name}/OpenAIEventHub'
  location: resourceGroup().location
}

output namespaceName string = eventHubNamespace.name
output eventHubName string = eventHub.name
