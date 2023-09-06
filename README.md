# Observability for your Azure OpenAI instance

## Overview and goals

This project aims to create a simple and easy to deploy solution to add observability to your Azure OpenAI instance. The approach adds an API Management instance as a proxy for your existing Azure OpenAI service, and funnels logs / requests / responses to an Application Insights instance. Additionally, a prebuilt query is saved to a workbook for easy access to logs.

- Keep all your OpenAI generations, metrics, and logs in your own Azure subscription.
- Provision and configure all dependent services programmatically.
- Queries, workbooks, and visualizations are available out of the box.
- An overall "batteries included" type of experience.

![Logs](/images/logs.png)

## Architecture footprint

The main components of the architecture include:

- API Management (Consumption plan)
  - Proxies your Azure OpenAI endpoint.
  - Provides a subscription key so you don't have to share your original API key.
  - Collects logs and metrics.
- Application Insights
  - Captures all logs from the APIM service via Application Insights logger resource.
  - Provides a workbook with prebuilt queries for easy access to logs.
  - `QueryPack` resource with prebuilt `Query` added.
  - Workbook to view table of logs (WIP - need to improve how we visualize longer logs).
- Azure OpenAI (PROVIDED BY USER)
  - When running this Bicep template, you must provide your Azure OpenAI endpoint and API key. **This script will NOT create an Azure OpenAI instance for you.**
- Dashboard
  - This will eventually be used for quick links and instructions.

<!-- ## Provisioned resources -->

![Provisioned resources](/images/resources.png)

<details>

<summary>

**View Bicep explorer**

</summary>

![Bicep explorer](/images/explorer.png)

</details>

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
--parameters openAiEndpoint="https://your-instance-hostname.openai.azure.com/openai/" \
openAiApiKey="your-api-key"
```

- Review the Dashboard to copy your new API endpoint, and replace it in your code. E.g.,

```javascript
// example Javascript code to call your Azure OpenAI instance
const { Configuration } = require("openai");

// add your APIM Subscription Key
const apiKey = process.env.MY_API_KEY;

config = new Configuration({
  basePath: `https://${APIM_ENDPOINT}/openai/deployments/${OPENAI_DEPLOYMENT_NAME}`,

  // be sure to add headers!
  baseOptions: {
    headers: { "api-key": apiKey },
    params: { "api-version": "2023-07-01-preview" },
  },
});
```

# Key considerations

There are several important considerations and potential issues to be aware of:

- APIM Consumption vs Developer Plan: The current setup uses the APIM Consumption plan for cost efficiency. However, upgrading to the Developer plan (~$50/mo) could provide built-in diagnostics with Azure Monitor.
- Log Latency: Requests take 2-4 seconds to show up in Application Insights.
- API Key Visibility: The OpenAI API key will be visible via the APIM instance to anyone who has access.
- : Consider using Grafana or other monitoring tools for a potentially better user experience.

# Todos

Here are some tasks to improve the current setup:

- [x] Create query packs with queries.
- [x] Improve the dashboard by linking to the workbook URL and showing the APIM route for OpenAI API calls.
- [x] Make the APIM route private by adding a subscription API key.
- [ ] App Insights "Live Metrics" can show requests and dependency calls (responses) in real time. Something interesting here? Can we shortcut link to it?
- [ ] Workbook ideas

  - [ ] Use Export Parameters where each row is a request, and clicking expands the request to see details.
  - [ ] Aggregate token usage over time.
  - [ ] Requests count and duration over time.

- [ ] Create a `main.parameters.json` to load in the parameters for the deployment script.
- [ ] Add a UI component, maybe as a managed application?
- [ ] Experiment with bicep functions for creating shortcut links to add to dashboard (e.g., tenant and sub ids).
- [ ] Abstract KQL and workbook code for easier reading and updating. Abstracted KQL for the QueryPack / Query objects, but not for the workbook since it requires JSON.

# Known issues

- The `Microsoft.Insights/components/favorites@2015-05-01` resource does not work as expected. This issue is currently being discussed with Azure support. Hopefully we'll be able to favorite the query we create, as that'll make it easier to find our logs view.

# Future thoughts

- APIM has a caching mechanism, can we do something interesting here? (caching GPT responses)
- Grafana for visualizations - can we completely automate the provisioning, configuration, and integration of Grafana?

This project takes inspiration from [this solution](https://github.com/Azure-Samples/openai-python-enterprise-logging), but aims to be significantly lighterweight and 100% automated for deployment.
