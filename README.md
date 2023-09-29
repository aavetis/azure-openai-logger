> _Need help setting this up for your organization? Let's chat._
>
> <a href="https://cal.com/teammait"><img src="https://cal.com/book-with-cal-dark.svg" alt="Book an intro meeting."></a>

# Observability for your Azure OpenAI instance

## Overview and goals

> **❗️ This project is in "beta"! Please re-review all deployment parameters, code, and queries before using in a production scenario.**

This project aims to create a simple and easy to deploy solution to add observability to your Azure OpenAI instance. The approach adds an API Management instance as a proxy for your existing Azure OpenAI service, and funnels logs / requests / responses to an Application Insights instance. Additionally, a prebuilt query is saved to a workbook for easy access to logs.

- Keep all your OpenAI generations, metrics, and logs in your own Azure subscription.
- Provision and configure all dependent services programmatically.
- Queries, workbooks, and visualizations are available out of the box.
- An overall "batteries included" type of experience.

![Demo](/images/demo.gif)

# Usage instructions

- **Pre-requisite: You must have an Azure OpenAI service provisioned already.**
- (Recommended) Create a new resource group to house these resources

```bash
az group create --name loggerTest --location eastus
```

- In the root of this repo, run the deployment script

```bash
az deployment group create --resource-group loggerTest \
--template-file ./main.bicep \
--parameters openAiEndpoint="https://your-instance-hostname.openai.azure.com" \
openAiApiKey="your-openai-api-key"
```

- Navigate to the API Management instance deployed to your resource group.
- Copy your new endpoint from APIM and Subscription Key, and replace it in your code. (You can find your Subscription key in Azure API Manager by clicking "Subscriptions", then on the elipsis dots ("...") to the right of OpenAI Subscription, and finally on "Show/hide keys")

```javascript
// example Javascript code to call your Azure OpenAI instance
const { Configuration } = require("openai");

// add your APIM Subscription Key
const apiKey = process.env.MY_APIM_API_KEY;

config = new Configuration({
  // replace endpoint with your new API Management instance endpoint
  basePath: `https://${APIM_ENDPOINT}/openai/deployments/${OPENAI_DEPLOYMENT_NAME}`,

  // be sure to add headers!
  baseOptions: {
    headers: { "api-key": apiKey },
    params: { "api-version": "2023-07-01-preview" },
  },
});
```

## Debugging issues

- Test your new endpoint by using the API Management tester (APIM -> APIs -> OpenAI Proxy API -> Test)
  - For `deployment-id` use a model deployment name you have deployed in Azure Open AI (eg. "gpt-35-turbo")
  - For `api-version` use the API version you are using (eg. "2023-07-01-preview")
  - If you get a 404, it's likely because the original endpoint you provided was structured incorrectly. Go to Backends -> backend -> Properties - you should see your original endpoint + `/openai`

## Architecture footprint

The main components of the architecture include:

- API Management (Consumption plan)\*
  - Proxies your Azure OpenAI endpoint.
  - Provides a subscription key so you don't have to share your original API key.
  - Collects logs and metrics.
  - \* Consider upgrading this to Basic or Standard
- Application Insights
  - Captures all logs from the APIM service via Application Insights logger resource.
  - Provides a workbook with prebuilt queries for easy access to logs.
  - `QueryPack` resource with prebuilt `Query` added.
  - Workbook to view table of logs (WIP - need to improve how we visualize longer logs).
- Workbook
  - Requests - view your requests including user & assistant responses, and system messages.
  - Metrics - view stats about your requests, including average response time, tokens, and more.
- Azure OpenAI (PROVIDED BY USER)
  - When running this Bicep template, you must provide your Azure OpenAI endpoint and API key. **This script will NOT create an Azure OpenAI instance for you.**
- Dashboard
  - This will eventually be used for quick links and instructions.

# Key considerations

There are several important considerations and potential issues to be aware of:

- APIM Consumption vs Developer Plan: The current setup uses the APIM Consumption plan for cost efficiency. However, upgrading to the Developer plan (~$50/mo) could provide built-in diagnostics with Azure Monitor.
- Log Latency: Requests take 2-4 seconds to show up in Application Insights.
- API Key Visibility: The OpenAI API key will be visible via the APIM instance to anyone who has access.
- : Consider using Grafana or other monitoring tools for a potentially better user experience.
