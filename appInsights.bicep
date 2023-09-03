param rgLocation string
// get GUID for name
param wbName string = guid('OpenAIWorkBook')

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: 'OpenAIAppInsights'
  location: rgLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

resource workbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: wbName
  location: rgLocation
  kind: 'shared'
  properties: {
    displayName: 'OpenAI WorkBook'
    serializedData: '{"version":"Notebook/1.0","items":[{"type":1,"content":{"json":"## OpenAI Requests\\n---\\n\\nView your OpenAI completions below!\\n\\nWe\'ve included a basic analytics query to get you started. Use the `Edit` button below each section to configure it or add more sections."},"name":"text - 2"},{"type":3,"content":{"version":"KqlItem/1.0","query":"requests\\n| where operation_Name == \\"OpenAIProxy;rev=1 - Completions_Create\\" or operation_Name == \\"OpenAIProxy;rev=1 - ChatCompletions_Create\\"\\n| extend Prompt = parse_json(tostring(parse_json(tostring(parse_json(tostring(customDimensions.[\\"Request-Body\\"])).messages[-1].content))))\\n| extend Generation = parse_json(tostring(parse_json(tostring(parse_json(tostring(customDimensions.[\\"Response-Body\\"])).choices))[0].message)).content\\n| extend promptTokens = parse_json(tostring(parse_json(tostring(customDimensions.[\\"Response-Body\\"])).usage)).prompt_tokens\\n| extend completionTokens = parse_json(tostring(parse_json(tostring(customDimensions.[\\"Response-Body\\"])).usage)).completion_tokens\\n| extend totalTokens = parse_json(tostring(parse_json(tostring(customDimensions.[\\"Response-Body\\"])).usage)).total_tokens\\n| project timestamp, Prompt, Generation, promptTokens, completionTokens, totalTokens, round(duration,2), operation_Name","size":1,"timeContext":{"durationMs":86400000},"queryType":0,"resourceType":"microsoft.insights/components"},"name":"query - 2"}],"isLocked":false}'
    sourceId: appInsights.id
    category: 'OpenAI'
  }
}

output instrumentationKey string = appInsights.properties.InstrumentationKey
output debugInfo string = 'App Insights Instrumentation Key: ${appInsights.properties.InstrumentationKey}'

output id string = appInsights.id
