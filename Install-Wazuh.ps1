<#
.SYNOPSIS
Install-Wazuh downloads Wazuh Agent and installs Wazuh
with a configuration file.
.DESCRIPTION
PowerShell script or module to install Wazuh with configuration

Ensure that the ossec-authd daemon is running in the foreground
on your ossec server.

Linux command to find running ossec-authd processes on server...
ps aux | grep ossec-authd | grep -v grep

Linux command to kill running ossec-authd processes
pkill ossec-authd

Linux command to run ossec-authd in foreground
./var/ossec/bin/ossec-authd -f -P

authd password is set in var/ossec/etc/authd.pass
echo ossec>/var/ossec/etc/authd.pass

.PARAMETER path
The path to the working directory.  Default is user Documents.
.PARAMETER agentname
The name of the agent that you are installing.  This is the agent 
name registered with the ossec server
.EXAMPLE
Install-Wazuh -path C:\Users\example\Desktop -agentname 'example'
#>

[CmdletBinding()]

#Establish parameters for path
param (
    [string]$path=[Environment]::GetFolderPath("Desktop")   
)

param (
	[string]$agentname
)

#Test path and create it if required

If(!(test-path $path))
{
	Write-Information -MessageData "Path does not exist.  Creating Path..." -InformationAction Continue;
	New-Item -ItemType Directory -Force -Path $path | Out-Null;
	Write-Information -MessageData "...Complete" -InformationAction Continue
}

Set-Location $path

Invoke-Webrequest -uri https://packages.wazuh.com/3.x/windows/wazuh-agent-3.8.2-1.msi -outfile wazuh-agent-3.8.2-1.msi

Invoke-WebRequest -Uri https://raw.githubusercontent.com/aluminoobie/Install-Wazuh/master/ossec.conf -Outfile ossec.conf

.\wazuh-agent-3.8.2-1.msi /q ADDRESS="172.20.3.35" AUTHD_SERVER="172.20.3.35" PASSWORD="ossec" AGENT_NAME="$agentname" /l installer.log

Copy-Item ossec.conf -Destination 'C:\Program Files (x86)\ossec-agent\'

Restart-Service wazuh

Write-Host "Wazuh Installed!"