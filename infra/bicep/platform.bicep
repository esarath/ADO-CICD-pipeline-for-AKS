// ============================================================================
// platform.bicep - SHARED platform services (deployed ONCE).
// Target resource group: rg-<prefix>-platform
//
//   ACR (non-prod)   - receives images from CI for dev/qa/uat/staging
//   ACR (prod)       - receives promoted images only (immutable tags)
//   Key Vault        - pipeline + workload secrets (RBAC mode)
//   Log Analytics    - Container Insights, control-plane logs, audits
//   AMW (Prometheus) - Managed Prometheus metrics store
//   Managed Grafana  - dashboards over AMW + LAW
// ============================================================================

targetScope = 'resourceGroup'

param location string = resourceGroup().location
param namePrefix string = 'hexaks'

@description('Globally unique, lowercase alphanumeric')
param acrNonProdName string
param acrProdName string
param keyVaultName string
param grafanaName string = 'grafana-${namePrefix}'

@description('Object ID of the Entra user/group to grant Grafana Admin + KV Secrets Officer')
param adminObjectId string = ''

param lawDailyCapGb int = 1
param lawRetentionDays int = 30

param tags object = {
  project: 'aks-devsecops-platform'
  scope: 'shared-platform'
  costProfile: 'poc-optimized'
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    namePrefix: namePrefix
    location: location
    tags: tags
    dailyCapGb: lawDailyCapGb
    retentionInDays: lawRetentionDays
  }
}

module acrNonProd 'modules/acr.bicep' = {
  name: 'acr-nonprod'
  params: {
    name: acrNonProdName
    location: location
    tags: union(tags, { environment: 'nonprod' })
    sku: 'Basic'
  }
}

module acrProd 'modules/acr.bicep' = {
  name: 'acr-prod'
  params: {
    name: acrProdName
    location: location
    tags: union(tags, { environment: 'prod' })
    sku: 'Basic'
  }
}

module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    name: keyVaultName
    location: location
    tags: tags
    enablePurgeProtection: false // POC only - set true for real workloads
  }
}

module grafana 'modules/grafana.bicep' = {
  name: 'grafana'
  params: {
    name: grafanaName
    location: location
    tags: tags
    azureMonitorWorkspaceId: monitoring.outputs.amwId
    adminObjectId: adminObjectId
  }
}

output lawId string = monitoring.outputs.lawId
output lawName string = monitoring.outputs.lawName
output amwId string = monitoring.outputs.amwId
output amwQueryEndpoint string = monitoring.outputs.amwQueryEndpoint
output acrNonProdLoginServer string = acrNonProd.outputs.loginServer
output acrProdLoginServer string = acrProd.outputs.loginServer
output keyVaultUri string = keyvault.outputs.vaultUri
output grafanaEndpoint string = grafana.outputs.endpoint
