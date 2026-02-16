param location string = resourceGroup().location
param storageName string = 'store${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}
resource uploadContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'upload'
}
resource thumbnailContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'thumbnail'
}

// App Service Plan(Servern)
resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'serverless-image-processor-plan'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}
// 2. Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'serverless-image-processor-ai'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}
// 3. Function App
resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: 'func-${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        // Denna rad kopplar ihop koden med ditt Storage Account automatiskt!
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME' // Understreck här, inte bindestreck
          value: 'dotnet-isolated'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
      ]
    }
  }
}
