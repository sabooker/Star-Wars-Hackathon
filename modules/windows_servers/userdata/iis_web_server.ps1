# modules/windows_servers/userdata/iis_web_server.ps1
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

# Enable remote management
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
Set-Service WinRM -StartupType Automatic
Start-Service WinRM

# Configure firewall
New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow

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

# Install IIS and features
Write-Host "Installing IIS..."
Install-WindowsFeature -Name Web-Server,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Health,Web-Http-Logging,Web-Performance,Web-Security,Web-Filtering,Web-App-Dev,Web-Net-Ext45,Web-Asp-Net45,Web-Mgmt-Tools,Web-Mgmt-Console -IncludeManagementTools

# Install .NET Framework
Install-WindowsFeature -Name NET-Framework-45-Core,NET-Framework-45-Features

# Create websites
%{ for site in websites ~}
Write-Host "Creating website: ${site.name}"

# Create directory
New-Item -Path "${site.path}" -ItemType Directory -Force

# Create application pool
New-WebAppPool -Name "${site.name}Pool"
Set-WebAppPoolDefaults -ManagedRuntimeVersion "v4.0"

# Create website
New-WebSite -Name "${site.name}" -Port ${site.port} -PhysicalPath "${site.path}" -ApplicationPool "${site.name}Pool"

# Create default page
$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Imperial ${site.name}</title>
    <style>
        body { background-color: #000; color: #fff; font-family: Arial, sans-serif; }
        .container { text-align: center; padding: 50px; }
        .imperial-logo { font-size: 72px; }
        .server-info { margin-top: 30px; font-size: 18px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="imperial-logo">⚫</div>
        <h1>Imperial ${site.name}</h1>
        <div class="server-info">
            <p>Server: ${instance_name}</p>
            <p>Instance Type: $(Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/instance-type)</p>
            <p>OS: Windows Server $(Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Version)</p>
            <p>IIS Version: $(Get-ItemProperty HKLM:\SOFTWARE\Microsoft\InetStp\ | Select-Object -ExpandProperty VersionString)</p>
        </div>
    </div>
</body>
</html>
"@

Set-Content -Path "${site.path}\index.html" -Value $htmlContent

# Configure SSL if port 443
if (${site.port} -eq 443) {
    # Create self-signed certificate
    $cert = New-SelfSignedCertificate -DnsName "${site.name}.starwars.local" -CertStoreLocation "cert:\LocalMachine\My"
    
    # Bind certificate to site
    New-WebBinding -Name "${site.name}" -Protocol "https" -Port 443
    $sslBinding = Get-WebBinding -Name "${site.name}" -Protocol "https"
    $sslBinding.AddSslCertificate($cert.GetCertHashString(), "my")
}
%{ endfor ~}

# Install URL Rewrite Module (for production use)
Write-Host "Installing URL Rewrite Module..."
$urlRewriteUrl = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
$urlRewritePath = "C:\install\urlrewrite.msi"
New-Item -Path "C:\install" -ItemType Directory -Force
Invoke-WebRequest -Uri $urlRewriteUrl -OutFile $urlRewritePath
Start-Process msiexec.exe -ArgumentList "/i $urlRewritePath /quiet" -Wait

# Install Application Request Routing
Write-Host "Installing Application Request Routing..."
$arrUrl = "https://download.microsoft.com/download/A/A/E/AAE3D7B2-80CF-46C2-BA95-063A627DCD87/ARRv3_Setup_amd64_en-us.exe"
$arrPath = "C:\install\ARRv3_Setup.exe"
Invoke-WebRequest -Uri $arrUrl -OutFile $arrPath
Start-Process $arrPath -ArgumentList "/quiet" -Wait

# Configure IIS Logging
Import-Module WebAdministration
Set-WebConfigurationProperty -Filter system.applicationHost/sites/siteDefaults/logfile -Name directory -Value "C:\inetpub\logs\LogFiles"
Set-WebConfigurationProperty -Filter system.applicationHost/sites/siteDefaults/logfile -Name period -Value Daily

# Install Web Deploy for remote deployment
Write-Host "Installing Web Deploy..."
$webDeployUrl = "https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"
$webDeployPath = "C:\install\WebDeploy.msi"
Invoke-WebRequest -Uri $webDeployUrl -OutFile $webDeployPath
Start-Process msiexec.exe -ArgumentList "/i $webDeployPath /quiet ADDLOCAL=ALL" -Wait

# Create monitoring endpoint
$monitoringContent = @"
<%@ Page Language="C#" %>
<%
Response.ContentType = "application/json";
Response.Write("{");
Response.Write("""status"":""healthy"",");
Response.Write("""server"":""" + Environment.MachineName + """,");
Response.Write("""timestamp"":""" + DateTime.UtcNow.ToString("o") + """,");
Response.Write("""uptime"":""" + TimeSpan.FromMilliseconds(Environment.TickCount).ToString() + """");
Response.Write("}");
%>
"@

# Create monitoring endpoint for each site
%{ for site in websites ~}
New-Item -Path "${site.path}\health" -ItemType Directory -Force
Set-Content -Path "${site.path}\health\check.aspx" -Value $monitoringContent
%{ endfor ~}

# Enable IIS performance counters
Write-Host "Enabling performance counters..."
lodctr /R
lodctr "C:\Windows\System32\w3ctrs.ini"

# Install simulated monitoring agent
$monitoringAgent = @{
    Name = "ImperialMonitor"
    Version = "2.3.1"
    Vendor = "Empire Monitoring Systems"
}

New-Item -Path "C:\Program Files\ImperialMonitor" -ItemType Directory -Force
Set-Content -Path "C:\Program Files\ImperialMonitor\version.txt" -Value $monitoringAgent.Version
Set-Content -Path "C:\Program Files\ImperialMonitor\config.xml" -Value @"
<configuration>
    <product>$($monitoringAgent.Name)</product>
    <version>$($monitoringAgent.Version)</version>
    <vendor>$($monitoringAgent.Vendor)</vendor>
    <monitoring>
        <iis>enabled</iis>
        <performance>enabled</performance>
        <eventlog>enabled</eventlog>
    </monitoring>
</configuration>
"@

# Configure SNMP
Write-Host "Configuring SNMP..."
Install-WindowsFeature -Name SNMP-Service,SNMP-WMI-Provider
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent" -Name "sysContact" -Value "empire-it@starwars.local"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent" -Name "sysLocation" -Value "Death Star Data Center"

# Create scheduled task for monitoring
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -Command 'Write-EventLog -LogName Application -Source ""ImperialMonitor"" -EventId 1000 -Message ""Health check completed""'"
$trigger = New-ScheduledTaskTrigger -Daily -At "3:00AM"
Register-ScheduledTask -TaskName "Imperial IIS Monitor" -Action $action -Trigger $trigger -User "SYSTEM"

# Schedule restart to complete configuration
shutdown /r /t 300 /c "Restarting to complete IIS configuration"

# Write completion flag
Set-Content -Path "C:\deployment_complete.txt" -Value "IIS deployment completed at $(Get-Date)"
</powershell>