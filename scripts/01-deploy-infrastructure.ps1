# ============================================================================
# 01-deploy-infrastructure.ps1 - provisions the whole platform:
#   rg-hexaks-platform : 2x ACR, Key Vault, LAW, AMW (Prometheus), Grafana
#   rg-hexaks-dev      : VNet + AKS staging cluster
#   rg-hexaks-prod     : VNet + AKS prod cluster
# Then enables Defender for Containers at subscription level.
#
# Prereq: run 00-prerequisites.ps1 first. ~15-20 min runtime (AKS is the long pole).
# ============================================================================

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')   # repo root

$SUBSCRIPTION_ID = '995377ec-18d5-43bb-98db-74ab68a2ef8f'
$LOCATION  = 'eastus'
$PREFIX    = 'hexaks'
$RG_PLAT   = "rg-$PREFIX-platform"
$RG_DEV    = "rg-$PREFIX-dev"
$RG_PROD   = "rg-$PREFIX-prod"

az account set --subscription $SUBSCRIPTION_ID
$me = az ad signed-in-user show --query id -o tsv   # for Grafana Admin / KV Officer

# ---------------------------------------------------------------- RG creation
Write-Host '=== Creating resource groups ===' -ForegroundColor Cyan
foreach ($rg in @($RG_PLAT, $RG_DEV, $RG_PROD)) {
  az group create --name $rg --location $LOCATION `
    --tags project=aks-devsecops-platform costProfile=poc-optimized | Out-Null
  Write-Host "  $rg"
}

# ------------------------------------------------------- 1) Shared platform
Write-Host '=== Deploying shared platform (ACR x2, KV, LAW, AMW, Grafana) ===' -ForegroundColor Cyan
$plat = az deployment group create `
  --resource-group $RG_PLAT `
  --template-file infra/bicep/platform.bicep `
  --parameters infra/bicep/params/platform.bicepparam `
  --parameters adminObjectId=$me `
  --query properties.outputs -o json | ConvertFrom-Json

$lawId         = $plat.lawId.value
$acrNonProd    = ($plat.acrNonProdLoginServer.value -split '\.')[0]
$acrProd       = ($plat.acrProdLoginServer.value -split '\.')[0]
$kvName        = ([uri]$plat.keyVaultUri.value).Host.Split('.')[0]
Write-Host "  LAW=$lawId`n  ACR-NP=$acrNonProd  ACR-P=$acrProd  KV=$kvName"

# Seed a couple of pipeline secrets so CI has something to read (optional)
az keyvault secret set --vault-name $kvName --name 'sample-secret' --value 'poc-value' --only-show-errors | Out-Null

# ------------------------------------------------------------ 2) AKS per env
foreach ($env in @('dev','prod')) {
  $rg = "rg-$PREFIX-$env"
  Write-Host "=== Deploying AKS ($env) into $rg ===" -ForegroundColor Cyan
  az deployment group create `
    --resource-group $rg `
    --template-file infra/bicep/main.bicep `
    --parameters "infra/bicep/params/$env.bicepparam" `
    --parameters platformResourceGroupName=$RG_PLAT `
                 acrNonProdName=$acrNonProd acrProdName=$acrProd `
                 keyVaultName=$kvName logAnalyticsWorkspaceId=$lawId `
    --query properties.outputs -o json | ConvertFrom-Json
}

# ------------------------------------------------- 3) Defender for Cloud POC
# Enable the minimum paid plans that this architecture uses.
# Defender for Containers ~= $7/node/month equivalent - comment out to skip.
Write-Host '=== Enabling Defender for Cloud plans ===' -ForegroundColor Cyan
az security pricing create --name Containers --tier standard --only-show-errors
az security pricing create --name KubernetesService --tier standard --only-show-errors 2>$null
# Foundational CSPM is FREE and on by default - no action needed.

Write-Host ''
Write-Host 'Infrastructure done. Next: scripts/02-post-deployment-config.ps1' -ForegroundColor Green
