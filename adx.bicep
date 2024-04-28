//This bicep deploys the Azure Data Explorer Cluster, Storage Account, Event Hub and Event Grid.

//Scope
targetScope = 'resourceGroup'

//Variables

//Parameters
param umirid string
param umipid string
param larid string
param location string
param environmentid string
param snetmainid string
param vnetid string
param adxsgid string

//Resources

//This deploys the ADX Cluster.
resource kustocluster 'Microsoft.Kusto/clusters@2023-08-15' = {
  name: 'adxfm${environmentid}'
  location: location
  sku: {
    capacity: 2
    name: 'Standard_E4ads_v5'
    tier: 'Standard'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umirid}': {}
    }
  }
  properties: {
    enableAutoStop: true
    enableDiskEncryption: true
    enablePurge: false
    enableStreamingIngest: true
    engineType: 'V3'
    publicIPType: 'IPv4'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }
}

//This deploys the UMI Role Assignment.
resource umiroleassign 'Microsoft.Kusto/clusters/principalAssignments@2023-08-15' = {
  name: 'umiradx${environmentid}'
  parent: kustocluster
  properties: {
    principalId: umipid
    principalType: 'App'
    role: 'AllDatabasesAdmin'
    tenantId: tenant().tenantId
  }
}

//This deploys the SG Role Assignment.
resource sgroleassign 'Microsoft.Kusto/clusters/principalAssignments@2023-08-15' = {
  name: 'sgadx${environmentid}'
  parent: kustocluster
  properties: {
    principalId: adxsgid
    principalType: 'Group'
    role: 'AllDatabasesAdmin'
    tenantId: tenant().tenantId
  }
}

//This deploys the ADXFlowmaster ADX Database.
resource flowdatabase 'Microsoft.Kusto/clusters/databases@2023-08-15' = {
  name: 'ADXFlowmaster'
  parent: kustocluster
  location: location
  kind: 'ReadWrite'
  properties: {
    hotCachePeriod: 'P60D'
    softDeletePeriod: 'P120D'
  }
}

//Diagnostic settings
resource kustoclusterdiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Monitor-adx'
  scope: kustocluster
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

//This deploys the ADX Private Endpoint.
resource kustoclusterpe 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: 'pe-adx-${environmentid}'
  location: location
  properties: {
    subnet: {
      id: snetmainid
    }
    privateLinkServiceConnections: [
      {
        name: 'psc-adx-${environmentid}'
        properties: {
          privateLinkServiceId: kustocluster.id
          groupIds: [
            'cluster'
          ]
        }
      }
    ]
  }
}

//This deploys the DNS Zone Link.
resource dnsadx 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.${location}.kusto.windows.net'
  location: 'global'
  dependsOn: [
    kustocluster
  ]
}

//This deploys the DNS Virtual Network Link.
resource dnsvnetlinkadx 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dnsadx
  name: 'adx-${environmentid}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetid
    }
  }
}

// Create Private DNS Zone Group.
resource kustozonegroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: kustocluster.name
  parent: kustoclusterpe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: kustocluster.name
        properties: {
          privateDnsZoneId: dnsadx.id
        }
      }
    ]
  }
}

//This deploys the Storage Account.
resource storage01 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stadx${environmentid}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umirid}': {}
    }
  }
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
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
      defaultAction: 'Allow'
    }
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Enabled'
    minimumTlsVersion: 'TLS1_2'
  }
}

//This enables archive rule to Archive tier and adds a deletion rule for 12 months.
resource archivevrule 'Microsoft.Storage/storageAccounts/managementPolicies@2023-01-01' = {
  parent: storage01
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          enabled: true
          name: 'Archive'
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                tierToCool: {
                  daysAfterModificationGreaterThan: 10
                }
              }
            }
            filters: {
              blobTypes: [
                'blockBlob'
              ]
            }
          }
        }
        {
          enabled: true
          name: 'DeleteAfter24Months'
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                delete: {
                  daysAfterModificationGreaterThan: 365
                }
              }
            }
            filters: {
              blobTypes: [
                'blockBlob'
              ]
            }
          }
        }
      ]
    }
  }
}

//Diagnostic settings for Storage
resource storage01diag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Monitor-storage01'
  scope: storage01
  properties: {
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
    workspaceId: larid
  }
}

//This deploys the Blob Service.
resource adxblobserv 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: storage01
  properties: {
  }
}

