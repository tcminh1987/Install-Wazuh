# Path to the Wazuh agent installer executable on the shared network folder
$installerPath = "\\x.x.x.x\soft\wazuh-agent-installer.msi"

# Read server list from the server-list.txt file
$servers = Get-Content -Path ".\server-list.txt"

# Wazuh variables
$WAZUH_MANAGER = "siem.local"
$WAZUH_REGISTRATION_SERVER = "siem.local"
$WAZUH_AGENT_GROUP = "default"

foreach ($server in $servers) {
    Write-Host "######### Start Upgrading Wazuh agent on $server...#########"
   # Create C:\Temp folder remotely if it doesn't exist
   Write-Host "Create TEMP Folder Wazuh agent on $server..."
   Invoke-Command -ComputerName $server -ScriptBlock {
       $tempPath = "C:\Temp"
       if (!(Test-Path $tempPath)) {
           New-Item -Path $tempPath -ItemType Directory
       }
   }
   Write-Host "Created OK TEMP Folder & Copy config keys Wazuh agent on $server..."
   
# Stop Wazuh service remotely
    Invoke-Command -ComputerName $server -ScriptBlock {
    # Backup old config and keys
    $configPath = "C:\Program Files (x86)\ossec-agent\ossec.conf"
    $keyPath = "C:\Program Files (x86)\ossec-agent\client.keys"
    $backupPath = "C:\Temp"
    if (!(Test-Path $backupPath)) {
        New-Item -Path $backupPath -ItemType Directory
    }
    Copy-Item -Path $configPath -Destination $backupPath -Force
    Copy-Item -Path $keyPath -Destination $backupPath -Force
       # Uninstall old Wazuh agent
       $wazuhProduct = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Wazuh Agent*" }
       if ($wazuhProduct) {
           $uninstallGuid = $wazuhProduct.IdentifyingNumber
           Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $uninstallGuid /qn" -Wait
        Write-Host "Uninstall Wazuh agent on $server..."
       }
   }

   # Copy installer to remote server
   Write-Host "Before copy Wazuh agent on $server..."
   Copy-Item -Path $installerPath -Destination "\\$server\C$\Temp" -Force

   Write-Host "After copy Wazuh agent on $server..."
   # Run installer remotely with variables
   Invoke-Command -ComputerName $server -ScriptBlock {
        $tempPath = "C:\Temp"
        Set-Location $tempPath
        $current = Get-Location
        $joinedPath = Join-Path $current "wazuh-agent-installer.msi"
        Write-Host $joinedPath
        #$absolutePathToMsi = Join-Path $PSScriptRoot "wazuh-agent-installer.msi"
        #Write-Host $absolutePathToMsi
       $installer = "C:\Temp\wazuh-agent-installer.msi"
       $args = @(
           "/S",
           "/WAZUH_MANAGER:$using:WAZUH_MANAGER",
           "/WAZUH_REGISTRATION_SERVER:$using:WAZUH_REGISTRATION_SERVER",
           "/WAZUH_AGENT_GROUP:$using:WAZUH_AGENT_GROUP"
       )
        Write-Host "Installing Wazuh..."
        Start-Process msiexec.exe -Wait -ArgumentList "/I $joinedPath /q WAZUH_MANAGER=siem.local WAZUH_REGISTRATION_SERVER=siem.local WAZUH_AGENT_GROUP=default /quiet"
       #Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $installer $args /quiet /forcerestart" -Wait  
       # Start Wazuh service
       Copy-Item -Path "C:\Temp\ossec.conf" -Destination "C:\Program Files (x86)\ossec-agent\" -Force
       Copy-Item -Path "C:\Temp\client.keys" -Destination "C:\Program Files (x86)\ossec-agent\" -Force
       Write-Host "Stop Wazuh..."
       Stop-Service -Name "Wazuh"
       Start-Sleep -Milliseconds 30
       Write-Host "Staring Wazuh..."
       Start-Service -Name "Wazuh"
       #Write-Host "Restaring Wazuh..."
       #Restart-Service -Name "Wazuh"
   }

   Write-Host "Upgrade completed on $server"
}
