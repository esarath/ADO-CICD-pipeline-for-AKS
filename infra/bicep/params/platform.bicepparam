// platform.bicepparam - shared platform services (deploy ONCE into rg-hexaks-platform)
// IMPORTANT: acr* and keyVault names are GLOBALLY unique - change the suffixes.
using '../platform.bicep'

param location = 'eastus'
param namePrefix = 'hexaks'

param acrNonProdName = 'acrhexaksnp001'   // change suffix if name is taken
param acrProdName = 'acrhexakspr001'      // change suffix if name is taken
param keyVaultName = 'kv-hexaks-001'      // 3-24 chars, globally unique
param grafanaName = 'grafana-hexaks-001'  // globally unique

// Run `az ad signed-in-user show --query id -o tsv` and paste your object ID
// to get Grafana Admin + Key Vault access automatically.
param adminObjectId = ''

// Cost guardrails
param lawDailyCapGb = 1
param lawRetentionDays = 30
