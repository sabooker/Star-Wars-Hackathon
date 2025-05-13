# modules/windows_servers/userdata/legacy_app_server.ps1
<powershell>
# Set execution policy
Set-ExecutionPolicy Unrestricted -Force

# Configure Windows
$computerName = "${instance_name}"
Rename-Computer -NewName $computerName -Force

# Set Administrator password
$adminPassword = ConvertTo-SecureString "Emp1reP@ss123!" -AsPlainText -Force
$adminUser = Get-LocalUser -Name "Administrator"
$adminUser | Set-LocalUser -Password $adminPassword

# Create local admin for discovery
$discoveryPassword = ConvertTo-SecureString "Emp1reD1sc0v3ryP@ss!" -AsPlainText -Force
New-LocalUser -Name "empire-discovery-admin" -Password $discoveryPassword -FullName "Empire Discovery Admin" -Description "ServiceNow Discovery Admin"
Add-LocalGroupMember -Group "Administrators" -Member "empire-discovery-admin"

# Enable WMI for ServiceNow Discovery
Write-Host "Configuring WMI for ServiceNow Discovery..."
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

# Enable PowerShell Remoting
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
Set-Service WinRM -StartupType Automatic
Start-Service WinRM

# Configure Windows Firewall for discovery
netsh advfirewall firewall set rule group="Windows Management Instrumentation (WMI)" new enable=yes
netsh advfirewall firewall set rule group="Remote Administration" new enable=yes
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes

# Join domain (if domain controller IP is provided)
$dcIP = "${domain_controller_ip}"
if ($dcIP -ne "") {
    # Set DNS to domain controller
    $networkAdapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    Set-DnsClientServerAddress -InterfaceIndex $networkAdapter.InterfaceIndex -ServerAddresses $dcIP
    
    # Wait for domain to be available
    Start-Sleep -Seconds 60
    
    # Join domain
    $domainName = "starwars.local"
    $domainUser = "STARWARS\darth-vader"
    $domainPassword = ConvertTo-SecureString "Emp1reAdm1n123!" -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($domainUser, $domainPassword)
    
    try {
        Add-Computer -DomainName $domainName -Credential $credential -Force
    } catch {
        Write-Host "Failed to join domain: $_"
    }
}

# Install Java 8 (Legacy version for old app)
Write-Host "Installing Java 8..."
$javaUrl = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=248202_ce59cff5c23f4e2eaf4e778a117d4c5b"
$javaPath = "C:\temp\java8-installer.exe"
New-Item -Path "C:\temp" -ItemType Directory -Force
Invoke-WebRequest -Uri $javaUrl -OutFile $javaPath -UseBasicParsing

# Silent install Java 8
Start-Process -FilePath $javaPath -ArgumentList "/s" -Wait

# Set JAVA_HOME for Java 8
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jre1.8.0_381", [System.EnvironmentVariableTarget]::Machine)
$env:Path += ";C:\Program Files\Java\jre1.8.0_381\bin"

# Install IIS for legacy web components
Write-Host "Installing IIS with legacy support..."
Install-WindowsFeature -Name Web-Server,Web-Common-Http,Web-Static-Content,Web-Dir-Browsing,Web-Http-Errors,Web-Http-Logging,Web-Performance,Web-Security,Web-Filtering,Web-App-Dev,Web-Net-Ext,Web-Net-Ext45,Web-Asp-Net,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Mgmt-Tools,Web-Mgmt-Console

# Install .NET Framework 3.5 (for legacy app compatibility)
Write-Host "Installing .NET Framework 3.5 for legacy support..."
Install-WindowsFeature -Name NET-Framework-Features

# Create legacy application directory
$appPath = "C:\LegacyApps\${app_name}"
New-Item -Path $appPath -ItemType Directory -Force

# Create mock legacy application
$appConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <appSettings>
    <add key="ApplicationName" value="${app_name}" />
    <add key="Version" value="1.2.5" />
    <add key="JavaVersion" value="${java_version}" />
    <add key="LegacyMode" value="true" />
    <add key="DatabaseConnection" value="Server=star-destroyer-sql;Database=EmpireCore;Integrated Security=true;" />
  </appSettings>
  <system.web>
    <compilation targetFramework="4.0" />
    <httpRuntime targetFramework="4.0" />
  </system.web>
</configuration>
"@
Set-Content -Path "$appPath\app.config" -Value $appConfig

