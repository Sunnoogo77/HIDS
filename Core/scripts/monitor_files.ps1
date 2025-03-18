# #Import logs
# . "$PSScriptRoot\logs.ps1"

# #Load configurations
# $configFile = "$PSScriptRoot\..\data\config.json"
# $statusFile =  "$PSScriptRoot\..\data\monitor_files.status"

# #Verify if the configuration file exists
# if(!(Test-Path $configFile)){
#     Write-Host "Missing Configuration File, creating a new one... | Execute config.ps1 to initialise" -ForegroundColor Yellow
#     exit
# }

# # Load monitored files
# $config = Get-Content $configFile | ConvertFrom-Json
# $monitoredFiles = @{}
# $interval = $config.interval
# $processId = $PID
# $startTime = Get-Date

# #Verify if the configuration file is empty
# if($null -eq $config.files -or $config.Files.Count -eq 0){
#     Write-Host "No files to monitor, please add files to monitor in the configuration file." -ForegroundColor Yellow
#     exit
# }

# #Initialize the monitored files hashes
# foreach ($file in $config.files){
#     if(Test-Path $file){
#         $monitoredFiles[$file] = (Get-FileHash -Path $file -Algorithm  SHA256).Hash
#         Write-Host "Monitoring: $file (Hash: $($monitoredFiles[$file]))" -ForegroundColor Cyan
#         Write-Log "Added file: $file (Hash: $($monitoredFiles[$file]))"
#     }else{
#         Write-Host "WARNING: File Not Found - $file" -ForegroundColor Red
#         Write-Log "WARNING: File not Found - $file"
#     }
# }

# Write-Host "File Monitoring started. Press Crtl+C to Stop." -ForegroundColor Green

# #Create status file
# @{
#     processId = $processId
#     startTime = $startTime
#     monitoredFiles = $monitoredFiles.Keys | ForEach-Object {$_}
#     Status = "Running"
#     interval = $interval
# } | ConvertTo-Json | Set-Content $statusFile

# #Monitoring function
# function Monitor-Files{
#     # $alerts = @() # Initialiser alerts en dehors de la boucle while
#     while ($true){
#         try {
#             $keys = $monitoredFiles.Keys | ForEach-Object {$_}

#             foreach ($file in $keys){
#                 if(Test-Path $file){
#                     $newHash = (Get-FileHash -Path $file -Algorithm SHA256).Hash
#                     if($monitoredFiles[$file] -ne $newHash){
#                         $modificationTime = (Get-Item $file).LastWriteTime
#                         $oldHash = $monitoredFiles[$file]
#                         $username = (Get-ACL $file).Owner

#                         $alertMessage = "File changed! $file || By: $username"
#                         Write-Host "ALERT: File changed! $file | Modified at: $modificationTime || New Hash: $newHash" -ForegroundColor Red
#                         Write-Log -Category "Files" -Message "File changed! $file | User: $username | Detected at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Modified at: $modificationTime | Old Hash: $oldHash | New Hash: $newHash"

#                         # Add the alert to the queue
#                         $alert = @{
#                             Timestamp = $modificationTime
#                             Message = $alertMessage
#                         }

                        
#                         # Add the alert to the alerts.json file
#                         $alertsFile = "$PSScriptRoot\..\data\alerts.json"
                        
#                         $alerts = Get-Content $alertsFile | ConvertFrom-Json
#                         $alerts.files += $alert
#                         $alerts | ConvertTo-Json -Depth 10 | Set-Content $alertsFile

#                         # Update hash
#                         $monitoredFiles[$file] = $newHash
#                     }
#                 }else{
#                     Write-Host "WARNING: File Missing - $file" -ForegroundColor Red
#                     Write-Log "WARNING: File Missing -$file"
#                     $monitoredFiles.Remove($file)
#                 }
#             }
#             #Update status file
#             # @{
#             #     processId = $processId
#             #     startTime = $startTime
#             #     monitoredFiles = $monitoredFiles.Keys | ForEach-Object {$_}
#             #     Status = "Running"
#             #     interval = $interval
#             # } | ConvertTo-Json
            
#             #Sleep for the interval specified in the configuration file
#             Start-Sleep -Seconds $interval
#         } catch {
#             Write-Error $_
#             Write-Log -Category "Error" -Message $_.Exception.Message
#         }
#     }
# }

