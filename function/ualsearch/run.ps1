# UALSearch Function App
# 0.0.1

using namespace System.Net

# Input bindings are passed in via param block.
param($Request)

# Extract parameters from the request body
$tenantId = $Request.Body.TenantId
$startDate = $Request.Body.StartDate
$endDate = $Request.Body.EndDate
$UserIds = $Request.Body.UserIds
$Operations = $Request.Body.Operations
$IPAddress = $Request.Body.IPAddress

if ([string]::IsNullOrEmpty($tenantId)) {
    $Body = "TenantId is a required parameter."
    $Result = [HttpStatusCode]::BadRequest
}
else {
    $Body = "The UALSearch function started successfully."
    $Result = [HttpStatusCode]::OK
}

# Write the Request parameters to the log
Write-Host "Request parameters:"
Write-Host "Tenant ID: $TenantId"
Write-Host "Start Date: $startDate"
Write-Host "End Date: $endDate"
Write-Host "User IDs: $UserIds"
Write-Host "Operations: $Operations"
Write-Host "IP Address: $IPAddress"

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $Result
    Body = $Body
})

# Get environment variables
$umicid = [System.Environment]::GetEnvironmentVariable('AZURE_CLIENT_ID', 'Process')
$umitenant = [System.Environment]::GetEnvironmentVariable('TENANT_DOMAIN', 'Process')

try {
    # Connect to Exchange Online
    Connect-ExchangeOnline -ManagedIdentity -Organization $umitenant -ManagedIdentityAccountId $umicid -ShowBanner:$false | Out-Null
    Write-Host "Successfully connected to Exchange Online."
} catch {
    Write-Host "Failed to connect to Exchange Online."
    Write-Host "Error Message: $($_.Exception.Message)"
    Write-Host "Error Type: $($_.Exception.GetType().FullName)"
    Write-Host "Inner Exception: $($_.Exception.InnerException)"
    exit
}

# Set default values for startDate and endDate if not provided or if they are empty strings
$startDate = if ($null -eq $startDate -or $startDate -eq '') { (Get-Date).AddDays(-30).ToString("yyyy-MM-dd") } else { $startDate }
$endDate = if ($null -eq $endDate -or $endDate -eq '') { (Get-Date).ToString("yyyy-MM-dd") } else { $endDate }

# Now, safely parse startDate and endDate as DateTime objects using the specific format
try {
    $parsedStartDate = [DateTime]::ParseExact($startDate, "yyyy-MM-dd", $null)
    $parsedEndDate = [DateTime]::ParseExact($endDate, "yyyy-MM-dd", $null)
    Write-Host "Dates parsed successfully."
} catch {
    Write-Host "Error parsing dates. Please ensure they are in the format 'yyyy-MM-dd'."
    exit 1
}

# Function to perform the audit log search with retries
Function PerformAuditLogSearch {
    param (
        [datetime]$startDate,
        [datetime]$endDate,
        [int]$retryInterval = 60,
        [int]$maximumRetries = 5,
        [string]$Operations = $null,
        [string]$IPAddress = $null
    )

    $searchParams = @{
        StartDate = $startDate
        EndDate = $endDate
        ResultSize = 5000
        SessionCommand = 'ReturnLargeSet'
        HighCompleteness = $false
    }

    if ($Operations) {
        $searchParams['Operations'] = $Operations -split ','
    }

    if ($IPAddress) {
        $searchParams['IPAddress'] = $IPAddress -split ','
    }

    $retryCount = 0
    $interval = 1440
    $currentStart = $startDate

    while ($currentStart -lt $endDate) {
        $currentEnd = $currentStart.AddMinutes($interval)
        if ($currentEnd -gt $endDate) {
            $currentEnd = $endDate
        }
        $amountResults = Search-UnifiedAuditLog -StartDate $currentStart -EndDate $currentEnd @searchParams -ResultSize 1 | Select-Object -First 1 -ExpandProperty ResultCount
        if ($null -eq $amountResults) {
            Write-Host "No audit logs between $($currentStart.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssK")) and $($currentEnd.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssK"))"
            $currentStart = $currentEnd
        } elseif ($amountResults -gt 5000) {
            while ($amountResults -gt 5000) {
                Write-Host "$amountResults entries between $($currentStart.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssK")) and $($currentEnd.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssK")) exceeding the maximum of 5000 entries"
                $interval = [math]::Round(($interval / (($amountResults / 5000) * 1.25)), 2)
                $currentEnd = $currentStart.AddMinutes($interval)
                Write-Host "Temporary lowering time interval to $interval minutes"
                $amountResults = Search-UnifiedAuditLog -StartDate $currentStart -EndDate $currentEnd @searchParams -ResultSize 1 | Select-Object -First 1 -ExpandProperty ResultCount
            }
        } else {
            $searchParams['StartDate'] = $currentStart
            $searchParams['EndDate'] = $currentEnd
            do {
                try {
                    Write-Host "Starting audit log query from $currentStart to $currentEnd..."
                    $auditLogs = Search-UnifiedAuditLog @searchParams
                    Write-Host "Audit log query started successfully."
                    return $auditLogs
                } catch {
                    Write-Host "Failed to start audit log query: $($_.Exception.Message)"
                    $retryCount++
                    if ($retryCount -le $maximumRetries) {
                        Write-Host "Retrying in $retryInterval seconds..."
                        Start-Sleep -Seconds $retryInterval
                    } else {
                        Write-Host "Maximum retries reached. Reducing time range and retrying..."
                        $currentEnd = $currentStart.AddMinutes($interval / 2)
                        $retryCount = 0
                    }
                }
            } while ($retryCount -le $maximumRetries)
            $currentStart = $currentEnd
        }
    }
    return $null
}

