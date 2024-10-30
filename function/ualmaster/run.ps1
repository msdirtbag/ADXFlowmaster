# UALMaster
# 0.0.1

using namespace System.Net

# Input bindings are passed in via param block.
param($Timer)

# Get environment variables
$umicid = [System.Environment]::GetEnvironmentVariable('AZURE_CLIENT_ID', 'Process')
$umitenant = [System.Environment]::GetEnvironmentVariable('TENANT_DOMAIN', 'Process')
$ualmasterfilter = [System.Environment]::GetEnvironmentVariable('UALMASTER_OPERATIONS', 'Process')
$adxstaccountname = [System.Environment]::GetEnvironmentVariable('ADX_STORAGE_ACCOUNT_NAME', 'Process')

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

# Get the current time and adjust for 2 hours behind
$endDate = (Get-Date).AddHours(-2)

# Set the start date to 11 minutes before the end date
$startDate = $endDate.AddMinutes(-11)

# Format the dates
$endDate = $endDate.ToString("yyyy-MM-dd HH:mm:ss")
$startDate = $startDate.ToString("yyyy-MM-dd HH:mm:ss")

# Define maximum number of retries
$maximumRetries = 3
$retryInterval = 10 # seconds

# Create a storage context
$storageContext = New-AzStorageContext -StorageAccountName $adxstaccountname -UseConnectedAccount

# Define the blob name
$timestamp = Get-Date -Format "yyyyMMddHHmmss"

# Create a temporary file
$tempFile = New-TemporaryFile

# Function to process and upload audit logs
Function ProcessAndUploadAuditLogs {
    param (
        $auditLogs,
        $timestamp,
        $storageContext,
        $searchName
    )

    $auditLogs | ForEach-Object -Parallel {
        $record = $_

        $record.AuditData = $record.AuditData | ConvertFrom-Json
        $jsonContent = $record | ConvertTo-Json -Depth 100
        $uniqueId = if ($record.AuditData.Id) { $record.AuditData.Id } else { [guid]::NewGuid().ToString() }
        $outputFilePath = "$($using:timestamp)-UnifiedAuditLog-$uniqueId.json"
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
    } -ThrottleLimit 200
}

# Function to perform the audit log search with retries
Function PerformAuditLogSearch {
    param (
        [datetime]$startDate,
        [datetime]$endDate,
        [string]$ualmasterfilter,
        [int]$retryInterval = 60,
        [int]$maximumRetries = 5
    )

    $searchParams = @{
        StartDate = $startDate
        EndDate = $endDate
        ResultSize = 5000
        SessionCommand = 'ReturnLargeSet'
        HighCompleteness = $false
        Operations = $ualmasterfilter -split ','
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

# Main script execution
$interval = 11 
$currentStart = [datetime]::ParseExact($startDate, "yyyy-MM-dd HH:mm:ss", $null)
$currentEnd = [datetime]::ParseExact($endDate, "yyyy-MM-dd HH:mm:ss", $null)

while ($currentStart -lt $currentEnd) {
    $currentEnd = $currentStart.AddMinutes($interval)
    if ($currentEnd -gt $endDate) {
        $currentEnd = $endDate
    }
    $auditLogs = PerformAuditLogSearch -startDate $currentStart -endDate $currentEnd -ualmasterfilter $ualmasterfilter
    if ($auditLogs) {
        ProcessAndUploadAuditLogs -auditLogs $auditLogs -timestamp $timestamp -storageContext $storageContext -searchName "UALMaster"
    }
    $currentStart = $currentEnd
}

Write-Host "Unified Audit log records have been uploaded to Azure Storage"