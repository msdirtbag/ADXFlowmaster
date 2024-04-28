//This bicep deploys Log Analytics Workspace.

//Scope
targetScope = 'resourceGroup'

//Parameters
param location string
param environmentid string
param umirid string

//Resources

//This deploys the Log Analytics Workspace.
resource laworkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-ADXFlowmaster-${environmentid}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umirid}': {}
    }
  }
  properties: {
    features: {
      enableDataExport: true
    }
    retentionInDays: 90
    sku: {
      name: 'PerGB2018'
    }
  }
}

//Outputs
output laworkspacerid string = laworkspace.id
output laworkspacename string = laworkspace.name
