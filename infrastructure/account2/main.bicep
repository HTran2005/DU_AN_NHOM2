// ============================================================
// Azure Monitoring & Governance - TripTo Project
// Account 2: Monitoring & Governance (Máy 4)
// ============================================================
// Cách deploy:
//   az deployment group create --resource-group rg-tripto-monitoring --template-file main.bicep --parameters parameters.json
// ============================================================

param location string = 'southeastasia'
param workspaceName string = 'law-tripto'
param appInsightsName string = 'appi-tripto'
param vaultName string = 'rsv-tripto'
param actionGroupName string = 'ag-tripto-critical'
param adminEmail string = 'admin@tripto.com'
param retentionInDays int = 30

// ==================== MODULES ====================

// --- Log Analytics Workspace ---
module logAnalytics './modules/log-analytics.bicep' = {
  name: 'deploy-log-analytics'
  params: {
    workspaceName: workspaceName
    location: location
    retentionInDays: retentionInDays
  }
}

// --- Application Insights ---
module appInsights './modules/app-insights.bicep' = {
  name: 'deploy-app-insights'
  params: {
    appInsightsName: appInsightsName
    location: location
    workspaceId: logAnalytics.outputs.workspaceId
  }
}

// --- Action Group ---
module actionGroup './modules/action-group.bicep' = {
  name: 'deploy-action-group'
  params: {
    actionGroupName: actionGroupName
    location: 'global'
    adminEmail: adminEmail
  }
}

// --- Metric Alerts ---
module alerts './modules/alerts.bicep' = {
  name: 'deploy-alerts'
  params: {
    actionGroupId: actionGroup.outputs.actionGroupId
    appInsightsId: appInsights.outputs.appInsightsId
  }
}

// --- Recovery Services Vault ---
module recoveryVault './modules/recovery-vault.bicep' = {
  name: 'deploy-recovery-vault'
  params: {
    vaultName: vaultName
    location: location
  }
}

// ==================== OUTPUTS ====================

output workspaceId string = logAnalytics.outputs.workspaceId
output workspaceCustomerId string = logAnalytics.outputs.workspaceCustomerId
output appInsightsInstrumentationKey string = appInsights.outputs.instrumentationKey
output appInsightsConnectionString string = appInsights.outputs.connectionString
output actionGroupId string = actionGroup.outputs.actionGroupId
output vaultId string = recoveryVault.outputs.vaultId
output vaultName string = recoveryVault.outputs.vaultName
