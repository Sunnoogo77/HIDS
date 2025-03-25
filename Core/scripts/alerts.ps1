param (
    [int]$Interval = 15 # Intervalle par défaut : 15 secondes
)

# Load required .NET libraries
Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\MimeKit.4.11.0\lib\netstandard2.0\MimeKit.dll"
Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\MailKit.4.11.0\lib\netstandard2.0\MailKit.dll"

# Configuration file path
$configFile = "$PSScriptRoot\..\data\config.json"
$alertsFile = "$PSScriptRoot\..\data\alerts.json"
$statusFile = "$PSScriptRoot\..\data\status.json"

if (!(Test-Path $configFile)) {
    Write-Host "Error: Configuration file not found. Run config.ps1 to set up monitoring." -ForegroundColor Red
    exit
}

$config = Get-Content $configFile | ConvertFrom-Json


$Interval = $config.email.interval

# Email settings for Outlook
$smtpServer = "smtp.office365.com"
$smtpPort = 587
$credentialFile = "$PSScriptRoot\..\outlook.xml"

if (!(Test-Path $credentialFile)) {
    Write-Host "Error: Credential file not found. Run 'Get-Credential | Export-Clixml' to store credentials." -ForegroundColor Red
    exit
}

$credential = Import-Clixml -Path $credentialFile
$smtpUser = $credential.UserName
$smtpPassword = $credential.GetNetworkCredential().Password
$emailSender = $smtpUser
$emailRecipients = $config.email.recipients

$processId = $PID # Get current process ID
$startTime = Get-Date # Get start time
$emailCounter = 0

### 🛠 **1. Vérifier l'intégrité de `alerts.json`**
function Validate-AlertsJson {
    param (
        [string]$FilePath
    )

    if (!(Test-Path $FilePath)) {
        Write-Host "Alert file not found, creating a new one..." -ForegroundColor Yellow
        Reset-AlertsFile -FilePath $FilePath
        return $true
    }

    try {
        $alerts = Get-Content $FilePath | ConvertFrom-Json
        if (-not $alerts -or -not $alerts.PSObject.Properties.Name -contains "files" -or `
            -not $alerts.PSObject.Properties.Name -contains "folders" -or `
            -not $alerts.PSObject.Properties.Name -contains "ips") {
            Write-Host "Invalid structure in alerts.json, resetting file..." -ForegroundColor Red
            Reset-AlertsFile -FilePath $FilePath
            return $false
        }
        return $true
    } catch {
        Write-Host "Error reading alerts.json, resetting file..." -ForegroundColor Red
        Reset-AlertsFile -FilePath $FilePath
        return $false
    }
}

### 🛠 **2. Réinitialiser `alerts.json` si corrompu**
function Reset-AlertsFile {
    param (
        [string]$FilePath
    )

    $emptyAlerts = @{
        files   = @()
        folders = @()
        ips     = @()
    }
    $emptyAlerts | ConvertTo-Json -Depth 10 | Set-Content -Path $FilePath
    Write-Host "alerts.json has been reset." -ForegroundColor Yellow
}

### 🛠 **3. Limiter la taille de `alerts.json`**
function Trim-AlertsFile {
    param (
        [string]$FilePath,
        [int]$MaxEntries = 1000
    )

    if (!(Test-Path $FilePath)) { return }

    $alerts = Get-Content $FilePath | ConvertFrom-Json

    # Vérifier si les alertes dépassent la limite
    if ($alerts.files.Count -gt $MaxEntries) {
        $alerts.files = $alerts.files | Select-Object -Last $MaxEntries
    }
    if ($alerts.folders.Count -gt $MaxEntries) {
        $alerts.folders = $alerts.folders | Select-Object -Last $MaxEntries
    }
    if ($alerts.ips.Count -gt $MaxEntries) {
        $alerts.ips = $alerts.ips | Select-Object -Last $MaxEntries
    }

    $alerts | ConvertTo-Json -Depth 10 | Set-Content -Path $FilePath
}

