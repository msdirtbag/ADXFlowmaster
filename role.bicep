//This bicep creates the role assignments for the User Assigned Managed Identity.

//Scope
targetScope = 'resourceGroup'

//Variables
var contributorrole = '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
var eventgridrole = '/providers/Microsoft.Authorization/roleDefinitions/1e241071-0855-49ea-94dc-649edcd759de'
var blobrole = '/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var eventhubrecieverole = '/providers/Microsoft.Authorization/roleDefinitions/a638d3c7-ab3a-418d-83e6-5f17a39d4fde'
var eventhubsendrole = '/providers/Microsoft.Authorization/roleDefinitions/2b629674-e913-4c01-ae53-ef4638d8f975'

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