//Diagnostic settings
resource adxblobservdiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Monitor-ADXblob'
  scope: adxblobserv
  properties: {
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
    workspaceId: larid
  }
}

//This deploys the Storage Blob Private Endpoint.
resource adxblob01pe 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: 'pe-${environmentid}adxstblob'
  location: location
  properties: {
    subnet: {
      id: snetmainid
    }
    privateLinkServiceConnections: [
      {
        name: 'psc-${environmentid}adxstblob'
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

//This deploys the DNS Zone.
resource dnsblob 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
}

// Create Private DNS Zone Group.
resource adxblob01pegroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: storage01.name
  parent: adxblob01pe
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

//This deploys the Blob Topic.
resource adxblobtopic 'Microsoft.EventGrid/systemTopics@2023-12-15-preview' = {
  name: 'egst-flowmaster-${environmentid}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umirid}': {}
    }
  }
  properties: {
    source: storage01.id
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
}

//Diagnostic settings for Event Grid
resource adxeventgriddiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Monitor-eventgrid-adx'
  scope: adxblobtopic
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

//This deploys the ADXFlowmaster KQL Script.
resource flowmasterscript 'Microsoft.Kusto/clusters/databases/scripts@2023-08-15' = {
  name: 'tablesscript-flowmaster-${environmentid}'
  parent: flowdatabase
  properties: {
    continueOnErrors: false
    scriptContent: loadTextContent('flowmaster.kql')
  }
  dependsOn: [
    dnsadx
  ]
}

//This deploys the Event Hub Namespace.
resource adxeventhubnamespace 'Microsoft.EventHub/namespaces@2023-01-01-preview' = {
  name: 'evhns-flowmaster-${environmentid}'
  location: location
  sku: {
    capacity: 1
    name: 'Standard'
    tier: 'Standard'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umirid}': {}
    }
  }
  properties: {
    disableLocalAuth: true
    isAutoInflateEnabled: false
    kafkaEnabled: true
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

//The Flow Logs Event Hub
resource flowlogshub 'Microsoft.EventHub/namespaces/eventhubs@2023-01-01-preview' = {
  name: 'evh-flowmaster-flowlogs-${environmentid}'
  parent: adxeventhubnamespace
  properties: {
    messageRetentionInDays: 1
    partitionCount: 8
  }
}

//The DeviceNetworkEvents Event Hub
resource devicenetworkhub 'Microsoft.EventHub/namespaces/eventhubs@2023-01-01-preview' = {
  name: 'evh-flowmaster-devicenetwork-${environmentid}'
  parent: adxeventhubnamespace
  properties: {
    messageRetentionInDays: 1
    partitionCount: 8
  }
}

//The ThreatIntelligenceIndicator Event Hub
resource ctihub 'Microsoft.EventHub/namespaces/eventhubs@2023-01-01-preview' = {
  name: 'evh-flowmaster-cti-${environmentid}'
  parent: adxeventhubnamespace
  properties: {
    messageRetentionInDays: 1
    partitionCount: 8
  }
}

//The DeviceNetworkEvents Subscription
resource devicenetworksubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2023-12-15-preview' = {
  parent: adxblobtopic
  name: 'evgs-flowmaster-devicenetwork-${environmentid}'
  properties: {
    deliveryWithResourceIdentity: {
      destination: {
        endpointType: 'EventHub'
        properties: {
          resourceId: devicenetworkhub.id
        }
      }
      identity: {
        type: 'UserAssigned'
        userAssignedIdentity: umirid
      }
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
      subjectBeginsWith: '/blobServices/default/containers/insights-logs-advancedhunting-devicenetworkevents/'
    }
  }
}

//The Flow Logs Subscription
resource flowlogssubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2023-12-15-preview' = {
  parent: adxblobtopic
  name: 'evgs-flowmaster-flowlogs-${environmentid}'
  properties: {
    deliveryWithResourceIdentity: {
      destination: {
        endpointType: 'EventHub'
        properties: {
          resourceId: flowlogshub.id
        }
      }
      identity: {
        type: 'UserAssigned'
        userAssignedIdentity: umirid
      }
    }
    eventDeliverySchema: 'EventGridSchema'
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
      enableAdvancedFilteringOnArrays	: false
      subjectBeginsWith: '/blobServices/default/containers/insights-logs-flowlogflowevent/'
      isSubjectCaseSensitive: true
      subjectEndsWith: 'PT1H.json'
    }
  }
}