# Function to download audit log results
Function DownloadUAL {
    param (
        $auditLogs
    )

    $adxstaccountname = [System.Environment]::GetEnvironmentVariable('ADX_STORAGE_ACCOUNT_NAME', 'Process')
    $storageContext = New-AzStorageContext -StorageAccountName $adxstaccountname -UseConnectedAccount
    $retryInterval = 60
    $maximumRetries = 5

    $scriptBlock = {
        $record = $_

        $record.AuditData = $record.AuditData | ConvertFrom-Json
        $jsonContent = $record | ConvertTo-Json -Depth 100
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $uniqueId = if ($record.AuditData.Id) { $record.AuditData.Id } else { [guid]::NewGuid().ToString() }
        $outputFilePath = "$timestamp-UnifiedAuditLog-$uniqueId.json"
        $tempFile = [System.IO.Path]::GetTempFileName()
        $jsonContent | Out-File -FilePath $tempFile -Force

        $retryCount = 0
        do {
            try {
                Set-AzStorageBlobContent -Blob $outputFilePath -Container "ual" -Context $using:storageContext -File $tempFile -Force | Out-Null
                break
            } catch {
                Write-Host "Failed to upload blob: $($_.Exception.Message)"
                $retryCount++
                if ($retryCount -le $using:maximumRetries) {
                    Write-Host "Retrying in $($using:retryInterval) seconds..."
                    Start-Sleep -Seconds $using:retryInterval
                } else {
                    Write-Host "Failed to upload blob after $($using:maximumRetries) attempts."
                    break
                }
            }
        } while ($retryCount -le $using:maximumRetries)
        Remove-Item -Path $tempFile -Force
    }
    if ($auditLogs) {
        $auditLogs | ForEach-Object -Parallel $scriptBlock -ThrottleLimit 200
    } else {
        Write-Host "No records found for the specified audit log query."
    }
    Write-Host "Audit log records have been uploaded to Azure Storage."
}

# Main script execution
$startDate = $parsedStartDate
$endDate = $parsedEndDate

while ($startDate -lt $endDate) {
    $auditLogs = PerformAuditLogSearch -startDate $startDate -endDate $endDate -Operations $Operations -IPAddress $IPAddress
    if ($null -ne $auditLogs) {
        try {
            Write-Host "Downloading audit log results..."
            DownloadUAL $auditLogs "UALSearch"
            Write-Host "Audit log results downloaded successfully."
        } catch {
            Write-Host "An error occurred while downloading audit log results: $($_.Exception.Message)"
            Write-Host "Skipping to the next operation..."
        }
    }
    $startDate = $startDate.AddDays(1)
}

# Return a 200 response
$body = @{
    status  = "Success"
    message = "UALSearch completed successfully"
}
$response = @{
    StatusCode = 200
    Body = $body | ConvertTo-Json
    Headers = @{
        'Content-Type' = 'application/json'
    }
}
return $response