// dev.bicepparam - DEV/STAGING environment (AKS staging cluster)
// Shared-resource params are overridden by the deploy script from platform
// outputs; the values below must match platform.bicepparam if run manually.
using '../main.bicep'

param environment = 'dev'
param location = 'eastus'
param namePrefix = 'hexaks'

param platformResourceGroupName = 'rg-hexaks-platform'
param acrNonProdName = 'acrhexaksnp001'
param acrProdName = 'acrhexakspr001'
param keyVaultName = 'kv-hexaks-001'
param logAnalyticsWorkspaceId = '' // filled by scripts/01-deploy-infrastructure.ps1

// dev VNet: 10.42.0.0/24
param vnetAddressPrefix = '10.42.0.0/24'
param aksSubnetPrefix = '10.42.0.0/25'
param peSubnetPrefix = '10.42.0.128/26'

// POC sizing - smallest viable
param systemVmSize = 'Standard_B2s'
param systemMinCount = 1
param systemMaxCount = 2
param spotVmSize = 'Standard_B2s'
param spotMinCount = 0
param spotMaxCount = 3
