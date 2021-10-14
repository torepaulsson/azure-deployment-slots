var resourceSuffix = '${uniqueString(subscription().displayName, resourceGroup().name)}'
var functionAppName = 'function-${resourceSuffix}'
var storageAccountName = 'storage${resourceSuffix}'
var servicePlanName = 'serviceplan-${resourceSuffix}'
var insightsName = 'insights-${resourceSuffix}'
var logAnalyticsName = 'la-${resourceSuffix}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource servicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: servicePlanName
  location: resourceGroup().location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsName
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 120
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: insightsName
  location: resourceGroup().location
  kind: 'web'
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/sites/${functionAppName}': 'Resource'
  }
  properties: {
    Application_Type: 'web'
		WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource functionApp 'Microsoft.Web/sites@2021-01-15' = {
  name: functionAppName
  location: resourceGroup().location
  kind: 'functionapp'
	identity:{
		type: 'SystemAssigned'
	}
	properties:{
    enabled: true
		serverFarmId: servicePlan.id
		httpsOnly:true
		siteConfig:{
			minTlsVersion: '1.2'
		}
	}
  dependsOn: [
    storageAccount
    appInsights
		servicePlan
  ]
}

resource functionAppStagingSlot 'Microsoft.Web/sites/slots@2021-01-15' = {
	name: '${functionApp.name}/staging'
	location: resourceGroup().location
  kind: 'functionapp'
	identity:{
		type: 'SystemAssigned'
	}
	properties:{
    enabled:true
		httpsOnly: true
		serverFarmId: servicePlan.id
	}
	dependsOn:[
		functionApp
	]
}

resource functionAppConfig 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: functionApp
  name: 'appsettings'
  properties: {
		AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountName, '2015-05-01-preview').key1}'
    WEBSITE_RUN_FROM_PACKAGE: '1'
		FUNCTIONS_EXTENSION_VERSION: '~3'
		FUNCTIONS_WORKER_RUNTIME: 'dotnet'
		APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
    WEBSITE_ADD_SITENAME_BINDINGS_IN_APPHOST_CONFIG: '1'
  }
  dependsOn: [
		appInsights
  ]
}

resource functionAppStagingConfig 'Microsoft.Web/sites/slots/config@2021-01-15' = {
  parent: functionAppStagingSlot
  name: 'appsettings'
  properties: {
		AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountName, '2015-05-01-preview').key1}'
    WEBSITE_RUN_FROM_PACKAGE: '1'
		FUNCTIONS_EXTENSION_VERSION: '~3'
		FUNCTIONS_WORKER_RUNTIME: 'dotnet'
		APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
    WEBSITE_ADD_SITENAME_BINDINGS_IN_APPHOST_CONFIG: '1'
  }
  dependsOn: [
		appInsights
  ]
}
