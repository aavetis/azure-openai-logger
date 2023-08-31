param openAiEndpoint string
param openAiApiKey string
param appInsightsInstrumentationKey string
param rgLocation string

resource apiManagementService 'Microsoft.ApiManagement/service@2020-06-01-preview' = {
  name: 'OpenAIApiManagement-test010101133'
  location: rgLocation
  sku: {
    name: 'Consumption'
    capacity: 0
  }
  properties: {
    publisherEmail: 'info@example.com'
    publisherName: 'OpenAI Publisher'
  }
}

resource apiManagementLogger 'Microsoft.ApiManagement/service/loggers@2020-06-01-preview' = {
  parent: apiManagementService
  name: 'appInsightsLogger'
  properties: {
    loggerType: 'applicationInsights'
    description: 'Logger for OpenAI API calls'
    credentials: {
      instrumentationKey: appInsightsInstrumentationKey
    }
  }
}

// todo: keep going through the actual UI and lining it up with the API reference on what to enable
// https://learn.microsoft.com/en-us/azure/templates/microsoft.apimanagement/service?pivots=deployment-language-bicep

resource api 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: apiManagementService.name
}

resource apiM 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  parent: api
  name: 'OpenAIProxy'
  properties: {
    serviceUrl: openAiEndpoint
    path: 'openai'
    displayName: 'OpenAI Proxy API' // Added display name
    protocols: [ 'https' ] // Added supported protocol
    format: 'openapi-link'
    value: 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable/2023-05-15/inference.json'
  }
}

resource apiBackend 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = {
  name: '${api.name}/openai'
  properties: {
    url: openAiEndpoint
    protocol: 'https'
    title: 'OpenAI API'
    description: 'OpenAI API'
    credentials: {
      // query: {
      //   subscriptionKey: openAiApiKey

      // }
      header: {
        'api-key': openAiApiKey
      }
    }
  }
}

resource apiDiagnostics 'Microsoft.ApiManagement/service/diagnostics@2023-03-01-preview' = {
  parent: apiBackend

}

// resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2020-06-01-preview' = {
//   name: '${api.name}/policy'
//   properties: {
//     format: 'rawxml'
//     value: '''
//     <policies>
//       <inbound>
//         <set-header name="Ocp-Apim-Subscription-Key" exists-action="delete" />
//         <set-header name="Ocp-Apim-Trace" exists-action="delete" />
//         <log-to-eventhub logger-id="appInsightsLogger">@((string)context.Request.Body.As<JObject>())</log-to-eventhub>
//         <base />
//       </inbound>
//       <backend>
//         <base />
//       </backend>
//       <outbound>
//         <base />
//       </outbound>
//       <on-error>
//         <base />
//       </on-error>
//     </policies>
//     '''
//   }
// }