# #Start monitoring
# try {
#     Monitor-Files
# }
# finally {
#     #Remove status file o exit
#     if (Test-Path $statusFile) {
#         Remove-Item $statusFile
#     }
# }




# Import logs
. "$PSScriptRoot\logs.ps1"

# Load configurations
$configFile = "$PSScriptRoot\..\data\config.json"
$statusFile = "$PSScriptRoot\..\data\status.json" # Centralized status file


# Verify if the configuration file exists
if (!(Test-Path $configFile)) {
    Write-Host "Missing Configuration File, creating a new one... | Execute config.ps1 to initialise" -ForegroundColor Yellow
    exit
}

# Load monitored files
$config = Get-Content $configFile | ConvertFrom-Json
$monitoredFiles = @{}
$interval = $config.interval
$processId = $PID # Get current process ID
$startTime = Get-Date # Get start time

# Verify if the configuration file is empty
if ($null -eq $config.files -or $config.Files.Count -eq 0) {
    Write-Host "No files to monitor, please add files to monitor in the configuration file." -ForegroundColor Yellow
    exit
}

# Initialize the monitored files hashes
foreach ($file in $config.files) {
    if (Test-Path $file) {
        $monitoredFiles[$file] = (Get-FileHash -Path $file -Algorithm SHA256).Hash
        Write-Host "Monitoring: $file (Hash: $($monitoredFiles[$file]))" -ForegroundColor Cyan
        Write-Log "Added file: $file (Hash: $($monitoredFiles[$file])) | PID: $processId | Start Time: $startTime"
    } else {
        Write-Host "WARNING: File Not Found - $file" -ForegroundColor Red
        Write-Log "WARNING: File not Found - $file | PID: $processId | Start Time: $startTime"
    }
}

Write-Host "File Monitoring started. Press Crtl+C to Stop." -ForegroundColor Green

# Monitoring function
function Monitor-Files {
    while ($true) {
        try {
            $keys = $monitoredFiles.Keys | ForEach-Object { $_ }

            foreach ($file in $keys) {
                if (Test-Path $file) {
                    $newHash = (Get-FileHash -Path $file -Algorithm SHA256).Hash
                    if ($monitoredFiles[$file] -ne $newHash) {
                        $modificationTime = (Get-Item $file).LastWriteTime
                        $oldHash = $monitoredFiles[$file]
                        $username = (Get-ACL $file).Owner

                        $alertMessage = "File changed! $file || By: $username"
                        Write-Host "ALERT: File changed! $file | Modified at: $modificationTime || New Hash: $newHash" -ForegroundColor Red
                        Write-Log -Category "Files" -Message "File changed! $file | User: $username | Detected at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Modified at: $modificationTime | Old Hash: $oldHash | New Hash: $newHash | PID: $processId | Start Time: $startTime"

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
                } else {
                    Write-Host "WARNING: File Missing - $file" -ForegroundColor Red
                    Write-Log "WARNING: File Missing -$file | PID: $processId | Start Time: $startTime"
                    $monitoredFiles.Remove($file)
                }
            }

            # Update status in the central status file
            $allStatuses = Get-Content $statusFile | ConvertFrom-Json
            $allStatuses."monitor_files" = @{
                PID = $processId
                StartTime = $startTime
                Status = "Running"
                Interval = $interval
                MonitoredCount = $monitoredFiles.Count
            }
            $allStatuses | ConvertTo-Json | Set-Content $statusFile

            # Sleep for the interval specified in the configuration file
            Start-Sleep -Seconds $interval

        } catch {
            Write-Error $_
            Write-Log -Category "Error" -Message $_.Exception.Message
        }
    }
}

# Start monitoring
try {
    # Initialize status in the central status file
    # $allStatuses = @{}
    if (Test-Path $statusFile) {
        $allStatuses = Get-Content $statusFile | ConvertFrom-Json
    } else {
        $allStatuses = @{}
    }
    $allStatuses."monitor_files" = @{
        PID = $processId
        StartTime = $startTime
        Status = "Running"
        interval = $interval
        MonitoredCount = $monitoredFiles.Count
    }
    $allStatuses | ConvertTo-Json | Set-Content $statusFile

    Monitor-Files
} finally {
    # Update status to "Stopped" and clear information on exit
    $allStatuses = Get-Content $statusFile | ConvertFrom-Json
    $allStatuses."monitor_files" = @{
        Status = "Stopped"
    }
    $allStatuses | ConvertTo-Json | Set-Content $statusFile
}