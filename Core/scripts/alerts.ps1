# # Load configuration
# $configFile = "$PSScriptRoot\..\data\config.json"

# if (!(Test-Path $configFile)) {
#     Write-Host "Error: Configuration file not found. Run config.ps1 to set up monitoring." -ForegroundColor Red
#     exit
# }

# $config = Get-Content $configFile | ConvertFrom-Json

# # Email Settings
# $smtpServer = "smtp.gmail.com"
# $smtpPort = 587
# $smtpUser = $config.email.smtpUser
# $emailSender = $config.email.sender
# $emailRecipients = $config.email.recipients

# # Function to display alerts in CLI
# function Display-Alert {
#     param (
#         [string]$Message
#     )
#     $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
#     Write-Host "[$timestamp] ALERT: $Message" -ForegroundColor Red
# }

# # Function to send email alerts
# function Send-EmailAlert {
#     param (
#         [string]$Subject,
#         [string]$Body
#     )

#     # if ($smtpServer -and $smtpUser -and $emailSender -and $emailRecipients.Count -gt 0) {
#     #     try {
#     #         # Ask the user to enter the password
#     #         $smtpPassword = Read-Host -AsSecureString -Prompt "Enter SMTP password"

#     #         $credential = New-Object System.Management.Automation.PSCredential ($smtpUser, $smtpPassword)

#     #         Send-MailMessage -To $emailRecipients -From $emailSender -Subject $Subject -Body $Body -SmtpServer $smtpServer -Port $smtpPort -Credential $credential -UseSsl $true

#     #         Write-Host "Email alert sent: $Subject" -ForegroundColor Green
#     #     } catch {
#     #         Write-Host "Error sending email: $_" -ForegroundColor Red
#     #         Write-Error $_
#     #     }
#     if ($smtpUser -and $emailSender -and $emailRecipients.Count -gt 0) {
#         try {
#             # Ask the user to enter the password
#             $smtpPassword = Read-Host -AsSecureString -Prompt "Enter Gmail password"

#             $credential = New-Object System.Management.Automation.PSCredential ($smtpUser, $smtpPassword)

#             Send-MailMessage -To $emailRecipients -From $emailSender -Subject $Subject -Body $Body -SmtpServer $smtpServer -Port $smtpPort -Credential $credential -UseSsl $true

#             Write-Host "Email alert sent: $Subject" -ForegroundColor Green
#         } catch {
#             Write-Host "Error sending email: $_" -ForegroundColor Red
#             Write-Error $_
#         }

#     } else {
#         Write-Host "Email settings are not properly configured in config.json" -ForegroundColor Yellow
#         Write-Error "Email settings are not properly configured in config.json"
#     }
# }











#-----------------------------------------------------------------

# # Load configuration
# $configFile = "$PSScriptRoot\..\data\config.json"

# if (!(Test-Path $configFile)) {
#     Write-Host "Error: Configuration file not found. Run config.ps1 to set up monitoring." -ForegroundColor Red
#     exit
# }

# $config = Get-Content $configFile | ConvertFrom-Json

# # Email Settings
# $smtpServer = "smtp.gmail.com"
# $smtpPort = 587
# $smtpUser = $config.email.sender
# $emailSender = $config.email.sender
# $emailRecipients = $config.email.recipients

# # Function to display alerts in CLI
# function Display-Alert {
#     param (
#         [string]$Message
#     )
#     $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
#     Write-Host "[$timestamp] ALERT: $Message" -ForegroundColor Red
# }

# # Function to send email alerts
# function Send-EmailAlert {
#     param (
#         [string]$Subject,
#         [string]$Body
#     )

#     if ($smtpUser -and $emailSender -and $emailRecipients.Count -gt 0) {
#         try {
#             # Ask the user to enter the password
#             $smtpPassword = Read-Host -AsSecureString -Prompt "Enter Gmail password"

#             $credential = New-Object System.Management.Automation.PSCredential ($smtpUser, $smtpPassword)

#             # Debugging output
#             Write-Host "SMTP Server: $smtpServer"
#             Write-Host "SMTP Port: $smtpPort"
#             Write-Host "SMTP User: $smtpUser"
#             Write-Host "Email Sender: $emailSender"
#             Write-Host "Email Recipients: $($emailRecipients -join ', ')"

#             # Send-MailMessage -To $emailRecipients -From $emailSender -Subject $Subject -Body $Body -SmtpServer $smtpServer -Port $smtpPort -Credential $credential -UseSsl:$true
#             $mailParams = @{
#                 To = $emailRecipients
#                 From = $emailSender
#                 Subject = $Subject
#                 Body = $Body
#                 SmtpServer = $smtpServer
#                 Port = $smtpPort
#                 Credential = $credential
#                 UseSsl = $true
#             }
#             Send-MailMessage @mailParams

