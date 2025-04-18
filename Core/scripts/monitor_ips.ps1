# Import logs
. .\Core\scripts\logs.ps1

# Load configurations
$configFile = ".\Core\data\config.json"
$statusFile = ".\Core\data\status.json" # Centralized status file
$alertsFile = ".\Core\data\alerts.json"

# Verify if the config file exists
if (!(Test-Path $configFile)) {
    Write-Host "Missing Configuration File, creating a new one..." -ForegroundColor Yellow
    exit
}

# Load monitored Ips and scan interval
$config = Get-Content $configFile | ConvertFrom-Json
$monitoredIps = @($config.ips)
$interval = $config.interval
$processId = $PID # Get current process ID
$startTime = Get-Date # Get start time

# Verify if there are monitored IPs
if ($null -eq $monitoredIps -or $monitoredIps.Count -eq 0) {
    Write-Host "No IPs to monitor. | Add some in the configuration" -ForegroundColor Yellow
    exit
}

Write-Host "IPS Monitoring started. Press Crtl+C to Stop." -ForegroundColor Green

# Function to retrieve active connections list
function Get-ActiveConnections {
    try {
        return Get-NetTCPConnection | Where-Object { $_.State -eq "Established" }
    } catch {
        Write-Host "Error getting active connections: $_" -ForegroundColor Red
        return @()
    }
}

#Monitoring function
function Monitor-Ips {
    $previousState = @{}

    while ($true) {
        try {
            $activeConnections = Get-ActiveConnections

            foreach ($ip in $monitoredIps) {
                $isConnected = $activeConnections | Where-Object { $_.RemoteAddress -eq $ip }

                if ($isConnected) {
                    $connection = $isConnected | Select-Object -First 1
                    $remotePort = $connection.RemotePort
                    $pids = $connection.OwningProcess
                    $processNames = ($pids | ForEach-Object { (Get-Process -Id $_).ProcessName }) -join ", "

                    if (-not $previousState.ContainsKey($ip)) {
                        Write-Host "Connection to $ip : $remotePort ($processNames) established!" -ForegroundColor Green
                        Write-Log "Connection to $ip : $remotePort ($processNames) established! | PID: $processId | Start Time: $startTime"
                        $previousState[$ip] = @{ "Port" = $remotePort; "Pids" = $pids }
                    } elseif ($previousState[$ip].Port -ne $remotePort -or $previousState[$ip].Pids -ne $pids) {
                        $alertMessage = "ALERT: Connection to $ip changed! New Port: $remotePort ($processNames)"
                        Write-Host $alertMessage -ForegroundColor Yellow
                        Write-Log "$alertMessage | PID: $processId | Start Time: $startTime"
                        $previousState[$ip] = @{ "Port" = $remotePort; "Pids" = $pids }
                    }
                } else {
                    if ($previousState.ContainsKey($ip)) {
                        $alertMessage = "Connection to $ip lost!"
                        Write-Host "ALERT: Connection to $ip lost!" -ForegroundColor Red
                        Write-Log "$alertMessage | PID: $processId | Start Time: $startTime"

                        # Add the alert to the alerts.json file
                        $alerts = Get-Content $alertsFile | ConvertFrom-Json
                        $alerts.ips += @{
                            Timestamp = (Get-Date).ToString("o")
                            Message = $alertMessage
                        }
                        $alerts | ConvertTo-Json -Depth 10 | Set-Content $alertsFile

                        $previousState.Remove($ip)
                    }
                }
            }

            # Update status in the central status file
            if (Test-Path $statusFile) {
                $allStatuses = Get-Content $statusFile | ConvertFrom-Json
            } else {
                $allStatuses = @{}
            }
            $allStatuses."monitor_ips" = @{
                PID = $processId
                StartTime = $startTime
                Status = "Running"
                MonitoredCount = $monitoredIps.Count
                MonitoredIPs = $monitoredIps
                Interval = $interval
            }
            $allStatuses | ConvertTo-Json | Set-Content $statusFile

            Start-Sleep -Seconds $interval
        } catch {
            Write-Error $_
            Write-Log -Category "Error" -Message $_.Exception.Message
        }
    }
}

# Start monitoring
try {
    # Read or initialize status in the central status file
    if (Test-Path $statusFile) {
        $allStatuses = Get-Content $statusFile | ConvertFrom-Json
    } else {
        $allStatuses = @{}
    }
    $allStatuses."monitor_ips" = @{
        PID = $processId
        StartTime = $startTime
        Status = "Running"
        MonitoredCount = $monitoredIps.Count
        MonitoredIPs = $monitoredIps
        Interval = $interval
        LastUpdate = (Get-Date).ToString("o")
    }
    $allStatuses | ConvertTo-Json | Set-Content $statusFile

    Monitor-Ips
} finally {
    # Update status to "Stopped" and clear information on exit
    if (Test-Path $statusFile) {
        $allStatuses = Get-Content $statusFile | ConvertFrom-Json
        $allStatuses."monitor_ips" = @{
            Status = "Stopped"
        }
        $allStatuses | ConvertTo-Json | Set-Content $statusFile
    }
}