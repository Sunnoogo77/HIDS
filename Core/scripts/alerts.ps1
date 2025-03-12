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

# Load configuration
$configFile = "$PSScriptRoot\..\data\config.json"

if (!(Test-Path $configFile)) {
    Write-Host "Error: Configuration file not found. Run config.ps1 to set up monitoring." -ForegroundColor Red
    exit
}

$config = Get-Content $configFile | ConvertFrom-Json

# Email Settings
$smtpServer = "smtp.gmail.com"
$smtpPort = 587
$smtpUser = $config.email.sender
$emailSender = $config.email.sender
$emailRecipients = $config.email.recipients

# Function to display alerts in CLI
function Display-Alert {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] ALERT: $Message" -ForegroundColor Red
}

# Function to send email alerts
function Send-EmailAlert {
    param (
        [string]$Subject,
        [string]$Body
    )

    if ($smtpUser -and $emailSender -and $emailRecipients.Count -gt 0) {
        try {
            # Ask the user to enter the password
            $smtpPassword = Read-Host -AsSecureString -Prompt "Enter Gmail password"

            $credential = New-Object System.Management.Automation.PSCredential ($smtpUser, $smtpPassword)

            # Debugging output
            Write-Host "SMTP Server: $smtpServer"
            Write-Host "SMTP Port: $smtpPort"
            Write-Host "SMTP User: $smtpUser"
            Write-Host "Email Sender: $emailSender"
            Write-Host "Email Recipients: $($emailRecipients -join ', ')"

            Send-MailMessage -To $emailRecipients -From $emailSender -Subject $Subject -Body $Body -SmtpServer $smtpServer -Port $smtpPort -Credential $credential -UseSsl $true

            Write-Host "Email alert sent: $Subject" -ForegroundColor Green
        } catch {
            Write-Host "Error sending email: $_" -ForegroundColor Red
            Write-Error $_
            $_ | Format-List -Force # Display detailed error
        }
    } else {
        Write-Host "Email settings are not properly configured in config.json" -ForegroundColor Yellow
        Write-Error "Email settings are not properly configured in config.json"
    }
}



# Function to send alerts
Send-EmailAlert -Subject "Test" -Body "This is a test email alert"
# Load configuration