#Import logs
. "$PSScriptRoot\logs.ps1"

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
        $hash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes(""))) -Algorithm SHA256).Hash
        return @{ Hash = $hash; Files = @() }
    }

    foreach ($file in $files) {
        try {
            $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
            $hashString += $hash
        } catch {
            Write-Warning "Failed to hash file: $($file.FullName) - $_"
        }
    }

    $folderHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($hashString))) -Algorithm SHA256).Hash
    return @{ Hash = $folderHash; Files = $files }
}

#Initialized folder with their initial state
foreach ($folder in $config.folders) {
    if (Test-Path $folder) {
        $folderHashInfo = Get-FolderHash -FolderPath $folder
        $monitoredFolders[$folder] = $folderHashInfo
        Write-Host "Monitoring folder: $folder (Hash: $($folderHashInfo.Hash))" -ForegroundColor Cyan
        Write-Log "Added folder: $folder (Hash: $($folderHashInfo.Hash))"
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
                    $newFolderHashInfo = Get-FolderHash -FolderPath $folder
                    if ($monitoredFolders[$folder].Hash -ne $newFolderHashInfo.Hash) {
                        $modificationTime = (Get-Item $folder).LastWriteTime
                        $oldHash = $monitoredFolders[$folder].Hash
                        $username = (Get-ACL $folder).Owner

                        # Compare file lists
                        $oldFiles = $monitoredFolders[$folder].Files
                        $newFiles = $newFolderHashInfo.Files

                        $addedFiles = Compare-Object -ReferenceObject $oldFiles -DifferenceObject $newFiles | Where-Object { $_.SideIndicator -eq "=>" } | ForEach-Object { $_.InputObject.FullName }
                        $removedFiles = Compare-Object -ReferenceObject $oldFiles -DifferenceObject $newFiles | Where-Object { $_.SideIndicator -eq "<=" } | ForEach-Object { $_.InputObject.FullName }
                        $modifiedFiles = Compare-Object -ReferenceObject $oldFiles -DifferenceObject $newFiles | Where-Object { $_.SideIndicator -eq "<=>" } | ForEach-Object { $_.InputObject.FullName }

                        $alertMessage = "Folder changed! $folder || By: $username"
                        if ($addedFiles.Count -gt 0) { $alertMessage += " || Added files: $($addedFiles -join ', ')" }
                        if ($removedFiles.Count -gt 0) { $alertMessage += " || Removed files: $($removedFiles -join ', ')" }
                        if ($modifiedFiles.Count -gt 0) { $alertMessage += " || Modified files: $($modifiedFiles -join ', ')" }

                        Write-Host $alertMessage -ForegroundColor Red
                        Write-Log $alertMessage + " | Detected at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Modified at: $modificationTime | Old Hash: $oldHash | New Hash: $($newFolderHashInfo.Hash) | Added files: $($addedFiles -join ', ') | Removed files: $($removedFiles -join ', ') | Modified files: $($modifiedFiles -join ', ')"

                        # Add the alert to the queue
                        $alert = @{
                            Timestamp = $modificationTime
                            Message = $alertMessage
                        }

                        # Ajouter l'alerte au tableau alerts
                        $alertsFile = "$PSScriptRoot\..\data\alerts.json"
                        $alerts = Get-Content $alertsFile | ConvertFrom-Json
                        $alerts.folders += $alert
                        $alerts | ConvertTo-Json -Depth 10 | Set-Content $alertsFile

                        $monitoredFolders[$folder] = $newFolderHashInfo
                    }
                } catch {
                    Write-Warning "Failed to calculate hash for folder: $folder - $_"
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