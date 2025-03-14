#Import logs
. "$PSScriptRoot\logs.ps1"

#Load configurations
$configFile = "$PSScriptRoot\..\data\config.json"

#Verify if the configuration file exists
if(!(Test-Path $configFile)){
    Write-Host "Missing Configuration File, creating a new one... | Execute config.ps1 to initialise" -ForegroundColor Yellow
    exit
}

# Load monitored files
$config = Get-Content $configFile | ConvertFrom-Json
$monitoredFiles = @{}
$interval = $config.interval

#Verify if the configuration file is empty
if($null -eq $config.files -or $config.Files.Count -eq 0){
    Write-Host "No files to monitor, please add files to monitor in the configuration file." -ForegroundColor Yellow
    exit
}

#Initialize the monitored files hashes
foreach ($file in $config.files){
    if(Test-Path $file){
        $monitoredFiles[$file] = (Get-FileHash -Path $file -Algorithm  SHA256).Hash
        Write-Host "Monitoring: $file (Hash: $($monitoredFiles[$file]))" -ForegroundColor Cyan
        Write-Log "Added file: $file (Hash: $($monitoredFiles[$file]))"
    }else{
        Write-Host "WARNING: File Not Found - $file" -ForegroundColor Red
        Write-Log "WARNING: File not Found - $file"
    }
}

Write-Host "File Monitoring started. Press Crtl+C to Stop." -ForegroundColor Green

#Monitoring function
function Monitor-Files{
    # $alerts = @() # Initialiser alerts en dehors de la boucle while
    while ($true){
        $keys = $monitoredFiles.Keys | ForEach-Object {$_}

        foreach ($file in $keys){
            if(Test-Path $file){
                $newHash = (Get-FileHash -Path $file -Algorithm SHA256).Hash
                if($monitoredFiles[$file] -ne $newHash){
                    $modificationTime = (Get-Item $file).LastWriteTime
                    $oldHash = $monitoredFiles[$file]
                    $username = (Get-ACL $file).Owner

                    $alertMessage = "File changed! $file || By: $username"
                    Write-Host "ALERT: File changed! $file | Modified at: $modificationTime || New Hash: $newHash" -ForegroundColor Red
                    Write-Log -Category "Files" -Message "File changed! $file | User: $username | Detected at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Modified at: $modificationTime | Old Hash: $oldHash | New Hash: $newHash"

                    # Add the alert to the queue
                    $alert = @{
                        Timestamp = $modificationTime
                        Message = $alertMessage
                    }

                    
                    # Add the alert to the alerts.json file
                    $alertsFile = "$PSScriptRoot\..\data\alerts.json"
                    
                    $alerts = Get-Content $alertsFile | ConvertFrom-Json
                    $alerts.files += $alert
                    $alerts | ConvertTo-Json -Depth 10 | Set-Content $alertsFile

                    # Update hash
                    $monitoredFiles[$file] = $newHash
                }
            }else{
                Write-Host "WARNING: File Missing - $file" -ForegroundColor Red
                Write-Log "WARNING: File Missing -$file"
                $monitoredFiles.Remove($file)
            }
        }
        #Sleep for the interval specified in the configuration file
        Start-Sleep -Seconds $interval
    }
}

#Start monitoring
Monitor-Files
