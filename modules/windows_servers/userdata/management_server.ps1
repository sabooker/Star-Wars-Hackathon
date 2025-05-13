# modules/windows_servers/userdata/management_server.ps1
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

# Install management features
Write-Host "Installing management features..."
Install-WindowsFeature -Name RSAT-AD-PowerShell
Install-WindowsFeature -Name RSAT-AD-AdminCenter
Install-WindowsFeature -Name RSAT-ADDS-Tools
Install-WindowsFeature -Name RSAT-DNS-Server
Install-WindowsFeature -Name RSAT-DHCP
Install-WindowsFeature -Name RSAT-RemoteAccess
Install-WindowsFeature -Name RSAT-File-Services
Install-WindowsFeature -Name GPMC
Install-WindowsFeature -Name UpdateServices-Services,UpdateServices-WidDB,UpdateServices-RSAT,UpdateServices-API

# Configure management tools based on the list
$managementTools = @()
%{ for tool in management_tools ~}
$managementTools += "${tool}"
%{ endfor ~}

# Install SCCM Prerequisites
if ($managementTools -contains "SCCM") {
    Write-Host "Installing SCCM prerequisites..."
    
    # Install IIS with required features for SCCM
    Install-WindowsFeature -Name Web-Server,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Http-Redirect,Web-App-Dev,Web-Net-Ext,Web-Net-Ext45,Web-Asp-Net,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Health,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Performance,Web-Stat-Compression,Web-Dyn-Compression,Web-Security,Web-Filtering,Web-Basic-Auth,Web-Windows-Auth,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,Web-Lgcy-Mgmt-Console,Web-Lgcy-Scripting,Web-WMI,Web-Scripting-Tools,Web-Mgmt-Service
    
    # Install .NET Framework features
    Install-WindowsFeature -Name NET-Framework-Features,NET-Framework-45-Features,NET-WCF-Services45,NET-WCF-HTTP-Activation45,NET-WCF-TCP-PortSharing45
    
    # Install Windows ADK features
    Install-WindowsFeature -Name RDC
    
    # Install SQL Server Native Client (mock for demo)
    Write-Host "SQL Server Native Client would be installed here..."
    
    # Create SCCM directories
    $sccmDirs = @(
        "C:\SCCM",
        "C:\SCCM\ContentLibrary",
        "C:\SCCM\ClientCache",
        "C:\SCCM\Logs",
        "C:\SCCM\Reports"
    )
    
    foreach ($dir in $sccmDirs) {
        New-Item -Path $dir -ItemType Directory -Force
    }
    
    # Create SCCM configuration
    $sccmConfig = @{
        SiteCode = "IMP"
        SiteName = "Imperial Primary Site"
        SQLServer = "star-destroyer-sql"
        ContentLibrary = "C:\SCCM\ContentLibrary"
        ClientVersion = "5.00.9078.1000"
        ConsoleVersion = "2207"
        Features = @(
            "Application Management",
            "Operating System Deployment",
            "Software Updates",
            "Endpoint Protection",
            "Inventory",
            "Remote Control"
        )
    }
    
    $sccmConfig | ConvertTo-Json -Depth 2 | Set-Content -Path "C:\SCCM\siteconfig.json"
}

