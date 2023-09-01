param rgLocation string
// get GUID for name
param wbName string = guid('OpenAIWorkBook')

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: 'OpenAIAppInsights'
  location: rgLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource workbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: wbName
  location: rgLocation
  kind: 'shared'
  properties: {
    displayName: 'OpenAI WorkBook'
    serializedData: '{"version":"Notebook/1.0","items":[{"type":1,"content":{"json":"## New workbook\\n---\\n\\nWelcome to your new workbook.  This area will display text formatted as markdown.\\n\\n\\nWe\'ve included a basic analytics query to get you started. Use the `Edit` button below each section to configure it or add more sections."},"name":"text - 2"},{"type":3,"content":{"version":"KqlItem/1.0","query":"requests\\n| where operation_Name == \\"OpenAIProxy;rev=1 - Completions_Create\\" or operation_Name == \\"OpenAIProxy;rev=1 - ChatCompletions_Create\\"\\n| extend reqMessage = parse_json(tostring(parse_json(tostring(parse_json(tostring(customDimensions.[\\"Request-Body\\"])).messages[-1].content))))\\n| extend lastMessage = parse_json(tostring(parse_json(tostring(parse_json(tostring(customDimensions.[\\"Response-Body\\"])).choices))[0].message)).content\\n| extend promptTokens = parse_json(tostring(parse_json(tostring(customDimensions.[\\"Response-Body\\"])).usage)).prompt_tokens\\n| extend completionTokens = parse_json(tostring(parse_json(tostring(customDimensions.[\\"Response-Body\\"])).usage)).completion_tokens\\n| extend totalTokens = parse_json(tostring(parse_json(tostring(customDimensions.[\\"Response-Body\\"])).usage)).total_tokens\\n| project timestamp, operation_Name, reqMessage, lastMessage, promptTokens, completionTokens, totalTokens, duration","size":1,"timeContext":{"durationMs":86400000},"queryType":0,"resourceType":"microsoft.insights/components"},"name":"query - 2"}],"isLocked":false,"fallbackResourceIds":["/subscriptions/50fbd004-95f5-4ece-baf9-d73565614a6a/resourceGroups/bicepTest6/providers/Microsoft.Insights/components/OpenAIAppInsights"]}'
    sourceId: appInsights.id
    category: 'OpenAI'
  }
}

output instrumentationKey string = appInsights.properties.InstrumentationKey
output debugInfo string = 'App Insights Instrumentation Key: ${appInsights.properties.InstrumentationKey}'

output id string = appInsights.id
