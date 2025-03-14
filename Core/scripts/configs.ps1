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
        "email" = @{
            "smtpServer" = "smtp.office365.com"
            "smtpPort" = 587
            "sender" = ""
            "recipients" = @()
            "emailInterval" = 300
        }
    }
    $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content $configFile
}

# Load JSON data
$config = Get-Content $configFile | ConvertFrom-Json

# ACTION: LIST CURRENT ITEMS
if ($Action -eq "LIST") {
    Write-Host "Current Configuration:" -ForegroundColor Cyan
    Write-Host "Scan interval: $($config.interval) seconds" -ForegroundColor Yellow
    Write-Host "`nEmail Settings:" -ForegroundColor Cyan
    Write-Host "SMTP Server: $($config.email.smtpServer)" -ForegroundColor Yellow
    Write-Host "SMTP Port: $($config.email.smtpPort)" -ForegroundColor Yellow
    Write-Host "Sender Email: $($config.email.sender)" -ForegroundColor Yellow
    Write-Host "Recipients: $($config.email.recipients -join ', ')" -ForegroundColor Yellow
    Write-Host "Email Interval: $($config.email.emailInterval) seconds" -ForegroundColor Yellow

    if ($config.files.Count -gt 0) {
        Write-Host "`nMonitored Files:"
        $config.files | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
    } else { Write-Host "No monitored files." -ForegroundColor Red }

    if ($config.folders.Count -gt 0) {
        Write-Host "`nMonitored Folders:"
        $config.folders | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
    } else { Write-Host "No monitored folders." -ForegroundColor Red }

    if ($config.ips.Count -gt 0) {
        Write-Host "`nMonitored IPs:"
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

# ACTION: SET EMAIL CONFIGURATION (ADD/REMOVE RECIPIENTS)
if ($Action -eq "SET-EMAIL") {
    if ($Type -eq "ADD-Recipient") {
        $emails = $Value -split "," | ForEach-Object { $_.Trim() }

        foreach ($email in $emails) {
            if ($email -match "^\S+@\S+\.\S+$") {
                if ($config.email.recipients -notcontains $email) {
                    $config.email.recipients += $email
                    Write-Host "Recipient added: $email" -ForegroundColor Green
                } else {
                    Write-Host "Recipient already exists: $email" -ForegroundColor Yellow
                }
            } else {
                Write-Host "Invalid email format: $email" -ForegroundColor Red
            }
        }
    }
    elseif ($Type -eq "REMOVE-Recipient") {
        if ($config.email.recipients -contains $Value) {
            $config.email.recipients = $config.email.recipients | Where-Object { $_ -ne $Value }
            Write-Host "Recipient removed: $Value" -ForegroundColor Green
        } else {
            Write-Host "Recipient not found: $Value" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Invalid TYPE value. Use ADD-Recipient or REMOVE-Recipient" -ForegroundColor Red
    }
}

#ACTION: MODIFY THE EMAIL SENDING INTERVAL
if($Action -eq "SET-EMAIL-INTERVAL"){
    if($Value -match "^\d+$"){
        $config.email.interval = [int]$Value
        Write-Host "Email interval updated to $Value seconds." -ForegroundColor Green
    }else{
        Write-Host "Invalid interval value." -ForegroundColor Red
    }
}

# Save the updated configuration
$config | ConvertTo-Json -Depth 10 | Set-Content $configFile
