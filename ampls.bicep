//This bicep deploys the AMPLS.

//Scope
targetScope = 'resourceGroup'

//Variables

//Parameters
param location string
param snetmainid string
param amplsid string
param vnetid string
param zones array = [
  'agentsvc.azure-automation.net'
  'monitor.azure.com'
  'ods.opinsights.azure.com'
  'oms.opinsights.azure.com'
]


//Resources

//This deploys the Azure Monitor Private Endpoint.
resource amplsscopeprivatendpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: 'pe-ampls'
  location: location
  properties: {
    subnet: {
      id: snetmainid
    }
    privateLinkServiceConnections: [
      {
        name: 'psc-ampls'
        properties: {
          privateLinkServiceId: amplsid
          groupIds: [
            'azuremonitor'
          ]
        }
      }
    ]
  }
  dependsOn: [
    privatednszoneforampls
    privatednszonelink
  ]
}

// Create Private DNS Zone for "pe-ampls"
resource privatednszoneforampls 'Microsoft.Network/privateDnsZones@2024-06-01' = [for zone in zones: {
  name: 'privatelink.${zone}'
  location: 'global'
  properties: {
  }
}]

//This deploys the DNS Zone Link.
resource privatednszonelink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [for (zone,i) in zones: { 
  parent: privatednszoneforampls[i]
  name: '${zone}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetid
    }
  }
}]

// Create Private DNS Zone Group.
resource pednsgroupforampls 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = {
  parent: amplsscopeprivatendpoint
  name: 'pvtendpointdnsgroupforampls'
  properties: {
    privateDnsZoneConfigs: [
      for (zone,i) in zones: {
        name: privatednszoneforampls[i].name
        properties: {
          privateDnsZoneId: privatednszoneforampls[i].id
        }
      }
    ]
  }
}



