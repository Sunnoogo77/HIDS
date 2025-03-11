$hashFile = ".\data\hashes.json"
$ipFile = ".\data\monitored_ips.json"
$configFile = ".\data\config.json"

#Verify if the file exists
if (!(Test-Path ".\data")) { New-Item -ItemType Directory -Path ".\data" | Out-Null }
if (!(Test-Path ".\logs")) { New-Item -ItemType Directory -Path ".\logs" | Out-Null }

#Verify if config exists
# if (Test-Path $configFile){
#     Write-Host "Configuration Already Exists. Do you want to modifiy it ? (O/N)" -ForegroundColor Cyan
#     $response = Read-Host
#     if ($response -match "[Nn]"){
#         Write-Host "Using Existing Configuration" -ForegroundColor Green
#         return
#     }
# }
if (Test-Path $configFile) {
    $config = Get-Content $configFile | ConvertFrom-Json
    if (($config.Files.Count -eq 0) -and ($config.Ips.Count -eq 0)) {
        Write-Host "⚠️ Configuration vide ! Veuillez configurer vos fichiers et IPs." -ForegroundColor Red
    } else {
        Write-Host "Configuration existante trouvée. Voulez-vous la modifier ? (O/N)" -ForegroundColor Cyan
        $response = Read-Host
        if ($response -match "[Nn]") {
            Write-Host "✅ Utilisation de la configuration existante." -ForegroundColor Green
            return
        }
    }
}

#list initializations
$monitoredFiles = @{}
$monitoredFolders = @{}
$monitoredIps = @()
$interval = 5

#Function to print out the selection menu
function Get-MonitoringChoices {
    Write-Host "What do you want to monitor ?" -ForegroundColor Cyan
    Write-Host "1. Files" -ForegroundColor Cyan
    Write-Host "2. Folders" -ForegroundColor Cyan
    Write-Host "3. IPs" -ForegroundColor Cyan
    Write-Host "4. Interval (seconds)" -ForegroundColor Cyan
    Write-Host "Enter your choice (1, 2, 3, 4): " -ForegroundColor Yellow -NoNewline
    $choice = Read-Host
    return $choice -split "," | ForEach-Object { $_.Trim() }
}

#Function to retrieve the files to monitor
# function Get-FilesToMonitor {
#     Write-Host "Enter full paths of files to monitor (comma-separated): " -ForegroundColor Cyan
#     $inputFiles = Read-Host
#     return $inputFiles -split "," | ForEach-Object { $_.Trim() }

#     foreach ($file in $files){
#         if (Test-Path $file){
#             $monitoredFiles[$file] = $null
#         } else {
#             Write-Host "File not found: $file" -ForegroundColor Red
#         }
#     }
# }
function Get-FilesToMonitor {
    Write-Host "`nEntrez les fichiers à surveiller (séparés par des virgules) : " -ForegroundColor Cyan
    $inputFiles = Read-Host
    $files = $inputFiles -split "," | ForEach-Object { $_.Trim() }

    foreach ($file in $files) {
        if (Test-Path $file) {
            $monitoredFiles[$file] = $null
        } else {
            Write-Host "⚠️ Fichier introuvable : $file" -ForegroundColor Red
        }
    }
}

#Function to retrieve the folders to monitor
function Get-FoldersToMonitor {
    Write-Host "nEnter full paths of folders to monitor (comma-separated): " -ForegroundColor Cyan
    $inputFolders = Read-Host
    return $inputFolders -split "," | ForEach-Object { $_.Trim() }

    foreach ($folder in $folders){
        if (Test-Path $folder){
            $monitoredFolders[$folder] = $null
        } else {
            Write-Host "Folder not found: $folder" -ForegroundColor Red
        }
    }
}

#Function to retrieve the IPs to monitor
# function Get-IpsToMonitor {
#     Write-Host "nEnter IPs to monitor (comma-separated): " -ForegroundColor Cyan
#     $inputIps = Read-Host
#     return $inputIps -split "," | ForEach-Object { $_.Trim() }

#     foreach ($ip in $ips){
#         if ($ip -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"){
#             $monitoredIps += $ip
#         } else {
#             Write-Host "Invalid IP: $ip" -ForegroundColor Red
#         }
#     }
# }
function Get-IpsToMonitor {
    Write-Host "`nEntrez les IPs à surveiller (séparées par des virgules) : " -ForegroundColor Cyan
    $inputIps = Read-Host
    $ips = $inputIps -split "," | ForEach-Object { $_.Trim() }

    foreach ($ip in $ips) {
        if ($ip -match "^(\d{1,3}\.){3}\d{1,3}$") {
            $monitoredIps += $ip
        } else {
            Write-Host "⚠️ Adresse IP invalide : $ip" -ForegroundColor Red
        }
    }
}

#Function to retrieve the interval
function Get-Interval {
    Write-Host "Enter the interval in seconds: " -ForegroundColor Cyan
    $interval  = Read-Host
    if ($interval -match "^\d+$"){
        return $interval
    } else {
        Write-Host "Invalid interval: $interval" -ForegroundColor Red
        return 5
    }
}

#Ask user what to monitor
$selectedChoices = Get-MonitoringChoices

#Monitor Entries
foreach ($choice in $selectedChoices){
    switch ($choice){
        1 { $monitoredFiles = Get-FilesToMonitor }
        2 { $monitoredFolders = Get-FoldersToMonitor }
        3 { $monitoredIps = Get-IpsToMonitor }
        4 { $interval = Get-Interval }
        default { Write-Host "Invalid choice: $choice" -ForegroundColor Red }
    }
}

#Save Entries
$hashes = $monitoredFiles + $monitoredFolders
$hashes | ConvertTo-Json -Depth 10 | Set-Content $hashFile
$monitoredIps | ConvertTo-Json -Depth 10 | Set-Content $ipFile

#Save Configuration
$config = @{
    "Files" = $monitoredFiles.Keys
    "Folders" = $monitoredFolders.Keys
    "Ips" = $monitoredIps
    "Interval" = $interval
}
$config | ConvertTo-Json -Depth 10 | Set-Content $configFile

#Print Configuration
Write-Host "Configuration Saved !  Here is what is to monitor :" -ForegroundColor Green

# if($monitoredFiles.Count -gt 0){
#     Write-Host "Files:" -ForegroundColor Cyan
#     $monitoredFiles.Keys | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
# }
# if($monitoredFolders.Count -gt 0){
#     Write-Host "Folders:" -ForegroundColor Cyan
#     $monitoredFolders.Keys | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
# }
# if($monitoredIps.Count -gt 0){
#     Write-Host "IPs:" -ForegroundColor Cyan
#     $monitoredIps | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
# }
# Write-Host "Interval: $interval seconds" -ForegroundColor Cyan
# Write-Host "HIDS Configuration Complete" -ForegroundColor Green