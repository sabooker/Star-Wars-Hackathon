# modules/windows_servers/userdata/modern_app_server.ps1
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

# Install Java 17 (Modern LTS version)
Write-Host "Installing Java 17 LTS..."
$javaUrl = "https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.exe"
$javaPath = "C:\temp\java17-installer.exe"
New-Item -Path "C:\temp" -ItemType Directory -Force
Invoke-WebRequest -Uri $javaUrl -OutFile $javaPath -UseBasicParsing

# Silent install Java 17
Start-Process -FilePath $javaPath -ArgumentList "/s" -Wait

# Set JAVA_HOME for Java 17
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk-17", [System.EnvironmentVariableTarget]::Machine)
$env:Path += ";C:\Program Files\Java\jdk-17\bin"

# Install IIS with modern features
Write-Host "Installing IIS with modern features..."
Install-WindowsFeature -Name Web-Server,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Health,Web-Http-Logging,Web-Performance,Web-Security,Web-Filtering,Web-App-Dev,Web-Net-Ext45,Web-Asp-Net45,Web-WebSockets,Web-Application-Init,Web-Mgmt-Tools,Web-Mgmt-Console

# Install .NET Core/.NET 6 Runtime and SDK
Write-Host "Installing .NET 6 Runtime and SDK..."
$dotnetUrl = "https://download.visualstudio.microsoft.com/download/pr/3e6bf187-36d5-47df-be8f-065f5bed5c56/1a3279320636e011ff297f7e1330fc14/dotnet-sdk-6.0.415-win-x64.exe"
$dotnetPath = "C:\temp\dotnet6-sdk.exe"
Invoke-WebRequest -Uri $dotnetUrl -OutFile $dotnetPath -UseBasicParsing
Start-Process -FilePath $dotnetPath -ArgumentList "/quiet" -Wait

# Create modern application directory structure
$appPath = "C:\Apps\${app_name}"
$appDirs = @(
    "$appPath\bin",
    "$appPath\config",
    "$appPath\logs",
    "$appPath\data",
    "$appPath\www"
)

foreach ($dir in $appDirs) {
    New-Item -Path $dir -ItemType Directory -Force
}

# Create modern application configuration (JSON format)
$appConfig = @{
    ApplicationName = "${app_name}"
    Version = "3.0.0"
    Runtime = @{
        Java = "${java_version}"
        DotNet = "6.0"
    }
    Features = @{
        Authentication = "OAuth2"
        API = "REST"
        Containerization = "Docker-ready"
        Monitoring = "Application Insights"
    }
    Database = @{
        Type = "SQL Server"
        ConnectionString = "Server=star-destroyer-sql;Database=ImperialFleet;Integrated Security=true;TrustServerCertificate=true;"
    }
    Microservices = @(
        "Authentication Service",
        "Fleet Management Service",
        "Trooper Management Service",
        "Analytics Service"
    )
}

$appConfig | ConvertTo-Json -Depth 3 | Set-Content -Path "$appPath\config\appsettings.json"

# Create Docker compose file for microservices
$dockerCompose = @"
version: '3.8'
services:
  fleet-api:
    image: empire/fleet-management:latest
    ports:
      - "8080:8080"
    environment:
      - JAVA_OPTS=-Xmx1024m
      - SPRING_PROFILES_ACTIVE=production
    depends_on:
      - redis
      - rabbitmq
  
  auth-service:
    image: empire/auth-service:latest
    ports:
      - "8081:8081"
    environment:
      - JWT_SECRET=ImperialSecret123
  
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
  
  rabbitmq:
    image: rabbitmq:3-management
    ports:
      - "5672:5672"
      - "15672:15672"
"@
Set-Content -Path "$appPath\docker-compose.yml" -Value $dockerCompose

# Install Docker Desktop for Windows Server
Write-Host "Preparing for container support..."
Install-WindowsFeature -Name Containers
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart:$false

# Install modern security software (current version)
Write-Host "Installing up-to-date security software..."
New-Item -Path "C:\Program Files\${security_software}" -ItemType Directory -Force

# Create comprehensive security configuration
$securityConfig = @{
    Product = "${security_software}"
    Version = "${security_version}"
    Vendor = "Imperial Security Systems"
    LastUpdate = (Get-Date).ToString("yyyy-MM-dd")
    Features = @{
        AntiVirus = @{
            Enabled = $true
            RealTimeProtection = $true
            CloudProtection = $true
            MachineLearning = $true
        }
        Firewall = @{
            Enabled = $true
            Mode = "Advanced"
            Rules = "Auto-managed"
        }
        IntrusionDetection = @{
            Enabled = $true
            Sensitivity = "High"
            AIAnalysis = $true
        }
        Compliance = @{
            Standards = @("ISO27001", "SOC2", "HIPAA")
            AutoReporting = $true
            Remediation = "Automatic"
        }
    }
    License = @{
        Type = "Enterprise"
        Status = "Active"
        Expiration = (Get-Date).AddYears(2).ToString("yyyy-MM-dd")
        Seats = 10000
    }
}

$securityConfig | ConvertTo-Json -Depth 4 | Set-Content -Path "C:\Program Files\${security_software}\config.json"
Set-Content -Path "C:\Program Files\${security_software}\version.txt" -Value ${security_version}

# Create modern Windows service with recovery options
Write-Host "Creating modern application service..."
$serviceParams = @{
    Name = "${app_name}Service"
    DisplayName = "Imperial Fleet Manager Service"
    Description = "Modern microservices-based fleet management system"
    BinaryPathName = "C:\Apps\${app_name}\bin\service.exe"
    StartupType = "Automatic"
    Credential = $null  # Run as LocalSystem
}

