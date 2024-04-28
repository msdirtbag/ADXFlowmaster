//ADXFlowmaster
//Version: 0.2.4
//Parameters for the ADXFlowmaster

using './main.bicep'

//Static Parameters
param vnetspace = '' // The IP address space for the virtual network (/26 or larger)
param mainsnetspace = '' // The IP address space for the main subnet (/26 or larger)

//Security Group ObjectID for AllDatabasesAdmin
param adxsgid = '' // The ObjectID of the Entra ID security group that will have admin access to all Flowmaster databases

//Metadata
param env = '' // The environment tag, used to differentiate resources in different environments and prevents CI/CD collisions. (e.g., dev, test, prod)