# Configure WSUS
if ($managementTools -contains "WSUS") {
    Write-Host "Configuring WSUS..."
    
    # Post-install configuration for WSUS
    $wsusUtil = "$env:ProgramFiles\Update Services\Tools\wsusutil.exe"
    
    # Create WSUS content directory
    New-Item -Path "C:\WSUS" -ItemType Directory -Force
    New-Item -Path "C:\WSUS\UpdateServicesPackages" -ItemType Directory -Force
    New-Item -Path "C:\WSUS\WsusContent" -ItemType Directory -Force
    
    # Configure WSUS (mock for demo)
    $wsusConfig = @{
        ContentDirectory = "C:\WSUS\WsusContent"
        SQLInstance = "MICROSOFT##WID"
        UpdateLanguages = @("en")
        Products = @(
            "Windows Server 2022",
            "Windows Server 2019",
            "Windows Server 2016",
            "Windows 11",
            "Windows 10"
        )
        Classifications = @(
            "Critical Updates",
            "Security Updates",
            "Update Rollups",
            "Service Packs"
        )
        SynchronizationSchedule = "Daily at 3:00 AM"
    }
    
    $wsusConfig | ConvertTo-Json -Depth 2 | Set-Content -Path "C:\WSUS\wsusconfig.json"
    
    # Create WSUS administration site in IIS
    Import-Module WebAdministration
    New-WebAppPool -Name "WsusPool"
    New-Website -Name "WSUS Administration" -Port 8530 -PhysicalPath "$env:ProgramFiles\Update Services\WebServices\Root" -ApplicationPool "WsusPool"
}

