//This bicep deploys the Entra ID roles for the ADXFlowmaster UMI. 

//Scope
targetScope = 'resourceGroup'

//Variables
var tenantid = tenant().tenantId

//Parameters
param location string
param umirid string
param uminame string
param spnid string
@secure()
param spnsecret string


//Resources

resource entraidexchangescript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'deployscript-ADXFlowmaster-exchange'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umirid}' : {}
    }
  }
  properties: {
    azPowerShellVersion: '12.3.0'
    retentionInterval: 'P1D'
    scriptContent: '''
      param(
        [Parameter(Mandatory=$true)]
        [string]$uminame,
        [Parameter(Mandatory=$true)]
        [string]$spnid,
        [Parameter(Mandatory=$true)]
        [string]$spnsecret,
        [Parameter(Mandatory=$true)]
        [string]$tenantid
      )
      Install-Module -Name "Microsoft.Graph" -Force
      $SecuredPassword = ConvertTo-SecureString -String $spnsecret -AsPlainText -Force
      $ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $spnid, $SecuredPassword
      Connect-MgGraph -TenantId $tenantid -Credential $ClientSecretCredential -NoWelcome
      $MIID = (Get-AzADServicePrincipal -DisplayName $uminame).Id
      $AppRoleID = "dc50a0fb-09a3-484d-be87-e023b12c6440"
      $ResourceID = (Get-MgServicePrincipal -Filter "AppId eq '00000002-0000-0ff1-ce00-000000000000'").Id
      New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $MIID -PrincipalId $MIID -AppRoleId $AppRoleID -ResourceId $ResourceID
    '''
    arguments: '-uminame ${uminame} -spnid ${spnid} -spnsecret ${spnsecret} -tenantId ${tenantid}'
  }
}

resource entraidexchangeadminscript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'deployscript-ADXFlowmaster-exchangeadmin'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umirid}' : {}
    }
  }
  properties: {
    azPowerShellVersion: '12.3.0'
    retentionInterval: 'P1D'
    scriptContent: '''
      param(
        [Parameter(Mandatory=$true)]
        [string]$uminame,
        [Parameter(Mandatory=$true)]
        [string]$spnid,
        [Parameter(Mandatory=$true)]
        [string]$spnsecret,
        [Parameter(Mandatory=$true)]
        [string]$tenantid
      )
      Install-Module -Name "Microsoft.Graph" -Force
      $SecuredPassword = ConvertTo-SecureString -String $spnsecret -AsPlainText -Force
      $ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $spnid, $SecuredPassword
      Connect-MgGraph -TenantId $tenantid -Credential $ClientSecretCredential -NoWelcome
      $RoleID = (Get-MgRoleManagementDirectoryRoleDefinition -Filter "DisplayName eq 'Exchange Administrator'").Id
      $MIID = (Get-AzADServicePrincipal -DisplayName $uminame).Id
      New-MgRoleManagementDirectoryRoleAssignment -PrincipalId $MIID -RoleDefinitionId $RoleID -DirectoryScopeId "/"
    '''
    arguments: '-uminame ${uminame} -spnid ${spnid} -spnsecret ${spnsecret} -tenantId ${tenantid}'
  }
  dependsOn: [
    entraidexchangescript
  ]
}
