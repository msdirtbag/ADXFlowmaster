//This bicep creates the role assignments for the User Assigned Managed Identity.

//Scope
targetScope = 'resourceGroup'

//Variables
var contributorrole = '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
var eventgridrole = '/providers/Microsoft.Authorization/roleDefinitions/1e241071-0855-49ea-94dc-649edcd759de'
var blobrole = '/providers/Microsoft.Authorization/roleDefinitions/b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
var eventhubrecieverole = '/providers/Microsoft.Authorization/roleDefinitions/a638d3c7-ab3a-418d-83e6-5f17a39d4fde'
var eventhubsendrole = '/providers/Microsoft.Authorization/roleDefinitions/2b629674-e913-4c01-ae53-ef4638d8f975'
var metricspublisherrole = '/providers/Microsoft.Authorization/roleDefinitions/3913510d-42f4-4e42-8a64-420c390055eb'
var stcontributorrole = '/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab'
var stqueuerole = '/providers/Microsoft.Authorization/roleDefinitions/974c5e8b-45b9-4653-ba55-5f855dd0fb88'
var sttablerole = '/providers/Microsoft.Authorization/roleDefinitions/0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'

//Parameters
param principalId string 

//Resources

//This deploys the role assignmtent.
resource contributorroleassign 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, contributorrole, subscription().id)
  properties: {
    roleDefinitionId: contributorrole
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource eventgridroleassign 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, eventgridrole, subscription().id)
  properties: {
    roleDefinitionId: eventgridrole
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource blobroleassign 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, blobrole, subscription().id)
  properties: {
    roleDefinitionId: blobrole
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource eventhubsendroleassign 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, eventhubsendrole, subscription().id)
  properties: {
    roleDefinitionId: eventhubsendrole
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource eventhubrecieveroleassign 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, eventhubrecieverole, subscription().id)
  properties: {
    roleDefinitionId: eventhubrecieverole
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource metricspublisherroleassign 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, metricspublisherrole, subscription().id)
  properties: {
    roleDefinitionId: metricspublisherrole
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource stcontributorroleassign 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, stcontributorrole, subscription().id)
  properties: {
    roleDefinitionId: stcontributorrole
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource stqueueroleassign 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, stqueuerole, subscription().id)
  properties: {
    roleDefinitionId: stqueuerole
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource sttableroleassign 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, sttablerole, subscription().id)
  properties: {
    roleDefinitionId: sttablerole
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
