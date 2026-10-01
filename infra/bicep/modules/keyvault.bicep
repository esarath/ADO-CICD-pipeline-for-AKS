// ============================================================================
// keyvault.bicep - Azure Key Vault (Standard tier, RBAC authorization mode).
// RBAC mode is required so AKS Key Vault CSI driver and pipeline identities
// can be granted "Key Vault Secrets User" without access policies.
// ============================================================================

@description('Globally unique vault name (3-24 chars, alphanumeric + dashes)')
param name string

param location string
param tags object

@description('Allow purge so the POC vault can be fully deleted/recreated. Set true for real workloads.')
param enablePurgeProtection bool = false

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: enablePurgeProtection ? true : null
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

output id string = kv.id
output name string = kv.name
output vaultUri string = kv.properties.vaultUri