//The CTI Subscription
resource ctisubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2023-12-15-preview' = {
  parent: adxblobtopic
  name: 'evgs-flowmaster-cti-${environmentid}'
  properties: {
    deliveryWithResourceIdentity: {
      destination: {
        endpointType: 'EventHub'
        properties: {
          resourceId: ctihub.id
        }
      }
      identity: {
        type: 'UserAssigned'
        userAssignedIdentity: umirid
      }
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
      subjectBeginsWith: '/blobServices/default/containers/am-threatintelligenceindicator/'
    }
  }
}

//The Device Network Data Connection
resource devicenetworkdataconnection 'Microsoft.Kusto/clusters/databases/dataConnections@2023-08-15' = {
  name: 'adxdc-fw-devicenetwork-${environmentid}'
  location: location
  parent: flowdatabase
  kind: 'EventGrid'
  properties: {
    consumerGroup: '$Default'
    dataFormat: 'JSON'
    databaseRouting: 'Multi'
    managedIdentityResourceId: umirid
    eventGridResourceId: adxblobtopic.id
    eventHubResourceId: devicenetworkhub.id
    storageAccountResourceId: storage01.id
    tableName: 'DeviceNetworkEvents'
    mappingRuleName: 'DeviceNetworkEvents_mapping'
    }
    dependsOn: [
      flowmasterscript
    ]
}

//The CTI Data Connection
resource ctidataconnection 'Microsoft.Kusto/clusters/databases/dataConnections@2023-08-15' = {
  name: 'adxdc-fw-cti-${environmentid}'
  location: location
  parent: flowdatabase
  kind: 'EventGrid'
  properties: {
    consumerGroup: '$Default'
    dataFormat: 'JSON'
    databaseRouting: 'Multi'
    managedIdentityResourceId: umirid
    eventGridResourceId: adxblobtopic.id
    eventHubResourceId: ctihub.id
    storageAccountResourceId: storage01.id
    tableName: 'ThreatIntelligenceIndicator'
    mappingRuleName: 'ThreatIntelligenceIndicator_mapping'
    }
    dependsOn: [
      flowmasterscript
    ]
}

//The Flow Logs Data Connection
resource flowlogsdataconnection 'Microsoft.Kusto/clusters/databases/dataConnections@2023-08-15' = {
  name: 'adxdc-fw-flowlogs-${environmentid}'
  location: location
  parent: flowdatabase
  kind: 'EventGrid'
  properties: {
    blobStorageEventType: 'Microsoft.Storage.BlobCreated'
    consumerGroup: '$Default'
    dataFormat: 'JSON'
    databaseRouting: 'Multi'
    managedIdentityResourceId: umirid
    eventGridResourceId: adxblobtopic.id
    eventHubResourceId: flowlogshub.id
    mappingRuleName: 'FlowLogFlowEventraw_mapping'
    storageAccountResourceId: storage01.id
    tableName: 'FlowLogFlowEventraw'
    }
    dependsOn: [
      flowmasterscript
    ]
}

//Diagnostic settings for Event Hub
resource adxeventhubdiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'Monitor-eventhub-adx'
  scope: adxeventhubnamespace
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

//This deploys the Primary Private Endpoint.
resource primaryevhnadxprivatendpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: 'pe-evhnadx-${environmentid}'
  location: location
  properties: {
    subnet: {
      id: snetmainid
    }
    privateLinkServiceConnections: [
      {
        name: 'psc-evhnadx-${environmentid}'
        properties: {
          privateLinkServiceId: adxeventhubnamespace.id
          groupIds: [
            'namespace'
          ]
        }
      }
    ]
  }
}

// Create Private DNS Zone Group.
resource evhnadxzonegroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: adxeventhubnamespace.name
  parent: primaryevhnadxprivatendpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: adxeventhubnamespace.name
        properties: {
          privateDnsZoneId: dnsevhn.id
        }
      }
    ]
  }
}

//This deploys the DNS Zone Link.
resource dnsevhn 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.servicebus.windows.net'
  location: 'global'
}

//This deploys the DNS Virtual Network Link.
resource dnsvnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dnsevhn
  name: 'EventHub-${environmentid}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetid
    }
  }
}

//Outputs
output adxname string = kustocluster.name
output adxstrid string = storage01.id
output adxeventgridname string = adxblobtopic.name
output adxstcs string = 'DefaultEndpointsProtocol=https;AccountName=${storage01.name};AccountKey=${listKeys(storage01.id, storage01.apiVersion).keys[0].value}'
