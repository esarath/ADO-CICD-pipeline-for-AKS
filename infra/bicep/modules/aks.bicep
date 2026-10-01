// ============================================================================
// aks.bicep - AKS cluster, cost-optimized POC profile.
//
// Cost profile (deliberately small - pay-as-you-go subscription):
//   - Free control-plane tier (no uptime SLA - fine for POC)
//   - 1 x Standard_B2s system node, autoscaler 1-2
//   - Spot user node pool (Standard_B2s spot), autoscaler 0-3
//     -> up to ~90% cheaper; pods tolerate the spot taint
//   - Azure CNI Overlay -> pods don't consume VNet IPs (scales cheaply)
//   - Azure Linux + Ephemeral OS disks -> fast, small nodes
//
// Enterprise deltas to revisit for real prod: Standard/Uptime tier, 3+ system
// nodes across zones, CriticalAddonsOnly taint, private API server, 4vCPU+ SKUs.
// ============================================================================

param name string
param location string
param tags object
param dnsPrefix string

@description('Empty = default AKS version for the region')
param kubernetesVersion string = ''

@description('Subnet ID for AKS nodes (from network.bicep)')
param subnetId string

// ---- Node pool sizing -------------------------------------------------------
param systemVmSize string = 'Standard_B2s'
param systemMinCount int = 1
param systemMaxCount int = 2
param spotVmSize string = 'Standard_B2s'
param spotMinCount int = 0
param spotMaxCount int = 3

@description('Taint the system pool CriticalAddonsOnly (enterprise posture). Keep false for the 1-node POC so app pods can still schedule when spot is scaled to zero.')
param systemPoolCriticalOnly bool = false

// ---- Overlay networking (must not overlap the VNet) -------------------------
param podCidr string = '192.168.0.0/16'
param serviceCidr string = '172.16.0.0/16'
param dnsServiceIp string = '172.16.0.10'

@description('LAW resource ID for Container Insights (omsagent addon)')
param logAnalyticsWorkspaceId string

resource aks 'Microsoft.ContainerService/managedClusters@2024-09-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Base'
    tier: 'Free' // 'Standard' gives 99.95% uptime SLA - enable for real prod
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: empty(kubernetesVersion) ? null : kubernetesVersion
    dnsPrefix: dnsPrefix
    enableRBAC: true

    agentPoolProfiles: [
      {
        name: 'system'
        mode: 'System'
        count: systemMinCount
        vmSize: systemVmSize
        osType: 'Linux'
        osSKU: 'AzureLinux'
        osDiskType: 'Ephemeral'
        osDiskSizeGB: 30
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: subnetId
        enableAutoScaling: true
        minCount: systemMinCount
        maxCount: systemMaxCount
        maxPods: 30
        nodeTaints: systemPoolCriticalOnly ? [
          'CriticalAddonsOnly=true:NoSchedule'
        ] : []
      }
      {
        name: 'spotpool'
        mode: 'User'
        count: spotMinCount
        vmSize: spotVmSize
        osType: 'Linux'
        osSKU: 'AzureLinux'
        osDiskType: 'Ephemeral'
        osDiskSizeGB: 30
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: subnetId
        enableAutoScaling: true
        minCount: spotMinCount
        maxCount: spotMaxCount
        maxPods: 30
        // Spot configuration
        scaleSetPriority: 'Spot'
        scaleSetEvictionPolicy: 'Deallocate'
        spotMaxPrice: -1 // -1 = pay up to on-demand price, evict on capacity only
        nodeLabels: {
          'kubernetes.azure.com/scalesetpriority': 'spot'
        }
        nodeTaints: [
          'kubernetes.azure.com/scalesetpriority=spot:NoSchedule'
        ]
      }
    ]

    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      networkPolicy: 'azure'
      podCidr: podCidr
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIp
      loadBalancerSku: 'standard'
      outboundType: 'loadBalancer'
    }

    aadProfile: {
      managed: true
      enableAzureRBAC: true
    }

    addonProfiles: {
      // Container Insights -> Log Analytics (MSI auth)
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
          useAADAuth: 'true'
        }
      }
      // Azure Policy addon (Gatekeeper) for governance + Deployment Safeguards
      azurepolicy: {
        enabled: true
      }
      // Key Vault Secrets Store CSI driver - pods mount secrets, no plumbing
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }
    }

    oidcIssuerProfile: {
      enabled: true
    }

    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
      // Defender runtime for containers is enabled at subscription level
      // via `az security pricing` (see scripts/01-deploy-infrastructure.ps1)
    }

    autoUpgradeProfile: {
      upgradeChannel: 'patch'
      nodeOSUpgradeChannel: 'NodeImage'
    }
  }
}

output aksName string = aks.name
output aksId string = aks.id
output aksFqdn string = aks.properties.fqdn
output oidcIssuerUrl string = aks.properties.oidcIssuerProfile.issuerURL
output kubeletObjectId string = aks.properties.identityProfile.kubeletidentity.objectId
output kvSecretsIdentityObjectId string = aks.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.objectId
