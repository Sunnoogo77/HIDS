

#
#
#MonitorFOlder :
#Import logs
. "$PSScriptRoot\logs.ps1"
. "$PSScriptRoot\alerts.ps1"  # Import alerts

#Load configurations
$configFile = "$PSScriptRoot\..\data\config.json"

#Verify if the config file exists
if (!(Test-Path $configFile)) {
    Write-Host "Missing Configuration File, creating a new one..." -ForegroundColor Yellow
    exit
}

#Load monitored folders
$config = Get-Content $configFile | ConvertFrom-Json
$monitoredFolders = @{}
$interval = $config.interval

#Verify if there are monitored folders 
if ($config.folders -eq $null -or $config.folders.Count -eq 0) {
    Write-Host "No folders to monitor" -ForegroundColor Yellow
    exit
}

#Function to calculate an hash based on the folder files
function Get-FolderHash {
    param (
        [string]$FolderPath
    )

    if (!(Test-Path $FolderPath)) { return $null }
    $hashString = ""
    $files = Get-ChildItem -Path $FolderPath -Recurse -File | Sort-Object -Property FullName

    if ($files.Count -eq 0) {
        return (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes(""))) -Algorithm SHA256).Hash
    }

    foreach ($file in $files) {
        try {
            $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
            $hashString += $hash
        } catch {
            Write-Warning "Failed to hash file: $($file.FullName)"
        }
    }

    return (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($hashString))) -Algorithm SHA256).Hash
}

#Initialized folder with their initial state
foreach ($folder in $config.folders) {
    if (Test-Path $folder) {
        $folderHash = Get-FolderHash -FolderPath $folder
        $monitoredFolders[$folder] = $folderHash
        Write-Host "Monitoring folder: $folder (Hash: $folderHash)" -ForegroundColor Cyan
        Write-Log "Added folder: $folder (Hash: $folderHash)"
    } else {
        Write-Host "WARNING: Folder Not Found - $folder" -ForegroundColor Red
        Write-Log "WARNING: Folder not Found - $folder"
    }
}

Write-Host "Folder Monitoring started. Press Crtl+C to Stop." -ForegroundColor Green

#Monitoring function
function Monitor-Folders {
    while ($true) {
        $keys = $monitoredFolders.Keys | ForEach-Object { $_ } # Create a copy of the keys

        foreach ($folder in $keys) {
            if (Test-Path $folder) {
                try {
                    $newFolderHash = Get-FolderHash -FolderPath $folder
                    if ($monitoredFolders[$folder] -ne $newFolderHash) {
                        $modificationTime = (Get-Item $folder).LastWriteTime
                        $oldHash = $monitoredFolders[$folder]
                        $username = (Get-ACL $folder).Owner

                        Write-Host "ALERT: Folder changed! $folder" -ForegroundColor Red
                        Write-Log "Folder modified: $folder | User: $username | Detected at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Modified at: $modificationTime | Old Hash: $oldHash | New Hash: $newFolderHash"

                        # Send email alert
                        Send-EmailAlert -Subject "Folder Change Alert" -Body "The folder: $folder was modified at $modificationTime."

                        $monitoredFolders[$folder] = $newFolderHash
                    }
                } catch {
                    Write-Warning "Failed to calculate hash for folder: $folder"
                }
            } else {
                Write-Host "WARNING: Folder Not Found - $folder" -ForegroundColor Red
                Write-Log "WARNING: Folder not Found - $folder"
            }
        }
        Start-Sleep -Seconds $interval
    }
}

#Start monitoring
Monitor-Folders