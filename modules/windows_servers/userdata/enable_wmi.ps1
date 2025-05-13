# modules/windows_servers/userdata/enable_wmi.ps1
# This snippet should be included in all Windows server UserData scripts

# Enable WMI for ServiceNow Discovery
Write-Host "Configuring WMI for ServiceNow Discovery..."

# Enable WMI through Windows Firewall
Enable-NetFirewallRule -DisplayGroup "Windows Management Instrumentation (WMI)"
Enable-NetFirewallRule -DisplayGroup "Remote Administration"
Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing"

# Configure DCOM settings
$dcomPath = "HKLM:\SOFTWARE\Microsoft\Ole"
Set-ItemProperty -Path $dcomPath -Name "EnableDCOMHTTP" -Value 1
Set-ItemProperty -Path $dcomPath -Name "LegacyAuthenticationLevel" -Value 2
Set-ItemProperty -Path $dcomPath -Name "LegacyImpersonationLevel" -Value 3

# Enable Remote Registry
Set-Service -Name RemoteRegistry -StartupType Automatic
Start-Service RemoteRegistry

# Enable WMI Service
Set-Service -Name Winmgmt -StartupType Automatic
Start-Service Winmgmt

# Enable Remote Management
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
Set-Service WinRM -StartupType Automatic
Start-Service WinRM

# Configure Windows Firewall for discovery
netsh advfirewall firewall set rule group="Windows Management Instrumentation (WMI)" new enable=yes
netsh advfirewall firewall set rule group="Remote Administration" new enable=yes
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes
netsh advfirewall firewall set rule group="Remote Service Management" new enable=yes
netsh advfirewall firewall set rule group="Performance Logs and Alerts" new enable=yes
netsh advfirewall firewall set rule group="Remote Event Log Management" new enable=yes
netsh advfirewall firewall set rule group="Remote Scheduled Tasks Management" new enable=yes
netsh advfirewall firewall set rule group="Windows Firewall Remote Management" new enable=yes
netsh advfirewall firewall set rule group="Remote Volume Management" new enable=yes

# Create firewall rules for dynamic RPC if they don't exist
New-NetFirewallRule -DisplayName "ServiceNow Discovery - Dynamic RPC" -Direction Inbound -Protocol TCP -LocalPort 49152-65535 -Action Allow -Profile Domain,Private

# Set WMI namespace security permissions
$namespace = "root\cimv2"
$account = "Everyone"
$accessMask = 0x1 # Enable Account
$aceType = 0x0 # Access Allowed

# Grant WMI permissions
$SDDL = "O:BAG:BAD:(A;CI;CCDCRP;;;BA)(A;CI;CCDCRP;;;NS)(A;CI;CCDCRP;;;LS)(A;CI;CCDCRP;;;AU)"
$converter = new-object system.management.ManagementClass Win32_SecurityDescriptorHelper
$binarySD = $converter.SDDLToBinarySD($SDDL)
$wmi = Get-WmiObject -Namespace "root\cimv2" -Class __SystemSecurity
$wmi.SetSD($binarySD.BinarySD)

Write-Host "WMI configuration completed for ServiceNow Discovery"