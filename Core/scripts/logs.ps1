#log file
$logDirPath = Join-Path $PSScriptRoot "..\logs"
$logTxtFile = Join-Path $logDirPath "hids.log"
$logJsonFile = Join-Path $logDirPath "hids.json"


if (!(Test-Path $logDirPath)) {
    Write-Host "Missing logs directory, creating a new one..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $logDirPath | Out-Null
}

if(!(Test-Path $logTxtFile)){ New-Item -ItemType File -Path $logTxtFile | Out-Null }
if(!(Test-Path $logJsonFile)){ @() | ConvertTo-Json  -Depth 10| Set-Content $logJsonFile }

#Function to write logs
function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = @{
        "timestamp" = $timestamp
        "event" = $Message
    }

    #Write in hids.json
    try{
        $logs = Get-Content $logJsonFile | ConvertFrom-Json
        if ($logs -is [System.Array[]]){
            $logs += $logEntry
        }else{
            $logs = @($logs) + $logEntry
        }
    } catch {
        $logs = @($logEntry)
    }
    $logs | ConvertTo-Json -Depth 10 | Set-Content $logJsonFile

    #Write in hids.log
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $logTxtFile -Value $logEntry
}