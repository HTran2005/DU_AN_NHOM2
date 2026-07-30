// ============================================================
// MODULE: Action Group (Email + SMS khi alert trigger)
// ============================================================
param actionGroupName string
param location string
param adminEmail string

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: location
  properties: {
    groupShortName: 'TripToAlerts'
    enabled: true
    emailReceivers: [
      {
        name: 'AdminEmail'
        emailAddress: adminEmail
        useCommonAlertSchema: true
      }
    ]
    smsReceivers: []
    webhookReceivers: []
  }
}

output actionGroupId string = actionGroup.id
output actionGroupName string = actionGroup.name
