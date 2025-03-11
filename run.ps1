Write-Host "========== Démarrage de HISD ==========" -ForegroundColor Cyan

#Charge configurations
. .\scripts\configs.ps1

#Lunch file and folder monitoring
Start-Job -ScriptBlock {. .\scripts\monitor_files.ps1}

#Lunch IPs monitoring
Start-Job -ScriptBlock {. .\scripts\monitor_ips.ps1}

Write-Host "[+]==> HIDS en cour d'exécution... Appuyez Ctrl+C pour arrêter." -ForegroundColor Green