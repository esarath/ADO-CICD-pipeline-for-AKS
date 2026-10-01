// ============================================================================
// grafana.bicep - Azure Managed Grafana (Standard SKU, smallest option).
// Wired to the Azure Monitor Workspace so Managed Prometheus dashboards work.
// NOTE: ~$9-10/month fixed cost. For a zero-cost POC alternative, run Grafana
// OSS as a Helm release on the spot node pool (see doc 06).
// ============================================================================

param name string
param location string
param tags object

@description('Azure Monitor Workspace ID to register as a datasource')
param azureMonitorWorkspaceId string

@description('Object ID of the Entra user/group to grant Grafana Admin. Empty = skip.')
param adminObjectId string = ''

var grafanaAdminRoleId = '22926164-76b3-42b3-bc55-97df8dab3e41'
var monitoringDataReaderRoleId = 'b0d8363b-8ddd-447d-831f-62ca05bff136'

resource grafana 'Microsoft.Dashboard/grafana@2023-09-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
    apiKey: 'Disabled'
    deterministicOutboundIP: 'Disabled'
    grafanaIntegrations: {
      azureMonitorWorkspaceIntegrations: [
        {
          azureMonitorWorkspaceResourceId: azureMonitorWorkspaceId
        }
      ]
    }
  }
}

resource amw 'microsoft.monitor/accounts@2023-04-03' existing = {
  name: last(split(azureMonitorWorkspaceId, '/'))
}

// Grafana identity can read metrics from the AMW
resource grafanaAmwReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(amw.id, grafana.id, monitoringDataReaderRoleId)
  scope: amw
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringDataReaderRoleId)
    principalId: grafana.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Grant the deploying user Grafana Admin so they can open dashboards
resource grafanaAdmin 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(adminObjectId)) {
  name: guid(grafana.id, adminObjectId, grafanaAdminRoleId)
  scope: grafana
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', grafanaAdminRoleId)
    principalId: adminObjectId
    principalType: 'User'
  }
}

output endpoint string = grafana.properties.endpoint
output id string = grafana.id
