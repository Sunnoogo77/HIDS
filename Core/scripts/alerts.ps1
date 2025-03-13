param (
    [int]$Interval = 15 # Intervalle par défaut : 1 minute
)

# Load required .NET libraries
Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\MimeKit.4.11.0\lib\netstandard2.0\MimeKit.dll"
Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\MailKit.4.11.0\lib\netstandard2.0\MailKit.dll"

# Configuration file path
$configFile = "$PSScriptRoot\..\data\config.json"

if (!(Test-Path $configFile)) {
    Write-Host "Error: Configuration file not found. Run config.ps1 to set up monitoring." -ForegroundColor Red
    exit
}

$config = Get-Content $configFile | ConvertFrom-Json

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

function Count-Alerts {
    param (
        [PSCustomObject]$Alerts
    )

    if ($Alerts -eq $null) {
        return 0
    }

    return ($Alerts.files.Count + $Alerts.folders.Count + $Alerts.ips.Count)
}

function Send-BatchedEmailAlerts {
    $alertsFile = "$PSScriptRoot\..\data\alerts.json"
    if (!(Test-Path $alertsFile)) {
        Write-Host "No alerts to send." -ForegroundColor Yellow
        return
    }

    $alerts = Get-Content $alertsFile | ConvertFrom-Json
    if ($alerts -eq $null -or ($alerts.files.Count + $alerts.folders.Count + $alerts.ips.Count) -eq 0) {
        # Write-Host "No alerts to send." -ForegroundColor Yellow
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
        # Create email message
        $message = New-Object MimeKit.MimeMessage
        $message.From.Add($emailSender)
        foreach ($recipient in $emailRecipients) {
            $message.To.Add($recipient)
        }
        $message.Subject = "HIDS Security Alerts - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

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

        Write-Host "Email alert sent with the following details | $($alerts.files.Count) Files Alerts | $($alerts.folders.Count) Folders Alerts | $($alerts.ips.Count) IPs Alerts" -ForegroundColor Green
    } catch {
        Write-Host "Error sending email: $_" -ForegroundColor Red
        Write-Error $_
    }

    # Clear the alerts file after sending the email
    Clear-Content $alertsFile

    # Reset the alerts file to an empty state
    $emptyAlerts = @{
        files = @()
        folders = @()
        ips = @()
    }
    $emptyAlerts | ConvertTo-Json | Set-Content -Path $alertsFile
}

# Main loop
while ($true) {
    try {
        Send-BatchedEmailAlerts
        # Write-Host "Waiting for $Interval seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds $Interval
    } catch {
        Write-Host "Error in main loop: $_" -ForegroundColor Red
        Write-Error $_
        Start-Sleep -Seconds 60 # Retry after 1 minute on error
    }
}