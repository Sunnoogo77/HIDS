

#Monitor FIles

#Import logs
. "$PSScriptRoot\logs.ps1"
. "$PSScriptRoot\alerts.ps1"

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
        # $hash = Get-FileHashValue -FilePath $file
        $monitoredFiles[$file] = (Get-FileHash -Path $file -Algorithm  SHA256).Hash
        Write-Host "Monitoring: $file (Hash: $hash)" -ForegroundColor Cyan
        Write-Log "Added file: $file (Hash: $hash)"
    }else{
        Write-Host "WARNING: File Not Found - $file" -ForegroundColor Red
        Write-Log "WARNING: File not Found - $file"
    }
}

Write-Host "File Monitoring started. Press Crtl+C to Stop." -ForegroundColor Green

#Monitoring function
function Monitor-Files{
    while ($true){
        $keys = $monitoredFiles.Keys | ForEach-Object {$_}

        foreach ($file in $keys){
            if(Test-Path $file){
                $newHash = (Get-FileHash -Path $file -Algorithm SHA256).Hash
                if($monitoredFiles[$file] -ne $newHash){
                    $modificationTime = (Get-Item $file).LastWriteTime
                    $oldHash = $monitoredFiles[$file]
                    $username = (Get-ACL $file).Owner

                    $alertMessage = "File changed! $file | Modified at: $modificationTime | User: $username | Old Hash: $oldHash | New Hash: $newHash"
                    Write-Host "ALERT: File changed! $file | Modified at: $modificationTime || New Hash: $newHash" -ForegroundColor Red
                    Write-Log "File modified: $file | User: $username | Modified at: $modificationTime | Old Hash: $oldHash | New Hash: $newHash"

                    # Add the alert to the queue
                    Add-AlertToQueue -Message $alertMessage

                    # Update hash
                    $monitoredFiles[$file] = $newHash

                    # At the end of the interval, send all alerts in one email
                    Send-BatchedEmailAlerts
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

