// Parameters for OpenAI configuration
param location string = resourceGroup().location
param openAiEndpoint string
@secure()
param openAiApiKey string

// Unique identifier to ensure globally unique names
var uniqueId = uniqueString(resourceGroup().id)

// API Management setup to manage and monitor OpenAI APIs
resource apiManagement 'Microsoft.ApiManagement/service@2020-06-01-preview' = {
  name: 'LogLLMOpenApiManagement${uniqueId}'
  location: location
  sku: {
    name: 'Developer'
    capacity: 1
  }
  properties: {
    publisherEmail: 'email@example.com'
    publisherName: 'Your Organization'
  }
}

// Event Hub setup for scalable event streaming and logging
resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-01-01-preview' = {
  name: 'LogLLMEventHubNamespace'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-01-01-preview' = {
  name: '${eventHubNamespace.name}/LogLLMEventHub'
  location: location
}

// Managed Identity setup for secure access control
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'LogLLMOpenAiManagedIdentity'
  location: location
}

resource eventHubNamespaceRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(eventHubNamespace.id, 'Azure Event Hubs Data Sender')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2b7893c4-684e-4acc-a535-f6e7f661b33a')
    principalId: managedIdentity.properties.principalId
  }
  scope: eventHubNamespace
}

// Stream Analytics setup for real-time data stream processing
resource streamAnalyticsJob 'Microsoft.StreamAnalytics/streamingjobs@2017-04-01-preview' = {
  name: 'LogLLMStreamAnalyticsJob'
  location: location
  properties: {
    sku: {
      name: 'Standard'
    }
    // Additional configuration for input, output, transformation, etc., will go here
  }
}

resource streamAnalyticsInput 'Microsoft.StreamAnalytics/streamingjobs/inputs@2017-04-01-preview' = {
  name: '${streamAnalyticsJob.name}/LogLLMEventHubInput'
  properties: {
    type: 'Stream'
    datasource: {
      type: 'Microsoft.EventHub/EventHub'
      properties: {
        eventHubNamespace: eventHubNamespace.name
        eventHubName: eventHub.name
        sharedAccessPolicyName: 'RootManageSharedAccessKey'
      }
    }
  }
}

// Custom Policy for OpenAI integration within API Management
resource apiManagementPolicy 'Microsoft.ApiManagement/service/policies@2020-06-01-preview' = {
  name: '${apiManagement.name}/policy'
  properties: {
    value: '<policies><inbound><set-header name="Authorization" exists-action="override"><value>@($"Bearer {openAiApiKey}")</value></set-header></inbound></policies>'
    format: 'xml'
  }
}
