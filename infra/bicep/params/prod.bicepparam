// prod.bicepparam - PRODUCTION environment (still POC-sized; scale up for real)
using '../main.bicep'

param environment = 'prod'
param location = 'eastus'
param namePrefix = 'hexaks'

param platformResourceGroupName = 'rg-hexaks-platform'
param acrNonProdName = 'acrhexaksnp001'
param acrProdName = 'acrhexakspr001'
param keyVaultName = 'kv-hexaks-001'
param logAnalyticsWorkspaceId = '' // filled by scripts/01-deploy-infrastructure.ps1

// prod VNet: 10.43.0.0/24 (different range so dev/prod never overlap)
param vnetAddressPrefix = '10.43.0.0/24'
param aksSubnetPrefix = '10.43.0.0/25'
param peSubnetPrefix = '10.43.0.128/26'

// Still POC-sized. For real prod: Standard tier, 3 system nodes, D4s_v5+, zones.
param systemVmSize = 'Standard_B2s'
param systemMinCount = 1
param systemMaxCount = 2
param spotVmSize = 'Standard_B2s'
param spotMinCount = 0
param spotMaxCount = 3
