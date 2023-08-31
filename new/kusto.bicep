resource kustoCluster 'Microsoft.Kusto/clusters@2020-09-18' = {
  name: 'yourKustoCluster'
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'Standard_D13_v2'
      capacity: 2
    }
  }
}

// Define database and table schema
