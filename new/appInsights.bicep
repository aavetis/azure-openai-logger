param rgLocation string

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: 'OpenAIAppInsights'
  location: rgLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

output instrumentationKey string = appInsights.properties.InstrumentationKey
output id string = appInsights.id
