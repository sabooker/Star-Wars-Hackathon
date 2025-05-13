# modules/windows_servers/userdata/service_host.ps1
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

# Install Windows features for services
Write-Host "Installing Windows features for service hosting..."
Install-WindowsFeature -Name NET-Framework-45-Core
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
Install-WindowsFeature -Name MSMQ-Server
Install-WindowsFeature -Name MSMQ-Directory
Install-WindowsFeature -Name MSMQ-HTTP-Support

# Configure MSMQ for message queuing service
Write-Host "Configuring MSMQ..."
$msmqPath = "C:\MessageQueues"
New-Item -Path $msmqPath -ItemType Directory -Force

# Create private queues
$queues = @(
    ".\private$\${services[0].Replace(' ', '')}"
    ".\private$\${services[1].Replace(' ', '')}"
    ".\private$\${services[2].Replace(' ', '')}"
)

foreach ($queuePath in $queues) {
    if (-not [System.Messaging.MessageQueue]::Exists($queuePath)) {
        $queue = [System.Messaging.MessageQueue]::Create($queuePath)
        $queue.Label = $queuePath.Split('\')[-1]
        Write-Host "Created queue: $queuePath"
    }
}

# Install .NET Framework 4.8
Write-Host "Installing .NET Framework 4.8..."
$dotnetUrl = "https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/abd170b4b0ec15ad0222a809b761a036/ndp48-x86-x64-allos-enu.exe"
$dotnetPath = "C:\temp\dotnet48.exe"
New-Item -Path "C:\temp" -ItemType Directory -Force
Invoke-WebRequest -Uri $dotnetUrl -OutFile $dotnetPath -UseBasicParsing
Start-Process -FilePath $dotnetPath -ArgumentList "/quiet" -Wait

# Create service directories and configurations
$servicesData = @{
    "${services[0]}" = @{
        Port = 8100
        Type = "MessageQueue"
        Technology = ".NET Framework"
        Database = "star-destroyer-sql"
    }
    "${services[1]}" = @{
        Port = 8200
        Type = "WebService"
        Technology = "WCF"
        Database = "star-destroyer-sql"
    }
    "${services[2]}" = @{
        Port = 8300
        Type = "Monitoring"
        Technology = ".NET Core"
        Database = "star-destroyer-sql"
    }
}

foreach ($serviceName in $servicesData.Keys) {
    $serviceInfo = $servicesData[$serviceName]
    $servicePath = "C:\Services\$serviceName"
    
    # Create directory structure
    $dirs = @(
        "$servicePath\bin",
        "$servicePath\config",
        "$servicePath\logs",
        "$servicePath\data"
    )
    
    foreach ($dir in $dirs) {
        New-Item -Path $dir -ItemType Directory -Force
    }
    
    # Create service configuration
    $configXml = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <appSettings>
    <add key="ServiceName" value="$serviceName" />
    <add key="Port" value="$($serviceInfo.Port)" />
    <add key="Type" value="$($serviceInfo.Type)" />
    <add key="Technology" value="$($serviceInfo.Technology)" />
    <add key="LogPath" value="$servicePath\logs" />
  </appSettings>
  <connectionStrings>
    <add name="DefaultConnection" connectionString="Server=$($serviceInfo.Database);Database=EmpireCore;Integrated Security=true;" />
  </connectionStrings>
  <system.serviceModel>
    <services>
      <service name="$serviceName">
        <endpoint address="" binding="netTcpBinding" contract="IService" />
        <endpoint address="mex" binding="mexHttpBinding" contract="IMetadataExchange" />
      </service>
    </services>
  </system.serviceModel>
</configuration>
"@
    Set-Content -Path "$servicePath\config\service.config" -Value $configXml
    
    # Create mock service executable info
    $serviceExeInfo = @"
Service: $serviceName
Version: 2.5.0
Framework: $($serviceInfo.Technology)
Port: $($serviceInfo.Port)
Type: $($serviceInfo.Type)
Dependencies: .NET Framework 4.8, MSMQ
"@
    Set-Content -Path "$servicePath\bin\service.info" -Value $serviceExeInfo
}

# Create Windows Services
Write-Host "Creating Windows Services..."
$serviceTemplate = @'
using System;
using System.ServiceProcess;

namespace ImperialServices
{
    public partial class ServiceName : ServiceBase
    {
        public ServiceName()
        {
            InitializeComponent();
        }

        protected override void OnStart(string[] args)
        {
            // Service start logic
            EventLog.WriteEntry("Service started", EventLogEntryType.Information);
        }

        protected override void OnStop()
        {
            // Service stop logic
            EventLog.WriteEntry("Service stopped", EventLogEntryType.Information);
        }
    }
}
'@

# Register services
$serviceList = @(
    @{
        Name = "${services[0].Replace(' ', '')}"
        DisplayName = "${services[0]}"
        Description = "Imperial message queuing service for trooper deployment coordination"
        StartMode = "Automatic"
        Dependencies = @("MSMQ")
    },
    @{
        Name = "${services[1].Replace(' ', '')}"
        DisplayName = "${services[1]}"
        Description = "Core service for trooper deployment operations"
        StartMode = "Automatic"
        Dependencies = @("MSMQ", "${services[0].Replace(' ', '')}")
    },
    @{
        Name = "${services[2].Replace(' ', '')}"
        DisplayName = "${services[2]}"
        Description = "Monitoring service for Death Star operations"
        StartMode = "Automatic"
        Dependencies = @()
    }
)

foreach ($svc in $serviceList) {
    # Create Windows Service (mock - in real deployment this would be actual service)
    if (Get-Service -Name $svc.Name -ErrorAction SilentlyContinue) {
        Stop-Service -Name $svc.Name -Force
        sc.exe delete $svc.Name
    }
    
    # Create service using sc.exe (simulated)
    # sc.exe create $svc.Name binPath= "C:\Services\$($svc.DisplayName)\bin\service.exe" DisplayName= "$($svc.DisplayName)" start= auto
    
    # Create event log source
    $logName = "Application"
    if (-not [System.Diagnostics.EventLog]::SourceExists($svc.Name)) {
        [System.Diagnostics.EventLog]::CreateEventSource($svc.Name, $logName)
    }
    
    # Log service creation
    Write-EventLog -LogName $logName -Source $svc.Name -EventId 1000 -EntryType Information -Message "Service registered: $($svc.DisplayName)"
}

# Install monitoring agent simulation
Write-Host "Installing monitoring components..."
$monitoringPath = "C:\Program Files\Imperial Monitoring"
New-Item -Path $monitoringPath -ItemType Directory -Force

$monitoringConfig = @{
    Agent = "Imperial Monitor Pro"
    Version = "3.0.1"
    CollectorEndpoint = "https://deathstar-monitor.empire.local"
    MetricsEnabled = $true
    LogsEnabled = $true
    TracesEnabled = $true
    Services = @(
        @{Name = "${services[0]}"; Monitored = $true}
        @{Name = "${services[1]}"; Monitored = $true}
        @{Name = "${services[2]}"; Monitored = $true}
    )
}

$monitoringConfig | ConvertTo-Json -Depth 3 | Set-Content -Path "$monitoringPath\config.json"

# Configure IIS for service endpoints
Write-Host "Configuring IIS for service endpoints..."
Import-Module WebAdministration

# Create application pools
foreach ($serviceName in $services) {
    $poolName = "$serviceName Pool"
    $siteName = "$serviceName Site"
    $port = 8000 + $services.IndexOf($serviceName)
    
    # Create app pool
    if (-not (Test-Path "IIS:\AppPools\$poolName")) {
        New-WebAppPool -Name $poolName
        Set-ItemProperty -Path "IIS:\AppPools\$poolName" -Name processIdentity.identityType -Value NetworkService
        Set-ItemProperty -Path "IIS:\AppPools\$poolName" -Name enable32BitAppOnWin64 -Value $false
    }
    
    # Create website (for service endpoints)
    $physicalPath = "C:\Services\$serviceName\www"
    New-Item -Path $physicalPath -ItemType Directory -Force
    
    if (-not (Get-Website -Name $siteName -ErrorAction SilentlyContinue)) {
        New-Website -Name $siteName -Port $port -PhysicalPath $physicalPath -ApplicationPool $poolName
    }
}

# Configure SNMP
Write-Host "Configuring SNMP..."
Install-WindowsFeature -Name SNMP-Service,SNMP-WMI-Provider
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent" -Name "sysContact" -Value "empire-it@starwars.local"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent" -Name "sysLocation" -Value "Death Star Data Center - Service Wing"

# Create performance counters for services
Write-Host "Creating performance counters..."
$categoryName = "Imperial Services"
if (-not [System.Diagnostics.PerformanceCounterCategory]::Exists($categoryName)) {
    $counterDataCollection = New-Object System.Diagnostics.CounterCreationDataCollection
    
    $counters = @(
        @{Name = "Messages Processed"; Type = "NumberOfItems32"}
        @{Name = "Service Uptime"; Type = "NumberOfItems32"}
        @{Name = "Queue Length"; Type = "NumberOfItems32"}
    )
    
    foreach ($counter in $counters) {
        $counterData = New-Object System.Diagnostics.CounterCreationData
        $counterData.CounterName = $counter.Name
        $counterData.CounterType = [System.Diagnostics.PerformanceCounterType]::($counter.Type)
        $counterDataCollection.Add($counterData)
    }
    
    [System.Diagnostics.PerformanceCounterCategory]::Create($categoryName, "Performance counters for Imperial Services", [System.Diagnostics.PerformanceCounterCategoryType]::SingleInstance, $counterDataCollection)
}

# Create scheduled tasks for service monitoring
$tasks = @(
    @{
        Name = "Service Health Check"
        Schedule = (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5))
        Action = (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -Command 'Get-Service | Where-Object {$_.Name -like \"*Imperial*\" -or $_.Name -like \"*Trooper*\" -or $_.Name -like \"*DeathStar*\"} | Select-Object Name, Status | Export-Csv C:\Services\health-check.csv -NoTypeInformation'")
    },
    @{
        Name = "Queue Monitor"
        Schedule = (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 10))
        Action = (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -Command '[System.Messaging.MessageQueue]::GetPrivateQueuesByMachine(\".\") | ForEach-Object { $_ | Select-Object QueueName, MessageCount } | Export-Csv C:\Services\queue-status.csv -NoTypeInformation'")
    }
)

foreach ($task in $tasks) {
    Register-ScheduledTask -TaskName $task.Name -Trigger $task.Schedule -Action $task.Action -User "SYSTEM"
}

# Install .NET hosting bundle for modern services
Write-Host "Installing .NET hosting bundle..."
$hostingBundleUrl = "https://download.visualstudio.microsoft.com/download/pr/73f8fcdb-7b4e-4c3c-bb05-b3651c8d4fbc/d9ce2dd5fb7e5f12f915d47a8c3f6c95/dotnet-hosting-6.0.14-win.exe"
$hostingBundlePath = "C:\temp\hosting-bundle.exe"
Invoke-WebRequest -Uri $hostingBundleUrl -OutFile $hostingBundlePath -UseBasicParsing
Start-Process -FilePath $hostingBundlePath -ArgumentList "/quiet" -Wait

# Create service dashboard
$dashboardHtml = @"
<!DOCTYPE html>
<html>
<head>
    <title>Imperial Service Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #1a1a1a; color: #fff; }
        .container { margin: 20px; }
        .service { border: 1px solid #666; padding: 10px; margin: 10px 0; }
        .running { background-color: #2a4d2a; }
        .stopped { background-color: #4d2a2a; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Imperial Service Host Status</h1>
        <h2>Server: ${instance_name}</h2>
        <div id="services">
"@

foreach ($serviceName in $services) {
    $dashboardHtml += @"
        <div class="service running">
            <h3>$serviceName</h3>
            <p>Status: Running</p>
            <p>Port: $(8000 + $services.IndexOf($serviceName))</p>
        </div>
"@
}

$dashboardHtml += @"
        </div>
    </div>
</body>
</html>
"@

Set-Content -Path "C:\inetpub\wwwroot\index.html" -Value $dashboardHtml

# Create PowerShell module for service management
$moduleContent = @'
function Get-ImperialServiceStatus {
    param(
        [string]$ServiceFilter = "*"
    )
    
    Get-Service | Where-Object {
        $_.Name -like "*Imperial*" -or 
        $_.Name -like "*Trooper*" -or 
        $_.Name -like "*DeathStar*"
    } | Where-Object { $_.Name -like $ServiceFilter } |
    Select-Object Name, Status, StartType, DependentServices
}

function Test-ImperialServiceHealth {
    $services = Get-ImperialServiceStatus
    $healthReport = @{
        Timestamp = Get-Date
        TotalServices = $services.Count
        RunningServices = ($services | Where-Object { $_.Status -eq 'Running' }).Count
        StoppedServices = ($services | Where-Object { $_.Status -eq 'Stopped' }).Count
        ServicesHealth = @()
    }
    
    foreach ($service in $services) {
        $health = @{
            Name = $service.Name
            Status = $service.Status
            Health = if ($service.Status -eq 'Running') { 'Healthy' } else { 'Unhealthy' }
        }
        $healthReport.ServicesHealth += $health
    }
    
    return $healthReport
}

Export-ModuleMember -Function Get-ImperialServiceStatus, Test-ImperialServiceHealth
'@

$modulePath = "C:\Program Files\WindowsPowerShell\Modules\ImperialServiceManager"
New-Item -Path $modulePath -ItemType Directory -Force
Set-Content -Path "$modulePath\ImperialServiceManager.psm1" -Value $moduleContent

# Schedule restart to complete configuration
shutdown /r /t 300 /c "Restarting to complete service host configuration"

# Write completion flag
$completionData = @{
    Timestamp = Get-Date
    Server = $computerName
    ServicesConfigured = $services
    Features = @(
        "MSMQ Message Queuing",
        "IIS Service Endpoints",
        "Performance Monitoring",
        ".NET Framework 4.8",
        ".NET Core Hosting",
        "Service Health Monitoring"
    )
}

$completionData | ConvertTo-Json -Depth 2 | Set-Content -Path "C:\deployment_complete.json"
Write-EventLog -LogName Application -Source "ServiceHostSetup" -EventId 9999 -EntryType Information -Message "Service host deployment completed"
</powershell>