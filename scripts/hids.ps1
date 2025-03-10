# Host Intrusion Detection System (HIDS) Script in PowerShell
# Logs the exact modification time from Windows metadata

$hashFile = "hashes.json"
$logFile = "hids.log"

#Function pour les logs
function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $logEntry
    Write-Host $logEntry -ForegroundColor Yellow
}

# File Hash
function Get-FileHashValue {
    param(
        [string]$FilePath
    )
    if (Test-Path $FilePath){
        return (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
    }else {
        return $null
    }
}

# Saving File hashes
function save-Hashes {
    param(
        [hashtable]$Hashes
    )
    $Hashes | ConvertTo-Json -Depth 10 | Set-Content $hashFile
}

#Loading Hashes
function Load-Hashes {
    if (Test-Path $hashFile){
        $data = Get-content $hashFile | ConvertFrom-Json

        $hashes = @{}
        if ($data -is [PSCustomObject]){
            $data.PSObject.Properties | ForEach-Object { $hashes[$_.Name] = $_.Value }
        }else {
            $hashes = $data
        }
        return $hashes
    } else {
        return @{}
    }
}

#Selection of files 
Write-Host "Entrer full paths of files to monitor (come-separated): " -ForegroundColor Cyan
$inputFIles = Read-Host
$files = $inputFiles -split "," | ForEach-Object { $_.Trim() }

# Load or initialize hashes
$hashes = Load-Hashes

#verify if $hashes is an Hashtable
if (-not ($hashes -is [hashtable])) {
    $hashes = @{}
}

#Calculate and store initial hashes
foreach ($files in $files){
    # $hash = Get-FileHashValue -FilePath $file
    if(Test-Path $file) {
        $hash = Get-FileHashValue -FilePath $file
        $hashes[$file] = $hash
        Write-Host "Monitoring: $file (Hash: $hash)" -ForegroundColor Green
        Write-Log "Added file: $file (Hash: $hash)"
    } else {
        Write-Host "WARNING: File Not Found - $file" -ForegroundColor Red
        Write-Log "WARNING: File not Found - $file"
    }
}

# Save initial hashes
save-Hashes -Hashes $hashes

Write-Host "Monitoring started. Press Crtl+C to Stop." -ForegroundColor Cyan
Write-Log "Monitoring Started."

while ($true){
    foreach ($file in $files){
    # $newHash =  Get-FileHashValue -FilePath $file
        if(Test-Path $file ){
            $newHash =  Get-FileHashValue -FilePath $file
            if ($hashes[$file] -ne $newHash) {
                #The exact modiication timestamp
                $modificationTime = (Get-Item $file).LastWriteTime
                $oldHash = $hashes[$file]
                $username = (Get-ACL $file).Owner

                Write-Host "ALERT: File changed! $file" -ForegroundColor Red
                Write-Log "File modified: $file | User: $username | Detected at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Modified at: $modificationTime | Old Hash: $oldHash | New Hash: $newHash"

                # Update hash
                $hashes[$file] = $newHash
                Save-Hashes -Hashes $hashes
            }
        } else {
            Write-Host "WARNING: File Missing - $file" -ForegroundColor Red
            Write-Log "WARNING: File Missing -$file"
        }
    }
    Start-Sleep -Seconds 10
}


