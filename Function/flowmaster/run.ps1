# Flowmaster
# 0.0.5

using namespace System.Net

# Input bindings are passed in via param block. new
param($eventGridEvent)

# Get the storage account connection string from application settings
$connectionString = [System.Environment]::GetEnvironmentVariable('StorageConnectionString', 'Process')

# Create a context for Azure Storage operations
$context = New-AzStorageContext -ConnectionString $connectionString

# Get the blob name from the event data
$blobUrl = $eventGridEvent.data.url
$blobName = $blobUrl.Substring($blobUrl.IndexOf('insights-logs-flowlogflowevent/') + 'insights-logs-flowlogflowevent/'.Length)

# Get the blob
$blob = Get-AzStorageBlob -Blob $blobName -Container "insights-logs-flowlogflowevent" -Context $context

# Get the blob content as a string
$blobContent = $blob.ICloudBlob.DownloadText()

# Get the data stream from the input blob
$jsonData = $blobContent | ConvertFrom-Json

# Check if 'records' property exists and is not null
if ($jsonData.PSObject.Properties.Name -contains 'records' -and $null -ne $jsonData.records) {
    # Flatten the 'records' array
    $flattenedData = $jsonData.records[0]

    # Check if 'flowRecords' property exists and is not null
    if ($flattenedData.PSObject.Properties.Name -contains 'flowRecords' -and $null -ne $flattenedData.flowRecords) {
        # Flatten the 'flowRecords' object
        $flattenedData.flowRecords = $flattenedData.flowRecords.flows
    } else {
        Write-Host "No 'flowRecords' property found or 'flowRecords' property is null. Skipping this record."
        return
    }
    
    # Extract the IP addresses from the vnetflow logs
    $ipAddresses = $flattenedData.flowRecords | ForEach-Object {$_.flowGroups | ForEach-Object {$_.flowTuples | ForEach-Object {($_ -split ',')[2]}}}

    # Flatten the IP addresses
    $flattenedIPs = $ipAddresses | Sort-Object | Get-Unique

    # Add the flattened IPs to the flattened data
    $flattenedData | Add-Member -NotePropertyName 'flattenedIPs' -NotePropertyValue $flattenedIPs

    # Remove Unneccessary fields from the flattened data
    $flattenedData.PSObject.Properties.Remove('flowLogResourceID')
    $flattenedData.PSObject.Properties.Remove('flowLogVersion')
    $flattenedData.PSObject.Properties.Remove('operationName')
    $flattenedData.PSObject.Properties.Remove('flowRecords')

    # Convert the flattened data back to JSON
    $flattenedJson = $flattenedData | ConvertTo-Json

    # Write the flattened JSON data to a temporary file
    $tempFile = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $tempFile -Value $flattenedJson

    # Create a new blob in the 'flowmaster' container and write the data from the temporary file to it
    Set-AzStorageBlobContent -File $tempFile -Blob $blobName -Container "flowmasterflowlogs" -Context $context -Force

    # Delete the temporary file
    Remove-Item -Path $tempFile

    # Write the blob name to the function log
    Write-Host "Processed blob '$blobName'"
} else {
    Write-Host "No 'records' property found or 'records' property is null"
}