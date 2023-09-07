param rgLocation string
param wbName string = guid(resourceGroup().id, 'OpenAIWorkBook')
param qpName string = guid('Query Pack')
param wbSerializedData object

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: 'OpenAIAppInsights'
  location: rgLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

var kqlQuery = '''
requests
| where operation_Name == "OpenAIProxy;rev=1 - Completions_Create" or operation_Name == "OpenAIProxy;rev=1 - ChatCompletions_Create"
| extend Prompt = parse_json(tostring(parse_json(tostring(parse_json(tostring(customDimensions.["Request-Body"])).messages[-1].content))))
| extend Generation = parse_json(tostring(parse_json(tostring(parse_json(tostring(customDimensions.["Response-Body"])).choices))[0].message)).content
| extend promptTokens = parse_json(tostring(parse_json(tostring(customDimensions.["Response-Body"])).usage)).prompt_tokens
| extend completionTokens = parse_json(tostring(parse_json(tostring(customDimensions.["Response-Body"])).usage)).completion_tokens
| extend totalTokens = parse_json(tostring(parse_json(tostring(customDimensions.["Response-Body"])).usage)).total_tokens
| project timestamp, Prompt, Generation, promptTokens, completionTokens, totalTokens, round(duration,2), operation_Name
'''

resource queryPack 'Microsoft.OperationalInsights/queryPacks@2019-09-01' = {
  name: 'OpenAI Query Pack'
  location: rgLocation
  properties: {}

}

resource query 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: queryPack
  name: qpName
  properties: {
    displayName: 'OpenAI Logs'
    description: 'Requests and responses from OpenAI calls'
    body: kqlQuery
    related: {
      categories: [
        'applications'
      ]
      resourceTypes: [
        'microsoft.insights/components'
      ]
    }
    tags: {
      labels: [
        'playGround'
      ]
    }
  }
}

// DOES NOT WORK. revisit this, the favorite resource seems to be bugged / outdated
// resource favoriteQuery 'Microsoft.Insights/components/favorites@2015-05-01' = {
//   name: 'favorite query'
//   parent: appInsights
//   Category: ''
//   Config: ''
//   FavoriteType: 'user'
//   IsGeneratedFromTemplate: false
//   SourceType: 'Search'
//   Version: '1.0'
// }

// note: undecided on whether we need to always filter by operation name, or just assume every request proxied through APIM is for OpenAI

resource workbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: wbName
  location: rgLocation
  kind: 'shared'
  properties: {
    displayName: 'OpenAI WorkBook'
    serializedData: string(wbSerializedData)
    sourceId: appInsights.id
    category: 'OpenAI'
  }
}

output instrumentationKey string = appInsights.properties.InstrumentationKey
output debugInfo string = 'App Insights Instrumentation Key: ${appInsights.properties.InstrumentationKey}'
output id string = appInsights.id