### 🛠 **4. Fonction pour envoyer les alertes par e-mail**
function Send-BatchedEmailAlerts {
    $global:emailCounter += 1
    
    if (!(Test-Path $alertsFile)) {
        Write-Host "No alerts to send." -ForegroundColor Yellow
        return
    }

    $alerts = Get-Content $alertsFile | ConvertFrom-Json
    if ($null -eq $alerts -or ($alerts.files.Count + $alerts.folders.Count + $alerts.ips.Count) -eq 0) {
        return
    }

    # Format the mail body as HTML table
    $htmlBody = @"
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; }
            table { width: 100%; border-collapse: collapse; }
            th, td { border: 1px solid black; padding: 8px; text-align: left; }
            th { background-color: #f2f2f2; }
        </style>
    </head>
    <body>
        <h2>HIDS Alert Report</h2>
        <p>The following security events were detected:</p>
        <h3>Files:</h3>
        <table>
            <tr>
                <th>Timestamp</th>
                <th>Alert Message</th>
            </tr>
            $(($alerts.files | ForEach-Object { "<tr><td>$($_.Timestamp)</td><td>$($_.Message)</td></tr>" }) -join "`n")
        </table>
        <h3>Folders:</h3>
        <table>
            <tr>
                <th>Timestamp</th>
                <th>Alert Message</th>
            </tr>
            $(($alerts.folders | ForEach-Object { "<tr><td>$($_.Timestamp)</td><td>$($_.Message)</td></tr>" }) -join "`n")
        </table>
        <h3>IPs:</h3>
        <table>
            <tr>
                <th>Timestamp</th>
                <th>Alert Message</th>
            </tr>
            $(($alerts.ips | ForEach-Object { "<tr><td>$($_.Timestamp)</td><td>$($_.Message)</td></tr>" }) -join "`n")
        </table>
        <p><i>This is an automated notification. Please review the details above.</i></p>
    </body>
    </html>
"@

    try {
        $message = New-Object MimeKit.MimeMessage
        $message.From.Add($emailSender)
        foreach ($recipient in $emailRecipients) {
            $message.To.Add($recipient)
        }
        $message.Subject = "HIDS Security Alerts - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

        $bodyBuilder = New-Object MimeKit.BodyBuilder
        $bodyBuilder.HtmlBody = $htmlBody
        $message.Body = $bodyBuilder.ToMessageBody()

        $smtp = New-Object MailKit.Net.Smtp.SmtpClient
        $secureOption = [MailKit.Security.SecureSocketOptions]::StartTls
        $smtp.Connect($smtpServer, $smtpPort, $secureOption)
        $smtp.Authenticate($smtpUser, $smtpPassword)
        [void]$smtp.Send($message)
        $smtp.Disconnect($true)
        $smtp.Dispose()

        Write-Host "Email alert sent with the following details | $($alerts.files.Count) Files Alerts | $($alerts.folders.Count) Folders Alerts | $($alerts.ips.Count) IPs Alerts" -ForegroundColor Green
    } catch {
        Write-Host "Error sending email: $_" -ForegroundColor Red
        Write-Error $_
    }

    Trim-AlertsFile -FilePath $alertsFile

    # Reset the alerts file to an empty state
    Reset-AlertsFile -FilePath $alertsFile
    
    if (!(Test-Path $alertsFile)) {
        $emptyAlerts | ConvertTo-Json -Depth 10 | Set-Content -Path $alertsFile
    }

    # Update status in the central status file
    if(Test-Path $statusFile) {
        $allStatuses = Get-Content $statusFile | ConvertFrom-Json
    } else {
        $allStatuses = @{}
    }
    $allStatuses."alerts" = @{
        PID = $processId
        StartTime = $startTime
        Status = "Running"
        Interval = $Interval
        EmailCounter = $emailCounter
        Emails = @($emailRecipients)
        LastUpdate = (Get-Date).ToString("o")
    }
    $allStatuses | ConvertTo-Json | Set-Content $statusFile
}

### **5. Vérification avant lancement**
Validate-AlertsJson -FilePath $alertsFile

try{
    #Read or initialize status in the central status file
    if (Test-Path $statusFile) {
        $allStatuses = Get-Content $statusFile | ConvertFrom-Json
    } else {
        $allStatuses = @{}
    }
    $allStatuses."alerts" = @{
        PID = $processId
        StartTime = $startTime
        Status = "Running"
        Interval = $Interval
        EmailCounter = $emailCounter
        Emails = @($emailRecipients)
    }
    $allStatuses | ConvertTo-Json | Set-Content $statusFile

    # Start monitoring
    while ($true) {
        try {
            Send-BatchedEmailAlerts
            Start-Sleep -Seconds $Interval
        } catch {
            Write-Host "Error in main loop: $_" -ForegroundColor Red
            Start-Sleep -Seconds 60
        }
    }
} finally {
    # Update status to "Stopped" and clear information on exit
    if(Test-Path $statusFile) {
        $allStatuses = Get-Content $statusFile | ConvertFrom-Json
        $allStatuses."alerts" = @{
            Status = "Stopped"
        }
        $allStatuses | ConvertTo-Json | Set-Content $statusFile
    }
}


# ### **6. Boucle principale**
# while ($true) {
#     try {
#         Send-BatchedEmailAlerts
#         Start-Sleep -Seconds $Interval
#     } catch {
#         Write-Host "Error in main loop: $_" -ForegroundColor Red
#         Start-Sleep -Seconds 60
#     }
# }
