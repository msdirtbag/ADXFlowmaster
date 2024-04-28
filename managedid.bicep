//This bicep deploys the User Managed Identity.

//Scope
targetScope = 'resourceGroup'

//Parameters
param env string
param location string

//Resources

//This deploys the shared User Managed Identity.
resource umi 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'umi-ADXFlowmaster-${env}'
  location: location
}

output umipid string = umi.properties.principalId
output umicid string = umi.properties.clientId
output umirid string = umi.id
output uminame string = umi.name










