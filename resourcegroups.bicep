//This bicep deploys the Resource Groups for the environment.

//Scope
targetScope = 'subscription'

//Variables

//Parameters
param env string
param location string

//Resources

//This deploys the Resource Group for the environment.
resource resourcegroup 'Microsoft.Resources/resourceGroups@2024-08-01' = {
  name: 'rg-ADXFlowmaster-${env}'
  location: location
}

//Outputs
output resourcegroupname string = resourcegroup.name