#             Write-Host "Email alert sent: $Subject" -ForegroundColor Green
#         } catch {
#             Write-Host "Error sending email: $_" -ForegroundColor Red
#             Write-Error $_
#             $_ | Format-List -Force # Display detailed error
#         }
#     } else {
#         Write-Host "Email settings are not properly configured in config.json" -ForegroundColor Yellow
#         Write-Error "Email settings are not properly configured in config.json"
#     }
# }



# # Function to send alerts
# Send-EmailAlert -Subject "Test" -Body "This is a test email alert"


#------------------------------------------------------------------------


# # Load the required .NET libraries
# Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\MimeKit.4.11.0\lib\netstandard2.0\MimeKit.dll"
# Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\MailKit.4.11.0\lib\netstandard2.0\MailKit.dll"

# # Load configuration file
# $configFile = "$PSScriptRoot\..\data\config.json"

# if (!(Test-Path $configFile)) {
#     Write-Host "Error: Configuration file not found. Run config.ps1 to set up monitoring." -ForegroundColor Red
#     exit
# }

# $config = Get-Content $configFile | ConvertFrom-Json

# # Email settings
# $smtpServer = $config.email.smtpServer
# $smtpPort = $config.email.smtpPort
# $smtpUser = $config.email.smtpUser
# $emailSender = $config.email.sender
# $emailRecipients = $config.email.recipients

# # Load secure credentials from XML
# $credentialFile = "$PSScriptRoot\..\gmail.xml"
# # $configFile = "$PSScriptRoot\..\data\config.json"
# if (!(Test-Path $credentialFile)) {
#     Write-Host "Error: Credential file not found. Run 'Get-Credential | Export-Clixml' to store credentials." -ForegroundColor Red
#     exit
# }

# # Load secure password from file
# # $securePassword = Get-Content "C:\Users\YourUser\email_password.txt" | ConvertTo-SecureString
# # $credential = New-Object System.Management.Automation.PSCredential ($smtpUser, $securePassword)

# $credential = Import-Clixml -Path $credentialFile
# $smtpPassword = $credential.GetNetworkCredential().Password


# # Function to display alerts in CLI
# function Display-Alert {
#     param (
#         [string]$Message
#     )
#     $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
#     Write-Host "[$timestamp] ALERT: $Message" -ForegroundColor Red
# }

# # Function to send email alerts using MailKit
# function Send-EmailAlert {
#     param (
#         [string]$Subject,
#         [string]$Body
#     )

#     try {
#         # Create email message
#         $message = New-Object MimeKit.MimeMessage
#         $message.From.Add($emailSender)
#         foreach ($recipient in $emailRecipients) {
#             $message.To.Add($recipient)
#         }
#         $message.Subject = $Subject

#         # Email body
#         $bodyBuilder = New-Object MimeKit.BodyBuilder
#         $bodyBuilder.TextBody = $Body
#         $message.Body = $bodyBuilder.ToMessageBody()

#         # SMTP Client
#         $smtp = New-Object MailKit.Net.Smtp.SmtpClient
#         $secureOption = [MailKit.Security.SecureSocketOptions]::StartTl
#         $smtp.Connect($smtpServer, $smtpPort, $secureOption)
#         $smtp.Authenticate($smtpUser,$smtpPassword)
#         # (New-Object System.Net.NetworkCredential("", $securePassword).Password))
#         $smtp.Send($message)
#         $smtp.Disconnect($true)
#         $smtp.Dispose()

#         Write-Host "Email alert sent: $Subject" -ForegroundColor Green
#     } catch {
#         Write-Host "Error sending email: $_" -ForegroundColor Red
#     }
# }

# # Test sending an email alert
# Send-EmailAlert -Subject "Test Alert" -Body "This is a test email from PowerShell using MailKit."


#------------------------------------------------------------------------

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

#Queue for alerts
$alertQueue = @()

#Function to add an alert to the Queue
function Add-AlertToQueue {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $alertQueue += "<tr><td>[$timestamp]</td><td>$Message</td></tr>"
}

# Function to send all queued alerts in a single email
function Send-EmailAlert {
    if ($alertQueueCount -eq 0){
        return 
    }

    #Format the mail body as HTML table
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
        <table>
            <tr>
                <th>Timestamp</th>
                <th>Alert Message</th>
            </tr>
            $($alertQueue -join "`n")
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

        Write-Host " Email alert sent with $( $alertQueue.Count ) alerts." -ForegroundColor Green
    } catch {
        Write-Host "Error sending email: $_" -ForegroundColor Red
    }

    #Clear the queue after sendind the email
    $alertQueueclear()
}

# Test sending an email alert
# Send-EmailAlert -Subject "Test Alert" -Body "This is a test email from PowerShell using Outlook SMTP. Part03"
