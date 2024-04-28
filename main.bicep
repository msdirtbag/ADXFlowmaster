//ADXFlowmaster
//Version: 0.2.4
//This bicep deployment provisions the ADXFlowmaster solution

//Scope
targetScope = 'subscription'

//Variables
var environmentid = uniqueString(subscription().id, tenant().tenantId, env)
var location = deployment().location

//Parameters
param env string
param adxsgid string
param vnetspace string
param mainsnetspace string

//Modules

//This module deploys the Resource Group.
module resourcegroupmodule './resourcegroups.bicep' = {
  name: 'rg-ADXFlowmaster-${env}'
  scope:subscription()
  params:{
    env: env
    location: location
  }
}

//This module deploys the User Managed Managed identity.
module managedidpmodule './managedid.bicep' = {
  name: 'umi-ADXFlowmaster-${env}'
  scope: resourceGroup('rg-ADXFlowmaster-${env}')
  params:{
    env: environmentid
    location: location
  }
  dependsOn: [
    resourcegroupmodule
  ]
}

//This module deploys the Role Assignment for the User Managed Identity.
module rolemodule './role.bicep' = {
  name: 'umirole-ADXFlowmaster-${env}'
  scope: resourceGroup('rg-ADXFlowmaster-${env}')
  params:{
    principalId: managedidpmodule.outputs.umipid
  }
  dependsOn: [
    managedidpmodule
  ]
}

//This module deploys the Log Analytics Workspace.
module laworkspacemodule './laworkspace.bicep' = {
  name: 'law-ADXFlowmaster-${env}'
  scope: resourceGroup('rg-ADXFlowmaster-${env}')
  params:{
    location: location
    umirid: managedidpmodule.outputs.umirid
    environmentid: environmentid
  }
  dependsOn: [
    managedidpmodule
    rolemodule
  ]
}

//This module deploys the Virtual Network.
module virtualnetworkmodule './virtualnetwork.bicep' = {
  name: 'vnet-ADXFlowmaster-${env}'
  scope: resourceGroup('rg-ADXFlowmaster-${env}')
  params:{
    env: environmentid
    larid: laworkspacemodule.outputs.laworkspacerid
    location: location
    vnetspace: vnetspace
    mainsnetspace: mainsnetspace
    mainnsg: networksecuritygroupmodule.outputs.mainnsgid
  }
  dependsOn: [
    resourcegroupmodule
    networksecuritygroupmodule
  ]
}

//This module deploys the Network Security Group.
module networksecuritygroupmodule './nsg.bicep' = {
  name: 'nsg-ADXFlowmaster-${env}'
  scope: resourceGroup('rg-ADXFlowmaster-${env}')
  params:{
    env: environmentid
    location: location
    larid: laworkspacemodule.outputs.laworkspacerid
  }
  dependsOn: [
    resourcegroupmodule
  ]
}

//This module deploys the Azure Data Explorer Cluster.
module adxemodule './adx.bicep' = {
  name: 'adx-ADXFlowmaster-${env}'
  scope: resourceGroup('rg-ADXFlowmaster-${env}')
  params:{
    environmentid: environmentid
    larid: laworkspacemodule.outputs.laworkspacerid
    location: location
    snetmainid: virtualnetworkmodule.outputs.mainsubnetresourceid
    umirid: managedidpmodule.outputs.umirid
    vnetid: virtualnetworkmodule.outputs.virtualnetworkid
    umipid: managedidpmodule.outputs.umipid
    adxsgid: adxsgid
  }
  dependsOn: [
    managedidpmodule
    rolemodule
  ]
}
