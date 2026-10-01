// ============================================================================
// platform-roleassignments.bicep - RBAC bindings into the SHARED platform RG.
// Deployed with `scope: resourceGroup(platformRg)` from main.bicep so the
// environment AKS identities get access to shared ACRs and Key Vault.
//
//   AKS kubelet identity            -> AcrPull on both ACRs
//   KV Secrets Provider identity    -> Key Vault Secrets User on the vault
// ============================================================================

param acrNames array
param keyVaultName string

@description('Object ID of the AKS kubelet managed identity')
param acrPullPrincipalId string

@description('Object ID of the Key Vault Secrets Provider addon identity')
param kvCsiPrincipalId string

var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var kvSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource acrs 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = [for n in acrNames: {
  name: n
}]

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource acrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (n, i) in acrNames: {
  name: guid(acrs[i].id, acrPullPrincipalId, acrPullRoleId)
  scope: acrs[i]
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: acrPullPrincipalId
    principalType: 'ServicePrincipal'
  }
}]

resource kvSecrets 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, kvCsiPrincipalId, kvSecretsUserRoleId)
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvSecretsUserRoleId)
    principalId: kvCsiPrincipalId
    principalType: 'ServicePrincipal'
  }
}
