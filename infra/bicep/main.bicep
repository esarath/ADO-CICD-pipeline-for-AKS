// ============================================================================
// main.bicep - PER-ENVIRONMENT deployment (run once for dev, once for prod).
// Target resource group: rg-<prefix>-<environment>
//
//   VNet (Azure CNI Overlay subnet) + AKS cluster
//   Cross-RG RBAC back into rg-<prefix>-platform:
//     kubelet identity        -> AcrPull on nonprod + prod ACRs
//     KV CSI addon identity   -> Key Vault Secrets User
//
// Deploy platform.bicep FIRST - this template needs its outputs (LAW id,
// ACR names, KV name) either via params or the orchestration script.
// ============================================================================

targetScope = 'resourceGroup'

@allowed([
  'dev'
  'prod'
])
param environment string

param location string = resourceGroup().location
param namePrefix string = 'hexaks'

// ---- Shared platform wiring (values come from platform.bicep outputs) -------
param platformResourceGroupName string
param acrNonProdName string
param acrProdName string
param keyVaultName string
param logAnalyticsWorkspaceId string

// ---- Networking -------------------------------------------------------------
param vnetAddressPrefix string
param aksSubnetPrefix string
param peSubnetPrefix string

// ---- AKS --------------------------------------------------------------------
param kubernetesVersion string = ''
param systemVmSize string = 'Standard_B2s'
param systemMinCount int = 1
param systemMaxCount int = 2
param spotVmSize string = 'Standard_B2s'
param spotMinCount int = 0
param spotMaxCount int = 3

param tags object = {}

var envTags = union({
  project: 'aks-devsecops-platform'
  environment: environment
  costProfile: 'poc-optimized'
}, tags)

module network 'modules/network.bicep' = {
  name: 'network-${environment}'
  params: {
    namePrefix: '${namePrefix}-${environment}'
    location: location
    tags: envTags
    vnetAddressPrefix: vnetAddressPrefix
    aksSubnetPrefix: aksSubnetPrefix
    peSubnetPrefix: peSubnetPrefix
  }
}

module aks 'modules/aks.bicep' = {
  name: 'aks-${environment}'
  params: {
    name: 'aks-${namePrefix}-${environment}'
    location: location
    tags: envTags
    dnsPrefix: 'aks-${namePrefix}-${environment}'
    kubernetesVersion: kubernetesVersion
    subnetId: network.outputs.aksSubnetId
    systemVmSize: systemVmSize
    systemMinCount: systemMinCount
    systemMaxCount: systemMaxCount
    spotVmSize: spotVmSize
    spotMinCount: spotMinCount
    spotMaxCount: spotMaxCount
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

// Wire the env cluster's identities into the shared platform RG
module platformRoles 'modules/platform-roleassignments.bicep' = {
  name: 'platform-roles-${environment}'
  scope: resourceGroup(platformResourceGroupName)
  params: {
    acrNames: [
      acrNonProdName
      acrProdName
    ]
    keyVaultName: keyVaultName
    acrPullPrincipalId: aks.outputs.kubeletObjectId
    kvCsiPrincipalId: aks.outputs.kvSecretsIdentityObjectId
  }
}

output aksName string = aks.outputs.aksName
output aksFqdn string = aks.outputs.aksFqdn
output oidcIssuerUrl string = aks.outputs.oidcIssuerUrl
output vnetId string = network.outputs.vnetId
