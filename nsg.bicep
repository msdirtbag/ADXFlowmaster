//This bicep deploys an Network Security Group.

//Scope
targetScope = 'resourceGroup'

//Parameters
param env string
param location string
param larid string

//Resources

//This deploys the Network Security Groups for Main.
resource mainnsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-ADXFlowmaster-${env}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow_VNET_Inbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 800
          direction: 'Inbound'
        }
      }
      {
        name: 'Deny_All_Internet_Inbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Deny'
          priority: 999
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_VNET_Outbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 800
          direction: 'Outbound'
        }
      }
      {
        name: 'Allow_AzureCloud_Outbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 900
          direction: 'Outbound'
        }
      }
      {
        name: 'Deny_All_Internet_Outbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Internet'
          access: 'Deny'
          priority: 999
          direction: 'Outbound'
        }
      }
    ]
  }
}

//Diagnostic settings
resource mainnsgdiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Monitor-mainnsg'
  scope: mainnsg
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    workspaceId: larid
  }
}

//Outputs
output mainnsgid string = mainnsg.id




