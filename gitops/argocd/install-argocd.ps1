# install-argocd.ps1 - GitOps alternative to push-based CD (see doc 04)
# Installs ArgoCD into the cluster. Run after 02-post-deployment-config.ps1.
# Usage: ./install-argocd.ps1 -ResourceGroup rg-hexaks-dev -AksName aks-hexaks-dev

param(
  [Parameter(Mandatory)] [string] $ResourceGroup,
  [Parameter(Mandatory)] [string] $AksName
)

az aks get-credentials --resource-group $ResourceGroup --name $AksName --overwrite-existing

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Write-Host "Waiting for ArgoCD server..." -ForegroundColor Cyan
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

$pw = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
Write-Host "ArgoCD installed."
Write-Host "  UI:      kubectl port-forward svc/argocd-server -n argocd 8080:443  ->  https://localhost:8080"
Write-Host "  Login:   admin / $([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($pw)))"
Write-Host "Next: kubectl apply -f gitops/argocd/application-staging.yaml"
