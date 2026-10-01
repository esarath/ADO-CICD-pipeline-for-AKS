# ============================================================================
# 02-post-deployment-config.ps1 - Day-1 cluster configuration:
#   kubeconfig, Managed Prometheus wiring, namespaces, baselines, sanity checks.
# ============================================================================

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$PREFIX  = 'hexaks'
$RG_PLAT = "rg-$PREFIX-platform"

# ---------------------------------------------------- kubeconfig + namespaces
foreach ($env in @('dev','prod')) {
  $rg  = "rg-$PREFIX-$env"
  $aks = "aks-$PREFIX-$env"
  Write-Host "=== Configuring $aks ===" -ForegroundColor Cyan

  az aks get-credentials --resource-group $rg --name $aks --overwrite-existing

  # Namespaces + Pod Security labels + baseline network policies
  kubectl apply -f k8s/namespaces.yaml
  kubectl apply -f k8s/network-policies.yaml
}

# --------------------------------- Managed Prometheus (Azure Monitor Metrics)
# Attaches the shared AMW; AKS creates its DCR/DCRA automatically.
$amwId = az monitor account show --name "amw-$PREFIX" --resource-group $RG_PLAT --query id -o tsv
foreach ($env in @('dev','prod')) {
  $rg  = "rg-$PREFIX-$env"
  $aks = "aks-$PREFIX-$env"
  Write-Host "=== Enabling Managed Prometheus on $aks ===" -ForegroundColor Cyan
  az aks update --resource-group $rg --name $aks `
    --enable-azure-monitor-metrics `
    --azure-monitor-workspace-resource-id $amwId --only-show-errors
}

# ------------------------------------------------- Optional: App Routing addon
# Managed nginx ingress - enable if you want the Helm ingress to work:
# az aks approuting enable -g rg-$PREFIX-dev -n aks-$PREFIX-dev

# ------------------------------------------------------------------- Sanity
az aks get-credentials --resource-group "rg-$PREFIX-dev" --name "aks-$PREFIX-dev" --overwrite-existing
Write-Host '=== Sanity checks (dev cluster) ===' -ForegroundColor Cyan
kubectl get nodes -o wide
kubectl get pods -A | Select-String -NotMatch 'Running|Completed'   # should be empty

Write-Host ''
Write-Host 'Post-config done. Next: scripts/03-azure-devops-setup.md' -ForegroundColor Green
