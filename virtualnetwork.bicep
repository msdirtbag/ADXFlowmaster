//This bicep deploys the Virtual Network.

//Scope
targetScope = 'resourceGroup'

//Parameters
param env string
param larid string
param location string
param vnetspace string
param mainsnetspace string
param mainnsg string

//Resources

//This deploys the Virtual Network Resource Type and Subnet Resource Type.
resource virtualnetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-ADXFlowmaster-${env}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetspace
      ]
    }
    subnets: [
      {
        name: 'main'
        properties: {
          addressPrefix: mainsnetspace
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          defaultOutboundAccess: false
          networkSecurityGroup: {
            id: mainnsg
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.AzureActiveDirectory'
            }
          ]
        }
      }
    ]
  }
}

//Diagnostic settings for Virtual Network
resource virtualnetworkdiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Monitor'
  scope: virtualnetwork
  properties: {
    metrics: [
      {
        category: 'allMetrics'
        enabled: true
      }
    ]
    workspaceId: larid
  }
}

//Outputs
output virtualnetworkid string = virtualnetwork.id
output virtualnetworkname string = virtualnetwork.name
output mainsubnetresourceid string = resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-ADXFlowmaster-${env}', 'main')
output mainsubnetid string = virtualnetwork.properties.subnets[0].id
output mainsubnetname string = virtualnetwork.properties.subnets[0].name