if (Get-Service -Name $serviceParams.Name -ErrorAction SilentlyContinue) {
    Stop-Service -Name $serviceParams.Name -Force
    sc.exe delete $serviceParams.Name
}

# Note: In real deployment, this would be an actual service executable
# New-Service @serviceParams

# Configure service recovery options
# sc.exe failure "${app_name}Service" reset= 86400 actions= restart/60000/restart/60000/restart/60000

# Install monitoring and telemetry
Write-Host "Setting up Application Insights and monitoring..."
$appInsightsKey = "00000000-0000-0000-0000-000000000000"  # Placeholder
$telemetryConfig = @{
    InstrumentationKey = $appInsightsKey
    ApplicationName = "${app_name}"
    Environment = "Production"
    EnableTrace = $true
    EnableMetrics = $true
    EnableDependencyTracking = $true
}

$telemetryConfig | ConvertTo-Json | Set-Content -Path "$appPath\config\telemetry.json"

# Configure SNMP with modern OIDs
Write-Host "Configuring SNMP..."
Install-WindowsFeature -Name SNMP-Service,SNMP-WMI-Provider
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent" -Name "sysContact" -Value "empire-it@starwars.local"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent" -Name "sysLocation" -Value "Death Star Data Center - Modern Wing"

# Enable Windows features for modern apps
Write-Host "Enabling modern Windows features..."
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart

# Create PowerShell module for app management
$psModule = @'
function Get-ImperialFleetStatus {
    [CmdletBinding()]
    param()
    
    $status = @{
        ServiceStatus = Get-Service -Name "*Imperial*" | Select-Object Name, Status
        ApplicationVersion = Get-Content "C:\Apps\ImperialFleetManager\config\appsettings.json" | ConvertFrom-Json | Select-Object -ExpandProperty Version
        SecurityStatus = Get-Content "C:\Program Files\BlastShield\config.json" | ConvertFrom-Json | Select-Object -ExpandProperty Features
        SystemHealth = @{
            CPU = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
            Memory = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
            Disk = (Get-Counter '\PhysicalDisk(_Total)\% Disk Time').CounterSamples.CookedValue
        }
    }
    
    return $status
}

Export-ModuleMember -Function Get-ImperialFleetStatus
'@

$modulePath = "C:\Program Files\WindowsPowerShell\Modules\ImperialFleetManager"
New-Item -Path $modulePath -ItemType Directory -Force
Set-Content -Path "$modulePath\ImperialFleetManager.psm1" -Value $psModule

# Create scheduled tasks for modern maintenance
$maintenanceTasks = @(
    @{
        Name = "${app_name} Health Check"
        Schedule = "Every 5 minutes"
        Action = "C:\Apps\${app_name}\bin\health-check.exe"
    },
    @{
        Name = "${app_name} Log Rotation"
        Schedule = "Daily at 2:00 AM"
        Action = "powershell.exe -Command 'Compress-Archive -Path C:\Apps\${app_name}\logs\*.log -DestinationPath C:\Apps\${app_name}\logs\archive\$(Get-Date -Format yyyyMMdd).zip'"
    },
    @{
        Name = "${app_name} Security Update"
        Schedule = "Weekly on Sunday at 3:00 AM"
        Action = "C:\Program Files\${security_software}\updater.exe"
    }
)

foreach ($task in $maintenanceTasks) {
    $action = New-ScheduledTaskAction -Execute $task.Action
    $trigger = switch ($task.Schedule) {
        "Every 5 minutes" { New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) }
        "Daily at 2:00 AM" { New-ScheduledTaskTrigger -Daily -At "2:00AM" }
        "Weekly on Sunday at 3:00 AM" { New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Sunday -At "3:00AM" }
    }
    Register-ScheduledTask -TaskName $task.Name -Action $action -Trigger $trigger -User "SYSTEM"
}

# Enable Performance Counters
Write-Host "Configuring performance monitoring..."
$categoryName = "Imperial Fleet Manager"
$counterName = "Requests per Second"
if (-not [System.Diagnostics.PerformanceCounterCategory]::Exists($categoryName)) {
    $counterData = New-Object System.Diagnostics.CounterCreationDataCollection
    $counter = New-Object System.Diagnostics.CounterCreationData
    $counter.CounterName = $counterName
    $counter.CounterHelp = "Number of requests processed per second"
    $counter.CounterType = [System.Diagnostics.PerformanceCounterType]::RateOfCountsPerSecond32
    $counterData.Add($counter)
    
    [System.Diagnostics.PerformanceCounterCategory]::Create($categoryName, "Performance metrics for Imperial Fleet Manager", [System.Diagnostics.PerformanceCounterCategoryType]::SingleInstance, $counterData)
}

# Schedule restart to complete configuration
shutdown /r /t 300 /c "Restarting to complete modern application setup"

# Write completion flag with metadata
$completionData = @{
    DeploymentTime = Get-Date
    ServerName = $computerName
    ApplicationVersion = "3.0.0"
    SecuritySoftware = @{
        Name = "${security_software}"
        Version = "${security_version}"
        Status = "Active"
    }
    Features = @(
        "Microservices Architecture",
        "Container Support",
        "Modern Security",
        "Application Insights",
        "Performance Monitoring"
    )
}

$completionData | ConvertTo-Json -Depth 3 | Set-Content -Path "C:\deployment_complete.json"
Write-EventLog -LogName Application -Source "ImperialFleetManager" -EventId 1000 -EntryType Information -Message "Modern application server deployment completed"
</powershell>