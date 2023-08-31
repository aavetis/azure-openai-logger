param inputEventHubNamespace string
param inputEventHubName string
param appInsightsInstrumentationKey string

resource streamAnalyticsJob 'Microsoft.StreamAnalytics/streamingjobs@2020-03-01' = {
  name: 'OpenAIStreamAnalytics'
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'Standard'
    }
    inputs: [
      {
        name: 'EventHubInput'
        properties: {
          type: 'Stream'
          datasource: {
            type: 'Microsoft.EventHub/EventHub'
            properties: {
              eventHubNamespace: inputEventHubNamespace
              eventHubName: inputEventHubName
              sharedAccessPolicyName: 'RootManageSharedAccessKey'
            }
          }
          serialization: {
            type: 'Json'
            properties: {
              encoding: 'UTF8'
            }
          }
        }
      }
    ]
    transformation: {
      name: 'ProcessOpenAIData'
      query: 'SELECT * INTO AppInsightsOutput FROM EventHubInput' // Define query based on your schema
    }
    outputs: [
      {
        name: 'AppInsightsOutput'
        properties: {
          type: 'Microsoft.Insights/components'
          properties: {
            instrumentationKey: appInsightsInstrumentationKey
          }
        }
      }
    ]
  }
}
