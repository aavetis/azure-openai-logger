#

# Issues / concerns

- Logs take 2-4 seconds to show up, this is a limitation of App Insights. Not sure if any alternative paths available to capture APIM requests.
- Why might we need Log Analytics Workspaces here? how do we streamline the UX for the user? Currently, the workbook is created but users have to go find it, then click "open workbook" to start seeing logs.
- OpenAI API key will be visible via APIM instance to anyone who has access. Even if we add Key Vault to the solution, someone will still have to provide the key at some point.
- Consider just using Grafana instead of forcing workbooks / queries to live in a nice UX

# Todos

- Abstract KQL and workbook stuff to make it easier to read / update. Right now it's all jammed in `serializedData`
-
