// ============================================================================
// monitoring.bicep - Log Analytics Workspace + Azure Monitor Workspace (Prometheus).
// LAW: PerGB2018 pay-as-you-go with a daily ingestion cap to protect the POC
// budget (first 5 GB/month are included free on PAYG).
// AMW: hosts Managed Prometheus metrics scraped from AKS.
// ============================================================================

param namePrefix string
param location string
param tags object

@description('Daily LAW ingestion cap in GB - keeps POC bills predictable')
param dailyCapGb int = 1

@description('Retention in days (30 keeps cost minimal; 90+ for compliance)')
param retentionInDays int = 30

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-${namePrefix}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyCapGb
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Azure Monitor Workspace = Managed Prometheus storage
resource amw 'microsoft.monitor/accounts@2023-04-03' = {
  name: 'amw-${namePrefix}'
  location: location
  tags: tags
  properties: {}
}

output lawId string = law.id
output lawName string = law.name
output lawCustomerId string = law.properties.customerId
output amwId string = amw.id
output amwName string = amw.name
output amwQueryEndpoint string = amw.properties.metrics.prometheusQueryEndpoint
