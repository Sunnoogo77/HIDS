#Import Alerts monitoring
. .\scripts\alerts.ps1

#Import Files to monitor from JSON
$hashFile = ".\data\hashes.json"
$configFile = ".\data\config.json"
$logFile = ".\logs\hids.log"

#Verify if the file exists
if (!(Test-Path ".\data")) {
    Write-Host "Missing File, creating a new one..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path ".\data" | Out-Null
}

#Verify if the config file exists
if(Test-Path $configFile){
    try {
        $config = Get-Content $configFile | ConvertFrom-Json
        $interval = $config.interval
    }
    catch {
        Write-Host "Error loading configuration file, using default interval (5 Seconds)" -ForegroundColor Red
        $interval = 5
    }
}else {
    Write-Host "Missing Configuration File, using default interval (5 Seconds)" -ForegroundColor Yellow
    $interval = 5
}
#Charge hashes
try {
    $hashes = Get-Content $hashFile | ConvertFrom-Json
}
catch {
    Write-Host "Error loading hashes file, creating a new one..." -ForegroundColor Yellow
    $hashes = @{}
    $hashes | ConvertTo-Json -Depth 10 | Set-Content $hashFile
}


#Function to calculate the hash of a file
function Get-FileHashValue {
    param(
        [string]$FilePath
    )
    if (Test-Path $FilePath){
        try {
            return (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
        }
        catch {
            Write-Host "Error calculating hash for file: $FilePath" -ForegroundColor Red
            return $null
        } 
    }else{
        return $null
    }
}
# The script is using the Start-Job cmdlet to run the monitor_files.ps1 and monitor_ips.ps1 scripts in the background. 
#The monitor_files.ps1 script is responsible for monitoring files and folders, while the monitor_ips.ps1 script is responsible 
#for monitoring IP addresses. The monitor_files.ps1 script loads configurations from the configs.ps1 script, 
#which includes functions to retrieve files, folders, and IPs to monitor. The monitor_files.ps1 script then saves the monitored files, 
#folders, and IPs to JSON files. The monitor_ips.ps1 script also loads configurations from the configs.ps1 script and saves 
#the monitored IPs to a JSON file. The hids.ps1 script imports the alerts.ps1 script, which contains functions for monitoring alerts. 
#It also loads the monitored files from the hashes.json file and initializes the hashes variable with the loaded data. 
#The hids.ps1 script then defines a function to calculate the hash of a file. 
#The script checks if the hashes.json file exists and creates a new one if it doesn't. 
#It then loads the monitored files from the hashes.json file and initializes the hashes variable with the loaded data. 
#The script also defines a function to calculate the hash of a file. The script is using the Start-Job cmdlet to run the 
#monitor_files.ps1 and monitor_ips.ps1 scripts in the background. The monitor_files.ps1 script is responsible for monitoring files and folders, 
#while the monitor_ips.ps1 script is responsible for monitoring IP addresses. The monitor_files.ps1 script loads configurations 
#from the configs.ps1 script, which includes functions to retrieve files, folders, and IPs to monitor. The monitor_files.ps1 script 
#then saves the monitored files, folders, and IPs to JSON files. The monitor_ips.ps1 script also loads configurations from the configs.ps1 
#script and saves the monitored IPs to a JSON file. The hids.ps1 script imports the alerts.ps1 script, which contains functions for monitoring alerts. 
#It also loads the monitored files from the hashes.json file and initializes the hashes variable with the loaded data. 
#The hids.ps1 script then defines a function to calculate the hash of a file. 
#The script checks if the hashes.json file exists and creates a new one if it doesn't. 
#It then loads the monitored files from the hashes.json file and initializes the hashes variable with the loaded data. 
#The script also defines a function to calculate the hash of a file. The script is using the Start-Job cmdlet to run the monitor

#Monitoring
Write-Host " Files Monitoring Activated... (Interval: $($interval) seconds)" -ForegroundColor Green

while ($true){
    foreach ($file in $hashes.Keys){
        $newHash  = Get-FileHashValue -FilePath $file
        if ($null -ne $newHash  -and $hashes[$file] -ne $newHash){
            $modificationTime = (Get-Item $file).LastWriteTime
            $username = (Get-ACL $file).Owner
            $oldHash = $hashes[$file]
            
            #Log + Sending ALert
            Write-Log "File: $file has been modified | By: $username | Time: $modificationTime | Old Hash: $oldHash |New Hash: $newHash  "
            Send-Alert -FilePath $file -Username $username -ModificationTime $modificationTime -OldHash $oldHash -NewHash $newHash 
            
            #Hash Update
            $hashes[$file] = $newHash 
            $hashes | ConvertTo-Json -Depth 10 | Set-Content $hashFile
        }
    }
    Start-Sleep -Seconds $interval
}