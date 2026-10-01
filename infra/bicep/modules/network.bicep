// ============================================================================
// network.bicep - Per-environment VNet for AKS (Azure CNI Overlay)
// Pods get IPs from the overlay CIDR (not the VNet), so only node IPs consume
// subnet addresses. A /25 AKS subnet is plenty for a small POC cluster.
// ============================================================================

@description('VNet address space, e.g. 10.42.0.0/24')
param vnetAddressPrefix string

@description('AKS node subnet, e.g. 10.42.0.0/25')
param aksSubnetPrefix string

@description('Reserved subnet for optional private endpoints, e.g. 10.42.0.128/26')
param peSubnetPrefix string

param location string
param namePrefix string
param tags object

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-${namePrefix}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
    subnets: [
      {
        name: 'snet-aks'
        properties: {
          addressPrefix: aksSubnetPrefix
        }
      }
      {
        // Reserved for private endpoints (ACR/KV Premium hardening). Not used
        // in the cost-optimized POC profile but kept so it is a Day-1 change.
        name: 'snet-pe'
        properties: {
          addressPrefix: peSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output aksSubnetId string = vnet.properties.subnets[0].id
output peSubnetId string = vnet.properties.subnets[1].id
