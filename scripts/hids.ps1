# Host Intrusion Detection System (HIDS) Script in PowerShell
# Logs the exact modification time from Windows metadata

$hashFile = "hashes.json"
$logFile = "hids.log"

# Function to write logs
function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $logEntry
    Write-Host $logEntry -ForegroundColor Yellow
}

# Function to get file hash
function Get-FileHashValue {
    param (
        [string]$FilePath
    )
    if (Test-Path $FilePath) {
        return (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
    } else {
        return $null
    }
}

# Function to save hashes
function Save-Hashes {
    param (
        [Hashtable]$Hashes
    )
    $Hashes | ConvertTo-Json -Depth 10 | Set-Content $hashFile
}

# Function to load hashes
function Load-Hashes {
    if (Test-Path $hashFile) {
        return Get-Content $hashFile | ConvertFrom-Json
    } else {
        return @{}
    }
}

# User selects files to monitor
Write-Host "Enter full paths of files to monitor (comma-separated): " -ForegroundColor Cyan
$inputFiles = Read-Host
$files = $inputFiles -split "," | ForEach-Object { $_.Trim() }

# Load or initialize hashes
$hashes = Load-Hashes

# Calculate and store initial hashes
foreach ($file in $files) {
    $hash = Get-FileHashValue -FilePath $file
    if ($hash -ne $null) {
        $hashes[$file] = $hash
        Write-Host "Monitoring: $file (Hash: $hash)" -ForegroundColor Green
        Write-Log "Added file: $file (Hash: $hash)"
    } else {
        Write-Host "WARNING: File not found - $file" -ForegroundColor Red
        Write-Log "WARNING: File not found - $file"
    }
}

# Save initial hashes
Save-Hashes -Hashes $hashes

Write-Host "Monitoring started. Press Ctrl+C to stop." -ForegroundColor Cyan
Write-Log "Monitoring started."

while ($true) {
    foreach ($file in $files) {
        $newHash = Get-FileHashValue -FilePath $file
        if ($newHash -ne $null) {
            if ($hashes[$file] -ne $newHash) {
                # Get the exact modification timestamp
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
            Write-Host "WARNING: File missing - $file" -ForegroundColor Red
            Write-Log "WARNING: File missing - $file"
        }
    }
    Start-Sleep -Seconds 10
}
