param openAiEndpoint string
param openAiApiKey string
param rgLocation string = resourceGroup().location

// Application Insights
module appInsights './appInsights.bicep' = {
  name: 'appInsightsModule'
  params: {
    rgLocation: rgLocation
  }
}

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

// Dashboard (WIP)
module dashboard './dashboard.bicep' = {
  name: 'dashboardModule'
  params: {
    apiGateway: apiManagement.outputs.gatewayUrl
    appInsightsId: appInsights.outputs.id
    appInsightsName: appInsights.name
  }
}
