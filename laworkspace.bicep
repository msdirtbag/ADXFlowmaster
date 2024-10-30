//This bicep deploys Log Analytics Workspace.

//Scope
targetScope = 'resourceGroup'

//Parameters
param location string
param environmentid string
param umirid string

//Resources

//This deploys the Log Analytics Workspace.
resource laworkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
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
      disableLocalAuth: true
      enableDataExport: true
    }
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Enabled'
    retentionInDays: 90
    sku: {
      name: 'PerGB2018'
    }
  }
}

//This deploys the Azure Monitor Private Link Scope.
resource amplsscope 'microsoft.insights/privateLinkScopes@2021-07-01-preview' = {
  name: 'ampls-ADXFlowmaster-${environmentid}'
  location: 'global'
  properties: {
    accessModeSettings: {
      ingestionAccessMode: 'PrivateOnly'
      queryAccessMode: 'Open'
    }
  }
}

//This deploys the Azure Monitor Private Link Scope Link.
resource amplslink 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview' = {
  name: 'amplslink-ADXFlowmaster-${environmentid}'
  parent: amplsscope
  properties: {
    linkedResourceId: laworkspace.id
  }
}

//Outputs
output laworkspacerid string = laworkspace.id
output laworkspacename string = laworkspace.name
output amplsscopeid string = amplsscope.id
output amplsscopename string = amplsscope.name
