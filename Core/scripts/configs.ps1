param (
    [string]$Action,      # ADD, REMOVE, LIST, SET-INTERVAL
    [string]$Type,        # File, Folder, IP, Interval
    [string]$Value       # The file/folder path or IP address
)

# Load the configuration file
$configFile = "$PSScriptRoot\..\data\config.json"

# Verify if the configuration file exists
if (!(Test-Path $configFile)) {
    Write-Host "Configuration file not found! Creating a blank file..." -ForegroundColor Red
    $defaultConfig = @{
        "interval" = 10
        "files" = @()
        "folders" = @()
        "ips" = @()
    }
    $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content $configFile
}

# Load JSON data
$config = Get-Content $configFile | ConvertFrom-Json

# ACTION: LIST CURRENT ITEMS
if ($Action -eq "LIST") {
    Write-Host "Current Configuration:" -ForegroundColor Cyan
    Write-Host "Scan interval: $($config.interval) seconds" -ForegroundColor Yellow

    if ($config.files.Count -gt 0) {
        Write-Host "Monitored Files:"
        $config.files | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
    } else { Write-Host "No monitored files." -ForegroundColor Red }

    if ($config.folders.Count -gt 0) {
        Write-Host "Monitored Folders:"
        $config.folders | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
    } else { Write-Host "No monitored folders." -ForegroundColor Red }

    if ($config.ips.Count -gt 0) {
        Write-Host "Monitored IPs:"
        $config.ips | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
    } else { Write-Host "No monitored IPs." -ForegroundColor Red }
    exit
}

# ACTION: ADD AN ITEM
if ($Action -eq "ADD") {
    if ($Type -eq "File") {
        if (Test-Path $Value) {
            if ($config.files -notcontains $Value) {
                $config.files += $Value
                Write-Host "File added: $Value" -ForegroundColor Green
            } else {
                Write-Host "This file is already monitored." -ForegroundColor Yellow
            }
        } else {
            Write-Host "File not found: $Value" -ForegroundColor Red
        }
    } elseif ($Type -eq "Folder") {
        if (Test-Path $Value) {
            if ($config.folders -notcontains $Value) {
                $config.folders += $Value
                Write-Host "Folder added: $Value" -ForegroundColor Green
            } else {
                Write-Host "This folder is already monitored." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Folder not found: $Value" -ForegroundColor Red
        }
    } elseif ($Type -eq "IP") {
        if ($Value -match "^(\d{1,3}\.){3}\d{1,3}$") {
            if ($config.ips -notcontains $Value) {
                $config.ips += $Value
                Write-Host "IP added: $Value" -ForegroundColor Green
            } else {
                Write-Host "This IP is already monitored." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Invalid IP address." -ForegroundColor Red
        }
    }
}

# ACTION: REMOVE AN ITEM
if ($Action -eq "REMOVE") {
    if ($Type -eq "File") {
        $config.files = $config.files | Where-Object { $_ -ne $Value }
        Write-Host "File removed: $Value" -ForegroundColor Green
    } elseif ($Type -eq "Folder") {
        $config.folders = $config.folders | Where-Object { $_ -ne $Value }
        Write-Host "Folder removed: $Value" -ForegroundColor Green
    } elseif ($Type -eq "IP") {
        $config.ips = $config.ips | Where-Object { $_ -ne $Value }
        Write-Host "IP removed: $Value" -ForegroundColor Green
    }
}

# ACTION: MODIFY THE MONITORING INTERVAL
if ($Action -eq "SET-INTERVAL") {
    if ($Value -match "^\d+$") {
        $config.interval = [int]$Value
        Write-Host "Interval updated to $Value seconds." -ForegroundColor Green
    } else {
        Write-Host "Invalid interval value." -ForegroundColor Red
    }
}

# Save the updated configuration
$config | ConvertTo-Json -Depth 10 | Set-Content $configFile