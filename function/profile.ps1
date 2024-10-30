# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper functions, run commands, or specify environment variables
# NOTE: any variables defined that are not environment variables will get reset after the first execution

# Authenticate with Azure PowerShell using MSI.
if ($env:MSI_SECRET) {
    Disable-AzContextAutosave -Scope Process | Out-Null

    # Get the Client ID of the User Assigned Managed Identity from an environment variable
    $clientId = [System.Environment]::GetEnvironmentVariable('AZURE_CLIENT_ID', 'Process')

    # Authenticate with Azure PowerShell using the Managed Identity
    Connect-AzAccount -Identity -AccountId $clientId | Out-Null

    # Set the default subscription
    $subscriptionId = [System.Environment]::GetEnvironmentVariable('AZURE_SUBSCRIPTION_ID', 'Process')
    Set-AzContext -Subscription $subscriptionId | Out-Null

}

Import-Module -Name Az.Accounts -ErrorAction Stop -Force
Import-Module -Name Az.Storage -ErrorAction Stop -Force
Import-Module -Name ExchangeOnlineManagement -ErrorAction Stop -Force

# You can also define functions or aliases that can be referenced in any of your PowerShell functions.