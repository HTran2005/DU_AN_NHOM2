// ============================================================
// MODULE: Application Insights (liên kết với Log Analytics)
// ============================================================
param appInsightsName string
param location string
param workspaceId string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceId
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    RetentionInDays: 90
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaAIExtension'
  }
}

output instrumentationKey string = appInsights.properties.InstrumentationKey
output connectionString string = appInsights.properties.ConnectionString
output appId string = appInsights.properties.AppId
output appInsightsId string = appInsights.id
