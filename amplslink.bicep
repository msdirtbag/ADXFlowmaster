//This bicep deploys the AMPLS Link.

//Scope
targetScope = 'resourceGroup'

//Variables

//Parameters
param appinsightsid string
param appinsightsname string
param amplsname string

//Resources

//Reference to the AMPLS
resource azuremonitorlink 'Microsoft.insights/privatelinkscopes@2021-07-01-preview' existing = {
  name: amplsname
}

//Link the App Insights to the AMPLS
resource amplslink 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview' = {
  name: appinsightsname
  parent: azuremonitorlink
  properties: {
    linkedResourceId: appinsightsid
  }
}

//Outputs

