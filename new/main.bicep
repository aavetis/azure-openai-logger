// Importing variables
param openAiEndpoint string
param openAiApiKey string
param rgLocation string = resourceGroup().location

// API Management
module apiManagement './apiManagement.bicep' = {
  name: 'apiManagementModule'
  params: {
    openAiEndpoint: openAiEndpoint
    openAiApiKey: openAiApiKey
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    appInsightsId: appInsights.outputs.id
    rgLocation: rgLocation
  }
}

// Application Insights
module appInsights './appInsights.bicep' = {
  name: 'appInsightsModule'
  params: {
    rgLocation: rgLocation
  }
}

// Azure Dashboard
resource dashboard 'Microsoft.Portal/dashboards@2015-08-01-preview' = {
  name: 'OpenAIDashboard'
  location: 'global'
  properties: {
    lenses: {
      '0': {
        order: 0
        parts: {
          '0': {
            position: { x: 0, y: 0, rowSpan: 2, colSpan: 3 }
            metadata: {
              inputs: [
                {
                  name: 'ComponentId'
                  value: appInsights.outputs.instrumentationKey
                }
                {
                  name: 'Query'
                  value: 'requests | summarize count() by bin(timestamp, 1h) | render timechart' // Example query
                }
              ]
              type: 'Extension/AppInsightsExtension/PartType/AnalyticsPart'
            }
          }
          // Additional tiles as needed
        }
      }
    }
  }
}