# Configure Imperial Monitoring tool
if ($managementTools -contains "ImperialMonitoring") {
    Write-Host "Installing Imperial Monitoring System..."
    
    $monitoringPath = "C:\Program Files\Imperial Monitoring System"
    New-Item -Path $monitoringPath -ItemType Directory -Force
    
    # Create monitoring configuration
    $monitoringConfig = @{
        ProductName = "Imperial Monitoring System"
        Version = "4.2.0"
        LicenseType = "Enterprise"
        Features = @{
            PerformanceMonitoring = $true
            EventLogCollection = $true
            RemoteManagement = $true
            AlertingEngine = $true
            Reporting = $true
            Dashboard = $true
        }
        MonitoredSystems = @(
            @{Type = "Windows Server"; Count = 10}
            @{Type = "Linux Server"; Count = 8}
            @{Type = "Network Device"; Count = 15}
            @{Type = "Database"; Count = 5}
        )
        CollectorGroups = @(
            @{Name = "Death Star Systems"; Members = 25}
            @{Name = "Star Destroyer Fleet"; Members = 15}
            @{Name = "Imperial Outposts"; Members = 30}
        )
        Database = @{
            Server = "star-destroyer-sql"
            Name = "ImperialMonitoring"
            Size = "50GB"
        }
    }
    
    $monitoringConfig | ConvertTo-Json -Depth 3 | Set-Content -Path "$monitoringPath\config.json"
    
    # Create monitoring dashboards directory
    $dashboardPath = "$monitoringPath\Dashboards"
    New-Item -Path $dashboardPath -ItemType Directory -Force
    
    # Create sample dashboard
    $dashboardHtml = @"
<!DOCTYPE html>
<html>
<head>
    <title>Imperial Monitoring Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #0a0a0a; color: #00ff00; }
        .header { background-color: #1a1a1a; padding: 20px; text-align: center; }
        .metric { display: inline-block; margin: 20px; padding: 20px; border: 1px solid #00ff00; }
        .critical { color: #ff0000; }
        .warning { color: #ffff00; }
        .healthy { color: #00ff00; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Imperial Fleet Monitoring System</h1>
        <h2>Management Server: ${instance_name}</h2>
    </div>
    <div class="metrics">
        <div class="metric healthy">
            <h3>Systems Online</h3>
            <p>75/80</p>
        </div>
        <div class="metric warning">
            <h3>Alerts Active</h3>
            <p>12</p>
        </div>
        <div class="metric critical">
            <h3>Critical Issues</h3>
            <p>3</p>
        </div>
    </div>
</body>
</html>
"@
    Set-Content -Path "$dashboardPath\index.html" -Value $dashboardHtml
}

# Install PowerShell modules for management
Write-Host "Installing PowerShell management modules..."
Install-Module -Name PSWindowsUpdate -Force -SkipPublisherCheck
Install-Module -Name PSLogging -Force -SkipPublisherCheck

# Create centralized management scripts
$scriptsPath = "C:\ManagementScripts"
New-Item -Path $scriptsPath -ItemType Directory -Force

# Create inventory collection script
$inventoryScript = @'
function Get-ImperialFleetInventory {
    param(
        [string[]]$ComputerNames = @("localhost")
    )
    
    $inventory = @()
    
    foreach ($computer in $ComputerNames) {
        try {
            $system = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $computer
            $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computer
            $cpu = Get-WmiObject -Class Win32_Processor -ComputerName $computer
            $memory = Get-WmiObject -Class Win32_PhysicalMemory -ComputerName $computer
            $disks = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $computer -Filter "DriveType='3'"
            
            $inv = [PSCustomObject]@{
                ComputerName = $computer
                Manufacturer = $system.Manufacturer
                Model = $system.Model
                OS = $os.Caption
                OSVersion = $os.Version
                ServicePack = $os.ServicePackMajorVersion
                CPUName = $cpu[0].Name
                CPUCores = $cpu[0].NumberOfCores
                TotalMemoryGB = [math]::Round(($memory | Measure-Object -Property Capacity -Sum).Sum / 1GB)
                Disks = $disks | ForEach-Object {
                    [PSCustomObject]@{
                        Drive = $_.DeviceID
                        SizeGB = [math]::Round($_.Size / 1GB)
                        FreeGB = [math]::Round($_.FreeSpace / 1GB)
                    }
                }
                LastUpdated = Get-Date
            }
            
            $inventory += $inv
        }
        catch {
            Write-Error "Failed to get inventory for $computer: $_"
        }
    }
    
    return $inventory
}

# Export inventory to CSV
Get-ImperialFleetInventory | Export-Csv -Path "C:\ManagementReports\fleet_inventory.csv" -NoTypeInformation
'@
Set-Content -Path "$scriptsPath\Get-FleetInventory.ps1" -Value $inventoryScript

# Create patch compliance script
$patchScript = @'
function Get-ImperialPatchCompliance {
    param(
        [string[]]$ComputerNames = @("localhost")
    )
    
    $compliance = @()
    
    foreach ($computer in $ComputerNames) {
        try {
            $updates = Get-WmiObject -ComputerName $computer -Query "SELECT * FROM Win32_QuickFixEngineering" | 
                       Select-Object HotFixID, Description, InstalledOn
            
            $lastBoot = (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computer).LastBootUpTime
            $lastBootDate = [Management.ManagementDateTimeConverter]::ToDateTime($lastBoot)
            
            $comp = [PSCustomObject]@{
                ComputerName = $computer
                UpdatesInstalled = $updates.Count
                LastUpdate = ($updates | Sort-Object InstalledOn -Descending | Select-Object -First 1).InstalledOn
                LastReboot = $lastBootDate
                DaysSinceReboot = (New-TimeSpan -Start $lastBootDate -End (Get-Date)).Days
                ComplianceStatus = if ((New-TimeSpan -Start $lastBootDate -End (Get-Date)).Days -gt 30) { "Non-Compliant" } else { "Compliant" }
            }
            
            $compliance += $comp
        }
        catch {
            Write-Error "Failed to get compliance for $computer: $_"
        }
    }
    
    return $compliance
}
'@
Set-Content -Path "$scriptsPath\Get-PatchCompliance.ps1" -Value $patchScript

# Create scheduled task for inventory collection
$inventoryAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\ManagementScripts\Get-FleetInventory.ps1"
$inventoryTrigger = New-ScheduledTaskTrigger -Daily -At "6:00AM"
Register-ScheduledTask -TaskName "Imperial Fleet Inventory" -Action $inventoryAction -Trigger $inventoryTrigger -User "SYSTEM"

# Create management reports directory
$reportsPath = "C:\ManagementReports"
New-Item -Path $reportsPath -ItemType Directory -Force

# Configure SNMP
Write-Host "Configuring SNMP..."
Install-WindowsFeature -Name SNMP-Service,SNMP-WMI-Provider
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent" -Name "sysContact" -Value "empire-it@starwars.local"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent" -Name "sysLocation" -Value "Death Star Data Center - Management Wing"

# Create performance monitoring configuration
Write-Host "Configuring performance monitoring..."
$perfCounters = @(
    "\Processor(_Total)\% Processor Time",
    "\Memory\Available MBytes",
    "\PhysicalDisk(_Total)\% Disk Time",
    "\Network Interface(*)\Bytes Total/sec"
)

# Create data collector set
$collectorName = "Imperial Management Monitoring"
$collectorPath = "C:\PerfLogs\Admin\$collectorName"
New-Item -Path $collectorPath -ItemType Directory -Force

# Create IIS site for management tools
Import-Module WebAdministration
$mgmtSitePath = "C:\inetpub\management"
New-Item -Path $mgmtSitePath -ItemType Directory -Force

$mgmtPortalHtml = @"
<!DOCTYPE html>
<html>
<head>
    <title>Imperial Management Portal</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #1a1a1a; color: #fff; }
        .container { margin: 20px; }
        .tool { border: 1px solid #666; padding: 15px; margin: 10px 0; }
        .tool h3 { color: #4a9eff; }
        a { color: #4a9eff; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Imperial Fleet Management Portal</h1>
        <h2>Server: ${instance_name}</h2>
        
        <div class="tool">
            <h3>System Center Configuration Manager (SCCM)</h3>
            <p>Manage software deployment, updates, and compliance across the Imperial Fleet</p>
            <a href="/sccm">Access SCCM Console</a>
        </div>
        
        <div class="tool">
            <h3>Windows Server Update Services (WSUS)</h3>
            <p>Centralized update management for all Imperial systems</p>
            <a href="http://${instance_name}:8530">Access WSUS Console</a>
        </div>
        
        <div class="tool">
            <h3>Imperial Monitoring System</h3>
            <p>Real-time monitoring and alerting for critical systems</p>
            <a href="/monitoring">Access Monitoring Dashboard</a>
        </div>
        
        <div class="tool">
            <h3>Reports</h3>
            <p>View system inventory and compliance reports</p>
            <a href="/reports">Access Reports</a>
        </div>
    </div>
</body>
</html>
"@
Set-Content -Path "$mgmtSitePath\index.html" -Value $mgmtPortalHtml

# Create IIS site
New-WebAppPool -Name "ManagementPortal"
New-Website -Name "Imperial Management Portal" -Port 8080 -PhysicalPath $mgmtSitePath -ApplicationPool "ManagementPortal"

# Enable remote management
Write-Host "Enabling remote management..."
Enable-PSRemoting -Force
Enable-WSManCredSSP -Role Server -Force

# Configure Windows Firewall for management tools
New-NetFirewallRule -DisplayName "SCCM Console" -Direction Inbound -Protocol TCP -LocalPort 8005 -Action Allow
New-NetFirewallRule -DisplayName "WSUS Administration" -Direction Inbound -Protocol TCP -LocalPort 8530 -Action Allow
New-NetFirewallRule -DisplayName "Management Portal" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow

# Schedule restart to complete configuration
shutdown /r /t 300 /c "Restarting to complete management server configuration"

# Write completion flag
$completionData = @{
    Timestamp = Get-Date
    Server = $computerName
    ManagementTools = $managementTools
    Features = @(
        "SCCM Site Server",
        "WSUS Server",
        "Imperial Monitoring",
        "PowerShell Management",
        "Centralized Reporting",
        "Remote Management"
    )
    Endpoints = @{
        ManagementPortal = "http://${instance_name}:8080"
        WSUS = "http://${instance_name}:8530"
        SCCM = "http://${instance_name}:8005"
    }
}

$completionData | ConvertTo-Json -Depth 3 | Set-Content -Path "C:\deployment_complete.json"
Write-EventLog -LogName Application -Source "ManagementServerSetup" -EventId 9999 -EntryType Information -Message "Management server deployment completed"
</powershell>