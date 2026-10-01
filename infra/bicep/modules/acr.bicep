// ============================================================================
// acr.bicep - Azure Container Registry (Basic SKU for POC).
// Deployed twice: acrNonProd (dev/qa/uat/staging images) and acrProd (prod images).
// Basic has no geo-replication / private endpoints / retention policies
// (those require Premium). Admin user stays disabled - auth is via Entra ID.
// ============================================================================

@description('Globally unique registry name, lowercase alphanumeric only')
param name string

param location string
param tags object

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
    // anonymousPullEnabled defaults to false - pulls require AcrPull
  }
}

output id string = acr.id
output name string = acr.name
output loginServer string = acr.properties.loginServer
