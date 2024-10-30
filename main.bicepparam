//ADXFlowmaster
//Version: 0.4.0
//Parameters for the ADXFlowmaster

using './main.bicep'

//Static Parameters
param vnetspace = '' // The IP address space for the virtual network (/26 or larger)
param mainsnetspace = '' // The IP address space for the main subnet (/26 or larger)
param funcsnetspace = '' // The IP address space for the functions subnet (/26 or larger)

//Security Group ObjectID for AllDatabasesAdmin
param adxsgid = '' // The ObjectID of the Entra ID security group that will have admin access to all Flowmaster databases

//Primary Entra ID Tenant Domain
param tenantdomain = '' // The primary Entra ID tenant domain (e.g., corpxyz.onmicrosoft.com) Note: The onmicrosoft.com section is not required.

//Metadata
param env = '' // The environment tag, used to differentiate resources in different environments and prevents CI/CD collisions. (e.g., dev, test, prod)

//Role Creation Service Principal
param spnid = '' // The Client ID of the service principal that will be used to create the Entra ID roles
param spnsecret = '' // The secret for the service principal that will be used to create the Entra ID roles

