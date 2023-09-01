param openAiEndpoint string
param openAiApiKey string
param appInsightsInstrumentationKey string
param appInsightsId string
param rgLocation string
param rgId string = substring(uniqueString(resourceGroup().id), 0, 8)
param aiName string = guid('openai')

resource apiManagementService 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: 'APIM-${rgId}'
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

// todo: keep going through the actual UI and lining it up with the API reference on what to enable
// https://learn.microsoft.com/en-us/azure/templates/microsoft.apimanagement/service?pivots=deployment-language-bicep

// resource api 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
//   name: apiManagementService.name
// }

resource apiM 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  parent: apiManagementService
  name: 'OpenAIProxy'
  properties: {
    serviceUrl: openAiEndpoint
    path: 'openai'
    displayName: 'OpenAI Proxy API' // Added display name
    protocols: [ 'https' ]
    format: 'openapi-link'
    value: 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable/2023-05-15/inference.json'
    subscriptionRequired: false

  }

}

resource inboundPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-03-01-preview' = {
  parent: apiM
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: '''
      <policies>
      <inbound>
          <base />
          <set-backend-service backend-id="backend" />
      </inbound>
      <backend>
          <base />
      </backend>
      <outbound>
          <base />
      </outbound>
      <on-error>
          <base />
      </on-error>
    </policies>
  '''
  }
}

// have to add inbound policy with backend id to allow calls through

resource apiBackend 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = {
  parent: apiManagementService
  name: 'backend'
  properties: {
    url: openAiEndpoint
    protocol: 'http'
    title: 'OpenAI API'
    description: 'OpenAI API'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
    credentials: {
      header: {
        'api-key': [ openAiApiKey ]
      }
    }
  }
}

resource apiManagementLogger 'Microsoft.ApiManagement/service/loggers@2020-06-01-preview' = {
  parent: apiManagementService
  name: 'OpenAI-Logger'
  properties: {
    loggerType: 'applicationInsights'
    description: 'Logger for OpenAI API calls'
    resourceId: appInsightsId
    credentials: {
      instrumentationKey: appInsightsInstrumentationKey
    }
  }
}

resource apiDiagnostics 'Microsoft.ApiManagement/service/apis/diagnostics@2023-03-01-preview' = {
  name: 'applicationinsights'
  parent: apiM
  properties: {
    logClientIp: false
    alwaysLog: 'allErrors'
    loggerId: apiManagementLogger.id
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    metrics: true
    backend: {
      request: {
        body: {
          bytes: 8192
        }
      }
      response: {
        body: {
          bytes: 8192
        }
      }
    }
    verbosity: 'information'
  }
}
