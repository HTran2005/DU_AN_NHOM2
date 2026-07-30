// ============================================================
// MODULE: Metric Alerts cho TripTo Backend (App Insights)
// ============================================================
// TripTo chạy trên XAMPP local, do đó:
// - Không tạo alert CPU/Memory (cần Azure VM)
// - Chỉ tạo alert cho Failed Requests từ App Insights
// - Alert cho PostgreSQL/MySQL performance (sẽ bổ sung sau)
// ============================================================
param actionGroupId string
param appInsightsId string

// --- Alert: Failed Requests > 5% (từ App Insights) ---
resource failedRequestAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-failed-requests'
  location: 'global'
  properties: {
    description: 'Tỷ lệ request lỗi > 5% trong 5 phút (TripTo Backend)'
    severity: 3
    enabled: true
    scopes: [
      appInsightsId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'failed_requests'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'requests/failed'
          metricNamespace: 'Microsoft.Insights/components'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Count'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
  }
}

// --- Alert: Response Time > 5s (từ App Insights) ---
resource responseTimeAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-slow-response'
  location: 'global'
  properties: {
    description: 'Response time > 5 giây (TripTo Backend)'
    severity: 3
    enabled: true
    scopes: [
      appInsightsId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'response_time'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'requests/duration'
          metricNamespace: 'Microsoft.Insights/components'
          operator: 'GreaterThan'
          threshold: 5000 // 5 giây
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
  }
}
