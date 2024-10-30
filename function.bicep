//This bicep deploys the Azure Function App.

//Scope
targetScope = 'resourceGroup'

//Variables
var subscriptionid = subscription().subscriptionId

//Parameters
param location string
param environmentid string
param umirid string
param larid string
param snetexid string
param snetmainid string
param vnetid string
param vnetname string
param umicid string
param adxstname string
param amplsname string
param tenantdomain string
param adxingesturl string

//Resources

//Shared Resources

resource dnsblob 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: 'privatelink.blob.core.windows.net'
}

resource dnsfile 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.file.core.windows.net'
  location: 'global'
}

resource dnsqueue 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.queue.core.windows.net'
  location: 'global'
}

resource dnstable 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.table.core.windows.net'
  location: 'global'
}

resource dnswebsites 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
}

resource dnsblobvnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsblob
  name: vnetname
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetid
    }
  }
}

resource dnsfilevnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsfile
  name: vnetname
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetid
    }
  }
}

resource dnsqueuevnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnsqueue
  name: vnetname
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetid
    }
  }
}

resource dnstablevnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnstable
  name: vnetname
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetid
    }
  }
}

resource dnswebsitesvnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: dnswebsites
  name: vnetname
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetid
    }
  }
}

//Function

//This deploys the Azure Function Storage Account.
resource storage01 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stfunc${environmentid}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umirid}': {}
    }
  }
  kind: 'StorageV2'
  sku: {
    name: 'Standard_ZRS'
  }
  properties: {
    isLocalUserEnabled: false
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: true
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Enabled'
    minimumTlsVersion: 'TLS1_2'
  }
}

//This deploys the Function Storage Blob Private Endpoint.
resource funcblob01pe 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: 'pe-${environmentid}funcst01blob'
  location: location
  properties: {
    subnet: {
      id: snetmainid
    }
    privateLinkServiceConnections: [
      {
        name: 'psc-${environmentid}funcst01blob'
        properties: {
          privateLinkServiceId: storage01.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

// Create Private DNS Zone Group.
resource funcblob01pegroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: storage01.name
  parent: funcblob01pe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: storage01.name
        properties: {
          privateDnsZoneId: dnsblob.id
        }
      }
    ]
  }
}

//This deploys the Function Storage File Private Endpoint.
resource funcfile01pe 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: 'pe-${environmentid}funcst01file'
  location: location
  properties: {
    subnet: {
      id: snetmainid
    }
    privateLinkServiceConnections: [
      {
        name: 'psc-func01file-${environmentid}'
        properties: {
          privateLinkServiceId: storage01.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

// Create Private DNS Zone Group.
resource funcfile01pegroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: storage01.name
  parent: funcfile01pe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: storage01.name
        properties: {
          privateDnsZoneId: dnsfile.id
        }
      }
    ]
  }
}

//This deploys the Function Storage Queue Private Endpoint.
resource funcqueue01pe 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: 'pe-${environmentid}funcst01queue'
  location: location
  properties: {
    subnet: {
      id: snetmainid
    }
    privateLinkServiceConnections: [
      {
        name: 'psc-${environmentid}funcst01queue'
        properties: {
          privateLinkServiceId: storage01.id
          groupIds: [
            'queue'
          ]
        }
      }
    ]
  }
}

// Create Private DNS Zone Group.
resource funcqueue01pegroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: storage01.name
  parent: funcqueue01pe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: storage01.name
        properties: {
          privateDnsZoneId: dnsqueue.id
        }
      }
    ]
  }
}

//This deploys the Function Storage Table Private Endpoint.
resource functable01pe 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: 'pe-${environmentid}funcst01table'
  location: location
  properties: {
    subnet: {
      id: snetmainid
    }
    privateLinkServiceConnections: [
      {
        name: 'psc-${environmentid}funcst01table'
        properties: {
          privateLinkServiceId: storage01.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
}

// Create Private DNS Zone Group.
resource functable01pegroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: storage01.name
  parent: functable01pe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: storage01.name
        properties: {
          privateDnsZoneId: dnstable.id
        }
      }
    ]
  }
}

resource appinsights01 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-ADXFlowmaster-${environmentid}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: larid
    RetentionInDays: 60
    IngestionMode: 'LogAnalytics'
    Flow_Type: 'Bluefield'
    DisableLocalAuth: true
    DisableIpMasking: true
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

//This links the Application Insights to the AMPLS.
module amplslink01 './amplslink.bicep' = {
  name: 'amplslink-ADXFlowmaster-${environmentid}'
  scope: resourceGroup()
  params:{
    appinsightsid: appinsights01.id
    appinsightsname: appinsights01.name
    amplsname: amplsname
  }
}

//Diagnostic settings for Application Insights
resource appinsights01diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Monitor-Appinsights01'
  scope: appinsights01
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'allMetrics'
        enabled: true
      }
    ]
    workspaceId: larid
  }
}

//This deploys the App Service Plan for the Azure Function.
resource appservice 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'asp-ADXFlowmaster-${environmentid}'
  location: location

  properties: {
    reserved: false
    elasticScaleEnabled: true
    maximumElasticWorkerCount: 20
  }
  sku: {
    tier: 'ElasticPremium'
    name: 'EP1'    
  }
}

//Diagnostic settings for App Service Plan.
resource appservicediag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Monitor'
  scope: appservice
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

