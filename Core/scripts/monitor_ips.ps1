#Import logs
. .\Core\scripts\logs.ps1

#Load configurations
$configFile = ".\Core\data\config.json"

#Verify if the config file exists
if(!(Test-Path $configFile)){
    Write-Host "Missing Configuration File, creating a new one..." -ForegroundColor Yellow
    exit
}

#Load monitored Ips and scan interval
$config = Get-Content $configFile | ConvertFrom-Json
$monitoredIps = @($config.ips)
$interval = $config.interval

#Verify if there are monitored IPs
if($null -eq $monitoredIps -or $monitoredIps.Count -eq 0){
    Write-Host "No IPs to monitor. | Add some in the configuration" -ForegroundColor Yellow
    exit
}

Write-Host "IPS Monitoring started. Press Crtl+C to Stop." -ForegroundColor Green

#Function to retrieve active connections list
function Get-ActiveConnections {
    return Get-NetTCPConnection | Where-Object { $_.State -eq "Established" }
}  


#Monitoring function
function Monitor-Ips {
    $previousState = @{}

    while ($true){
        $activeConnections = Get-ActiveConnections

        foreach($ip in $monitoredIps){
            $isConnected = $activeConnections | Where-Object { $_.RemoteAddress -eq $ip }

            if($isConnected){
                $connection = $isConnected | Select-Object -First 1
                $remotePort = $connection.RemotePort
                $pids = $connection.OwningProcess

                if(-not $previousState.ContainsKey($ip)){
                    Write-Host "Connection to $ip : $remotePort (PID: $pids) established!" -ForegroundColor Green
                    Write-Log "Connection to $ip : $remotePort (PID: $pids) established!"
                    $previousState[$ip] = @{ "Port" = $remotePort; "Pids" = $pids }
                } elseif ($previousState[$ip].Port -ne $remotePort -or $previousState[$ip].Pids -ne $pids) {
                    Write-Host "ALERT: Connection to $ip changed! New Port: $remotePort (PID: $pids)" -ForegroundColor Yellow
                    Write-Log "ALERT: Connection to $ip changed! New Port: $remotePort (PID: $pids)"
                    $previousState[$ip] = @{ "Port" = $remotePort; "Pids" = $pids }
                    <# Action when this condition is true #>
                }
            }else{
                if($previousState.ContainsKey($ip)){
                    Write-Host "ALERT: Connection to $ip lost!" -ForegroundColor Red
                    Write-Log "ALERT: Connection to $ip lost!"
                    $previousState.Remove($ip)
                }
            }
        }

        Start-Sleep -Seconds $interval
    }
}

#Start monitoring
Monitor-Ips