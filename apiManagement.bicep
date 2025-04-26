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

var endpoint = '${openAiEndpoint}/openai'

resource openAiApiProxy 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  parent: apiManagementService
  name: 'OpenAIProxy'
  properties: {
    serviceUrl: endpoint
    path: 'openai'
    displayName: 'OpenAI Proxy API'
    protocols: ['https']
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
          <!-- Explicitly convert RequestId to string -->
          <set-variable name="requestId" value="@((string)context.RequestId.ToString())" />
          <base />
          <set-backend-service backend-id="backend" />
        </inbound>
        <backend>
          <base />
        </backend>
        <outbound>
          <base />
          <!-- Pass requestId back in response header -->
          <set-header name="x-request-id" exists-action="override">
            <value>@((string)context.Variables["requestId"])</value>
          </set-header>
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
        'api-key': [
          openAiApiKey
        ]
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

/*
  NEW: /feedback operation to capture binary feedback and log it.
*/

resource openAiFeedbackOperation 'Microsoft.ApiManagement/service/apis/operations@2023-03-01-preview' = {
  name: 'feedback'
  parent: openAiApiProxy
  properties: {
    displayName: 'Feedback'
    method: 'POST'
    urlTemplate: '/feedback'
  }
}

resource openAiFeedbackPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2023-03-01-preview' = {
  name: 'policy'
  parent: openAiFeedbackOperation
  properties: {
    format: 'rawxml'
    value: '''
      <policies>
        <inbound>
          <base />
          <trace source="feedback">
            @{
              // Parse the incoming request body as JSON
              var bodyJson = context.Request.Body.As<JObject>(preserveContent: true);
              // Build a structured object using the full payload
              var logObject = new {
                requestId = (string)bodyJson["requestId"],
                feedback = (string)bodyJson["feedback"],
                comments = (string)bodyJson["comments"],
                metadata = bodyJson["metadata"] // This is already a JSON object containing userId and timestamp, among others
              };
              // Serialize the object to JSON
              return Newtonsoft.Json.JsonConvert.SerializeObject(logObject);
            }
          </trace>
          <return-response>
            <set-status code="200" reason="OK" />
            <set-body>@("{\"message\":\"Feedback received.\"}")</set-body>
          </return-response>
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

output url string = openAiApiProxy.properties.serviceUrl
output gatewayUrl string = apiManagementService.properties.gatewayUrl
