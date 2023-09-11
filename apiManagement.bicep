param openAiEndpoint string
param openAiApiKey string
param appInsightsInstrumentationKey string
param appInsightsId string
param rgLocation string
param rgId string = substring(uniqueString(resourceGroup().id), 0, 8)

resource apiManagementService 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: 'OpenAI-API-${rgId}'
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

/*
todos
- add keyvault for named value on api? might be dumb, because we need the api key at some point anyway
-
*/

var endpoint = '${openAiEndpoint}/openai'

resource openAiApiProxy 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  parent: apiManagementService
  name: 'OpenAIProxy'
  properties: {
    serviceUrl: endpoint
    path: 'openai'
    displayName: 'OpenAI Proxy API' // Added display name
    protocols: [ 'https' ]
    format: 'openapi-link'
    value: 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable/2023-05-15/inference.json'
    subscriptionRequired: true
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
  }
}

resource apiSubscription 'Microsoft.ApiManagement/service/subscriptions@2023-03-01-preview' = {
  parent: apiManagementService
  name: 'OpenAI-Subscription'
  properties: {
    scope: openAiApiProxy.id
    displayName: 'OpenAI Subscription'
    state: 'active'
  }
}

resource inboundPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-03-01-preview' = {
  parent: openAiApiProxy
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

resource apiBackend 'Microsoft.ApiManagement/service/backends@2023-03-01-preview' = {
  parent: apiManagementService
  name: 'backend'
  properties: {
    url: endpoint
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
  parent: openAiApiProxy
  properties: {
    logClientIp: false
    alwaysLog: 'allErrors'
    loggerId: apiManagementLogger.id
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    metrics: true
    frontend: {
      request: {
        headers: [
          'custom-headers'
        ]
        body: {
          bytes: 8192
        }
      }
      response: {
        headers: [
          'custom-headers'
        ]
        body: {
          bytes: 8192
        }
      }
    }
    backend: {
      request: {
        headers: [
          'custom-headers'
        ]
        body: {
          bytes: 8192
        }
      }
      response: {
        headers: [
          'custom-headers'
        ]
        body: {
          bytes: 8192
        }
      }
    }
    verbosity: 'information'
  }
}

output url string = openAiApiProxy.properties.serviceUrl
output gatewayUrl string = apiManagementService.properties.gatewayUrl