//This deploys the Azure Function.
resource function01 'Microsoft.Web/sites@2023-12-01' = {
  name: 'funcADXFlowmaster${environmentid}'
  kind: 'functionapp'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umirid}': {}
    }
  }
  properties: {
    serverFarmId: appservice.id
    virtualNetworkSubnetId: snetexid
    publicNetworkAccess: 'Enabled'
    httpsOnly: true
    siteConfig: {
      vnetRouteAllEnabled: true
      autoHealEnabled: true
      detailedErrorLoggingEnabled: true
      httpLoggingEnabled: true
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
          'https://preview.portal.azure.com'
        ]
        supportCredentials: true
      }
      preWarmedInstanceCount: 2
      remoteDebuggingEnabled: false
      requestTracingEnabled: true
      scmMinTlsVersion: '1.2'
      http20Enabled: true
      functionAppScaleLimit: 10
      functionsRuntimeScaleMonitoringEnabled: true
      appSettings: [
        {
            name: 'FUNCTIONS_EXTENSION_VERSION'
            value: '~4'
        }
        {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: appinsights01.properties.ConnectionString
        }
        {
            name: 'APPLICATIONINSIGHTS_AUTHENTICATION_STRING'
            value: 'Authorization=AAD;ClientId=${umicid}'
        }
        {
            name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
            value: '~3'
        }
        {
            name: 'APPLICATIONINSIGHTS_ENABLE_AGENT'
            value: 'true'
        }
        {
            name: 'XDT_MicrosoftApplicationInsights_Mode'
            value: 'recommended'
        }   
        {
            name: 'FUNCTIONS_WORKER_RUNTIME'
            value: 'powershell'
        }
        {
            name: 'DiagnosticServices_EXTENSION_VERSION'
            value: '~3'
        }
        {
            name: 'WEBSITE_CONTENTOVERVNET'
            value: '1'
        }
        {
            name: 'WEBSITE_DNS_SERVER'
            value: '168.63.129.16'
        }
        {
            name: 'WEBSITE_OVERRIDE_STICKY_DIAGNOSTICS_SETTINGS'
            value: '0'
        }
        {
            name: 'AzureWebJobsStorage__accountname'
            value: storage01.name
        }
        {
            name: 'AzureWebJobsStorage__blobServiceUri'
            value: 'https://${storage01.name}.blob.core.windows.net/'
        }
        {
            name: 'AzureWebJobsStorage__queueServiceUri'
            value: 'https://${storage01.name}.queue.core.windows.net/'
        }
        {
            name: 'AzureWebJobsStorage__tableServiceUri'
            value: 'https://${storage01.name}.table.core.windows.net/'
        }
        {
            name: 'AzureWebJobsStorage__fileServiceUri'
            value: 'https://${storage01.name}.file.core.windows.net/'
        }
        {
            name: 'FUNCTIONS_WORKER_PROCESS_COUNT'
            value: '10'
        }
        {
            name: 'ADX_STORAGE_ACCOUNT_NAME'
            value: adxstname
        }
        {
            name: 'AZURE_CLIENT_ID'
            value: umicid
        }
        {
            name: 'AZURE_SUBSCRIPTION_ID'
            value: subscriptionid
        }
        {
            name: 'ADX_INGEST_URL'
            value: adxingesturl
        }
        {
            name: 'ADX_URL'
            value: adxingesturl
        }
        {
            name: 'WEBSITE_RUN_FROM_PACKAGE'
            value: 'https://github.com/msdirtbag/ADXFlowmaster/blob/main/function.zip?isAsync=true'
        }
        {
            name: 'TENANT_DOMAIN'
            value: '${tenantdomain}.onmicrosoft.com'
        }
        {
            name: 'UALMASTER_OPERATIONS'
            value: 'MailItemsAccessed'
        }
        {
            name: 'AzureWebJobs.ualmaster.Disabled'
            value: '1'
        }
        {
            name: 'ADX_URL'
            value: adxingesturl
        }
        {
            name: 'WEBSITE_RUN_FROM_PACKAGE'
            value: 'https://bvautomation.blob.core.windows.net/deployment/ual.zip?isAsync=true'
        }
        {
            name: 'TENANT_DOMAIN'
            value: '${tenantdomain}.onmicrosoft.com'
        }
        {
            name: 'UALMASTER_OPERATIONS'
            value: 'MailItemsAccessed'
        }
        {
            name: 'AzureWebJobs.ualmaster.Disabled'
            value: '1'
        }
      ]
      use32BitWorkerProcess: false
      ftpsState: 'Disabled'
      powerShellVersion: '7.4'
      netFrameworkVersion: 'v8.0'
    }
  }
  dependsOn: [
    funcqueue01pegroup
    functable01pegroup
    funcfile01pegroup
    funcblob01pegroup
  ]
}

//Diagnostic settings for Function
resource functiondiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Monitor'
  scope: function01
  properties: {
    logs: [
      {
        category: 'FunctionAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'allMetrics'
        enabled: true
      }
    ]
    workspaceId: larid
  }
}

/*

//This deploys the Function Private Endpoint.
resource function01pe 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: 'pe-func01-${environmentid}'
  location: location
  properties: {
    subnet: {
      id: snetmainid
    }
    privateLinkServiceConnections: [
      {
        name: 'psc-func01-${environmentid}'
        properties: {
          privateLinkServiceId: function01.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

// Create Private DNS Zone Group.
resource func01zonegroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: function01.name
  parent: function01pe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: function01.name
        properties: {
          privateDnsZoneId: dnswebsites.id
        }
      }
    ]
  }
}
*/

//Outputs
output function01id string = function01.id
output function01name string = function01.name
output appinsights01id string = appinsights01.id










