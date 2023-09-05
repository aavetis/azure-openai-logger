param apiGateway string
param appInsightsId string
param appInsightsName string

var gatewayContent = format(
  '''
# OpenAI API Gateway
Replace your OpenAI API endpoint with the following values.

**Endpoint URL**: `{0}`

**Endpoint Key**: Navigate to your API Management instance -> Subscription keys

```

### Test title
''', apiGateway)

resource dashboard 'Microsoft.Portal/dashboards@2020-09-01-preview' = {

  name: 'OpenAIDashboard'
  location: 'global'
  properties: {
    lenses: [
      {
        order: 0
        parts: [
          {
            position: {
              x: 0
              y: 0
              rowSpan: 3
              colSpan: 3
            }
            metadata: {
              inputs: []
              type: 'Extension/HubsExtension/PartType/MarkdownPart'
              settings: {
                content: {
                  settings: {
                    content: '## OpenAI WorkBook Overview\r\nWelcome to your OpenAI WorkBook dashboard. Here you can find insights and analytics related to your OpenAI interactions.'
                  }
                }
              }
            }
          }
          {
            position: {
              x: 3
              y: 0
              rowSpan: 4
              colSpan: 8
            }
            metadata: {
              inputs: []
              type: 'Extension/HubsExtension/PartType/MarkdownPart'
              settings: {
                content: {
                  settings: {
                    content: gatewayContent
                  }
                }
              }
            }
          }
          {
            position: {
              x: 0
              y: 4
              colSpan: 6
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: appInsightsId
                          }
                          name: 'requests/duration'
                          aggregationType: 4 // avg
                          namespace: 'Microsoft.Insights/components'
                          metricVisualization: {
                            displayName: 'Server response time'
                            resourceDisplayName: appInsightsName
                          }
                        }
                      ]
                      title: 'Response time'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
            }
          }
        ]
      }
    ]
  }
}
