# modules/windows_servers/userdata/sql_server.ps1
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

# Configure firewall for SQL Server
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
New-NetFirewallRule -DisplayName "SQL Server Browser" -Direction Inbound -Protocol UDP -LocalPort 1434 -Action Allow

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

# Install SQL Server features (SQL Server ${sql_version})
Write-Host "Installing SQL Server ${sql_version}..."

# Create SQL Server service accounts
$sqlServicePassword = ConvertTo-SecureString "SqlS3rv1c3P@ss!" -AsPlainText -Force
New-LocalUser -Name "svc-sql-engine" -Password $sqlServicePassword -FullName "SQL Server Engine Service" -Description "SQL Server Database Engine Service Account"
New-LocalUser -Name "svc-sql-agent" -Password $sqlServicePassword -FullName "SQL Server Agent Service" -Description "SQL Server Agent Service Account"

# Add service accounts to appropriate groups
Add-LocalGroupMember -Group "Users" -Member "svc-sql-engine"
Add-LocalGroupMember -Group "Users" -Member "svc-sql-agent"

# Download and install SQL Server
# Note: In production, you would download from a secure S3 bucket or use AWS Systems Manager
Write-Host "SQL Server installation would be performed here..."

# For demo purposes, create mock databases
$mockDatabases = @(
    %{ for db in databases ~}
    @{Name="${db}"; Size="10GB"},
    %{ endfor ~}
)

# Create SQL data directories
New-Item -Path "D:\SQLData" -ItemType Directory -Force
New-Item -Path "E:\SQLLogs" -ItemType Directory -Force
New-Item -Path "F:\SQLTempDB" -ItemType Directory -Force

# Set proper permissions on SQL directories
$acl = Get-Acl "D:\SQLData"
$permission = "BUILTIN\Users","FullControl","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl "D:\SQLData" $acl

# Install IIS for SQL Server Reporting Services
Install-WindowsFeature -Name Web-Server,Web-Mgmt-Tools,Web-Asp-Net45

# Install .NET Framework
Install-WindowsFeature -Name NET-Framework-45-Core,NET-Framework-45-Features

# Create sample databases info file (for discovery demonstration)
$dbInfo = @"
SQL Server Instance: ${instance_name}
Version: SQL Server ${sql_version}
Databases:
%{ for db in databases ~}
- ${db}
%{ endfor ~}
"@

Set-Content -Path "C:\sql_server_info.txt" -Value $dbInfo

# Install security software simulation
$securitySoftware = @{
    Name = "ImperialShield"
    Version = "6.0.1"
    Vendor = "Empire Security Systems"
}

New-Item -Path "C:\Program Files\ImperialShield" -ItemType Directory -Force
Set-Content -Path "C:\Program Files\ImperialShield\version.txt" -Value $securitySoftware.Version
Set-Content -Path "C:\Program Files\ImperialShield\config.xml" -Value @"
<configuration>
    <product>$($securitySoftware.Name)</product>
    <version>$($securitySoftware.Version)</version>
    <vendor>$($securitySoftware.Vendor)</vendor>
    <features>
        <antivirus>enabled</antivirus>
        <firewall>enabled</firewall>
        <intrusion_detection>enabled</intrusion_detection>
    </features>
</configuration>
"@

# Create scheduled task to simulate security software running
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -Command 'Write-Host ImperialShield Active'"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "ImperialShield Monitor" -Action $action -Trigger $trigger -User "SYSTEM"

# Enable Windows features for monitoring
Install-WindowsFeature -Name SNMP-Service,SNMP-WMI-Provider

# Configure SNMP
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent" -Name "sysContact" -Value "empire-it@starwars.local"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent" -Name "sysLocation" -Value "Death Star Data Center"

# Create performance counter for monitoring
$categoryName = "Imperial Database Performance"
$counterName = "Query Execution Time"
if (-not [System.Diagnostics.PerformanceCounterCategory]::Exists($categoryName)) {
    $counterData = New-Object System.Diagnostics.CounterCreationDataCollection
    $counter = New-Object System.Diagnostics.CounterCreationData
    $counter.CounterName = $counterName
    $counter.CounterHelp = "Average query execution time in milliseconds"
    $counter.CounterType = [System.Diagnostics.PerformanceCounterType]::AverageTimer32
    $counterData.Add($counter)
    
    [System.Diagnostics.PerformanceCounterCategory]::Create($categoryName, "SQL Server Performance Metrics", $counterData)
}

# Schedule restart after all configurations
shutdown /r /t 300 /c "Restarting to complete SQL Server configuration"

# Write completion flag
Set-Content -Path "C:\deployment_complete.txt" -Value "SQL Server deployment completed at $(Get-Date)"
</powershell>