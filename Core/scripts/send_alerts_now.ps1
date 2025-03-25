param (
    [bool]$ClearAfterSend = $false  # Par défaut, on ne vide pas les alertes après envoi
)

# Load required .NET libraries
Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\MimeKit.4.11.0\lib\netstandard2.0\MimeKit.dll"
Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\MailKit.4.11.0\lib\netstandard2.0\MailKit.dll"

# Configuration file path
$configFile = "$PSScriptRoot\..\data\config.json"
$alertsFile = "$PSScriptRoot\..\data\alerts.json"

# Vérifier si le fichier de config existe
if (!(Test-Path $configFile)) {
    Write-Host "Error: Configuration file not found. Run config.ps1 to set up monitoring." -ForegroundColor Red
    exit
}

$config = Get-Content $configFile | ConvertFrom-Json

# Email settings
# $smtpServer = $config.email.smtpServer
# $smtpPort = $config.email.smtpPort
# $emailSender = $config.email.sender
# $emailRecipients = $config.email.recipients

$smtpServer = "smtp.office365.com"
$smtpPort = 587
$credentialFile = "$PSScriptRoot\..\outlook.xml"

$credentialFile = "$PSScriptRoot\..\outlook.xml"

if (!(Test-Path $credentialFile)) {
    Write-Host "Error: Credential file not found. Run 'Get-Credential | Export-Clixml' to store credentials." -ForegroundColor Red
    exit
}

# $credential = Import-Clixml -Path $credentialFile
# $smtpUser = $credential.UserName
# $smtpPassword = $credential.GetNetworkCredential().Password

$credential = Import-Clixml -Path $credentialFile
$smtpUser = $credential.UserName
$smtpPassword = $credential.GetNetworkCredential().Password
$emailSender = $smtpUser
$emailRecipients = $config.email.recipients

# Vérifier si le fichier alerts.json existe
if (!(Test-Path $alertsFile)) {
    Write-Host "No alerts to send." -ForegroundColor Yellow
    exit
}

$alerts = Get-Content $alertsFile | ConvertFrom-Json

# Vérifier s'il y a des alertes
if ($alerts -eq $null -or ($alerts.files.Count + $alerts.folders.Count + $alerts.ips.Count) -eq 0) {
    Write-Host "No new alerts to send." -ForegroundColor Yellow
    exit
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
    <h2>HIDS Alert Report (Manual Send)</h2>
    <p>The following security events were detected:</p>
    <h3>Files:</h3>
    <table>
        <tr><th>Timestamp</th><th>Alert Message</th></tr>
        $(($alerts.files | ForEach-Object { "<tr><td>$($_.Timestamp)</td><td>$($_.Message)</td></tr>" }) -join "`n")
    </table>
    <h3>Folders:</h3>
    <table>
        <tr><th>Timestamp</th><th>Alert Message</th></tr>
        $(($alerts.folders | ForEach-Object { "<tr><td>$($_.Timestamp)</td><td>$($_.Message)</td></tr>" }) -join "`n")
    </table>
    <h3>IPs:</h3>
    <table>
        <tr><th>Timestamp</th><th>Alert Message</th></tr>
        $(($alerts.ips | ForEach-Object { "<tr><td>$($_.Timestamp)</td><td>$($_.Message)</td></tr>" }) -join "`n")
    </table>
    <p><i>This is a manually triggered alert notification.</i></p>
</body>
</html>
"@

try {
    # Create email message
    $message = New-Object MimeKit.MimeMessage
    $message.From.Add($emailSender)
    foreach ($recipient in $emailRecipients) {
        $message.To.Add($recipient)
    }
    $message.Subject = "HIDS Security Alerts (Manual) - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    # Email body
    $bodyBuilder = New-Object MimeKit.BodyBuilder
    $bodyBuilder.HtmlBody = $htmlBody
    $message.Body = $bodyBuilder.ToMessageBody()

    # SMTP Client
    $smtp = New-Object MailKit.Net.Smtp.SmtpClient
    $secureOption = [MailKit.Security.SecureSocketOptions]::StartTls
    $smtp.Connect($smtpServer, $smtpPort, $secureOption)
    $smtp.Authenticate($smtpUser, $smtpPassword)
    [void]$smtp.Send($message)
    $smtp.Disconnect($true)
    $smtp.Dispose()

    Write-Host "Manual email alert sent successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error sending manual email alert: $_" -ForegroundColor Red
}

# Option: Vider les alertes après envoi
if ($ClearAfterSend) {
    $emptyAlerts = @{ files = @(); folders = @(); ips = @() }
    $emptyAlerts | ConvertTo-Json -Depth 10 | Set-Content -Path $alertsFile
    Write-Host "Alerts cleared after manual send." -ForegroundColor Yellow
} else {
    Write-Host "Alerts retained after manual send." -ForegroundColor Cyan
}