# Create legacy batch file launcher (common in old apps)
$batchLauncher = @"
@echo off
echo Starting ${app_name}...
set JAVA_HOME=C:\Program Files\Java\jre1.8.0_381
set PATH=%JAVA_HOME%\bin;%PATH%
java -Xmx1024m -jar "${app_name}.jar"
pause
"@
Set-Content -Path "$appPath\start-app.bat" -Value $batchLauncher

# Create mock JAR file info
$jarInfo = @"
Manifest-Version: 1.0
Main-Class: com.empire.legacy.${app_name}
Created-By: 1.8.0_381 (Oracle Corporation)
Application-Name: ${app_name}
Application-Version: 1.2.5
"@
Set-Content -Path "$appPath\MANIFEST.MF" -Value $jarInfo

# Install legacy runtime components
Write-Host "Installing Visual C++ Redistributables for legacy support..."
# Visual C++ 2010
$vc2010Url = "https://download.microsoft.com/download/C/6/D/C6D0FD4E-9E53-4897-9B91-836EBA2AACD3/vcredist_x64.exe"
$vc2010Path = "C:\temp\vc2010_x64.exe"
Invoke-WebRequest -Uri $vc2010Url -OutFile $vc2010Path -UseBasicParsing
Start-Process -FilePath $vc2010Path -ArgumentList "/q" -Wait

# Visual C++ 2013
$vc2013Url = "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe"
$vc2013Path = "C:\temp\vc2013_x64.exe"
Invoke-WebRequest -Uri $vc2013Url -OutFile $vc2013Path -UseBasicParsing
Start-Process -FilePath $vc2013Path -ArgumentList "/quiet" -Wait

# Configure SNMP
Write-Host "Configuring SNMP..."
Install-WindowsFeature -Name SNMP-Service,SNMP-WMI-Provider
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent" -Name "sysContact" -Value "empire-it@starwars.local"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent" -Name "sysLocation" -Value "Death Star Data Center - Legacy Wing"

# Create Windows Service for legacy app
Write-Host "Creating Windows Service for legacy application..."
$serviceScript = @'
$serviceName = "ImperialLegacyApp"
$displayName = "Imperial Legacy Application Service"
$description = "Legacy Empire Control System"
$binaryPath = "C:\LegacyApps\LegacyEmpireControl\start-app.bat"

if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
    Stop-Service -Name $serviceName -Force
    Remove-Service -Name $serviceName
}

New-Service -Name $serviceName -DisplayName $displayName -Description $description -BinaryPathName $binaryPath -StartupType Automatic
'@
Set-Content -Path "C:\temp\create-service.ps1" -Value $serviceScript

# Note: The service would need a proper executable, this is just for demonstration

# Install outdated security software (for SAM Pro demo)
Write-Host "Installing legacy security software..."
$legacyAV = @{
    Name = "ImperialGuard"
    Version = "2.1.7"  # Intentionally old version
    Vendor = "Empire Security (Discontinued)"
}

New-Item -Path "C:\Program Files\ImperialGuard" -ItemType Directory -Force
Set-Content -Path "C:\Program Files\ImperialGuard\version.txt" -Value $legacyAV.Version
Set-Content -Path "C:\Program Files\ImperialGuard\config.ini" -Value @"
[Settings]
Product=$($legacyAV.Name)
Version=$($legacyAV.Version)
Vendor=$($legacyAV.Vendor)
LastUpdate=2018-05-15
UpdateServer=updates.empire.local
ScanSchedule=Daily
RealTimeProtection=Enabled
Status=OutOfDate
License=Expired
"@

# Create event log entries for legacy app
$logName = "Application"
$sourceName = "${app_name}"
if (![System.Diagnostics.EventLog]::SourceExists($sourceName)) {
    [System.Diagnostics.EventLog]::CreateEventSource($sourceName, $logName)
}
Write-EventLog -LogName $logName -Source $sourceName -EventId 1000 -EntryType Information -Message "${app_name} installed successfully"

# Create scheduled task for legacy maintenance
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -Command 'Write-EventLog -LogName Application -Source ${app_name} -EventId 1001 -Message ""Daily maintenance completed""'"
$trigger = New-ScheduledTaskTrigger -Daily -At "2:00AM"
Register-ScheduledTask -TaskName "${app_name} Maintenance" -Action $action -Trigger $trigger -User "SYSTEM"

# Schedule restart to complete configuration
shutdown /r /t 300 /c "Restarting to complete legacy application setup"

# Write completion flag
Set-Content -Path "C:\deployment_complete.txt" -Value "Legacy application server deployment completed at $(Get-Date)"
Write-EventLog -LogName $logName -Source $sourceName -EventId 9999 -EntryType Information -Message "Deployment completed - System will restart in 5 minutes"
</powershell>