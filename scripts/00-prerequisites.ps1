# ============================================================================
# 00-prerequisites.ps1 - local tooling + Azure login + provider registration.
# Run on your admin workstation (Windows). Idempotent - safe to re-run.
# ============================================================================
#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
$SUBSCRIPTION_ID = '995377ec-18d5-43bb-98db-74ab68a2ef8f'   # adminebooks

Write-Host '=== 1/4 Checking / installing local tools ===' -ForegroundColor Cyan
$tools = @(
  @{ Cmd = 'az';       Winget = 'Microsoft.AzureCLI' },
  @{ Cmd = 'kubectl';  Winget = 'Kubernetes.kubectl' },
  @{ Cmd = 'helm';     Winget = 'Helm.Helm' },
  @{ Cmd = 'git';      Winget = 'Git.Git' }
)
foreach ($t in $tools) {
  if (Get-Command $t.Cmd -ErrorAction SilentlyContinue) {
    Write-Host "  [ok] $($t.Cmd) already installed"
  } else {
    Write-Host "  [..] installing $($t.Winget)"
    winget install --id $t.Winget -e --accept-source-agreements --accept-package-agreements
  }
}
# Bicep ships with Azure CLI - just upgrade it
az bicep upgrade

Write-Host '=== 2/4 Azure CLI extensions ===' -ForegroundColor Cyan
az extension add --name azure-devops --only-show-errors 2>$null
az extension add --name aks-preview --only-show-errors 2>$null

Write-Host '=== 3/4 Login + subscription ===' -ForegroundColor Cyan
az login --only-show-errors | Out-Null
az account set --subscription $SUBSCRIPTION_ID
az account show --query '{name:name, id:id, tenantId:tenantId}' -o table

Write-Host '=== 4/4 Register resource providers ===' -ForegroundColor Cyan
$providers = @(
  'Microsoft.ContainerService','Microsoft.ContainerRegistry','Microsoft.KeyVault',
  'Microsoft.OperationalInsights','Microsoft.Monitor','microsoft.monitor',
  'Microsoft.Dashboard','Microsoft.Network','Microsoft.Security','Microsoft.PolicyInsights'
)
foreach ($p in $providers) {
  az provider register --namespace $p --only-show-errors | Out-Null
  Write-Host "  registered $p"
}

Write-Host ''
Write-Host 'Done. Next: scripts/01-deploy-infrastructure.ps1' -ForegroundColor Green
