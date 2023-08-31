param oaiEndpoint string

resource azAPIM 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
// add RG ID to make unique name
  name: 'LogLLM-APIM-' + resourceGroup().id
  location: 'eastus'
  sku: {
    name: 'Consumption'
    capacity: 1
  }
  properties: {
    publisherEmail: '
