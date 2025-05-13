# modules/mid_server_windows/userdata/windows_mid_server_setup.ps1
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

# Enable WMI through Windows Firewall
Enable-NetFirewallRule -DisplayGroup "Windows Management Instrumentation (WMI)"
Enable-NetFirewallRule -DisplayGroup "Remote Administration"
Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing"

# Set WMI permissions
$Namespace = "root/cimv2"
$ComputerName = "."
$WMI = Get-WmiObject -Namespace $Namespace -Class __SystemSecurity -ComputerName $ComputerName
$WMI.PsBase.Scope.Options.EnablePrivileges = $true

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

# Configure WMI security for discovery
Write-Host "Configuring WMI security..."
$WMISDDL = "O:BAG:BAD:(A;;CCDCRP;;;BA)(A;;CCDCRP;;;IU)(A;;CCDCRP;;;SY)"
$DCOMSDDL = "O:BAG:BAD:(A;;CCDCRP;;;BA)(A;;CCDCRP;;;IU)(A;;CCDCRP;;;SY)"

# Set WMI namespace security
$WMIPath = "winmgmts:\\.\root\cimv2"
$WMISecurity = Get-WmiObject -Namespace "root\cimv2" -Class "__SystemSecurity"
$WMISecurity.SetSecurityDescriptor($WMISDDL)

# Enable PowerShell Remoting
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
Set-Service WinRM -StartupType Automatic
Start-Service WinRM

# Configure WinRM for HTTPS
$cert = New-SelfSignedCertificate -DnsName $computerName -CertStoreLocation "cert:\LocalMachine\My"
$thumbprint = $cert.Thumbprint
New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $thumbprint -Force

# Join domain if specified
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

# Install required features
Write-Host "Installing required Windows features..."
Install-WindowsFeature -Name NET-Framework-45-Core,NET-Framework-45-Features
Install-WindowsFeature -Name RSAT-AD-PowerShell
Install-WindowsFeature -Name SNMP-Service,SNMP-WMI-Provider

# Configure SNMP
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent" -Name "sysContact" -Value "empire-it@starwars.local"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\RFC1156Agent" -Name "sysLocation" -Value "Death Star Data Center"

# Download and install Java for MID Server
Write-Host "Installing Java for MID Server..."
$javaUrl = "https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.exe"
$javaPath = "C:\temp\java-installer.exe"
New-Item -Path "C:\temp" -ItemType Directory -Force
Invoke-WebRequest -Uri $javaUrl -OutFile $javaPath
Start-Process -FilePath $javaPath -ArgumentList "/s" -Wait

# Set JAVA_HOME
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk-17", [System.EnvironmentVariableTarget]::Machine)
$env:Path += ";C:\Program Files\Java\jdk-17\bin"

# Create MID Server directories
Write-Host "Creating MID Server directories..."
New-Item -Path "C:\ServiceNow\MID Server\agent" -ItemType Directory -Force
New-Item -Path "C:\ServiceNow\MID Server\logs" -ItemType Directory -Force
New-Item -Path "C:\ServiceNow\MID Server\scripts" -ItemType Directory -Force

# Create MID Server placeholder configuration
$midConfig = @"
<?xml version="1.0" encoding="UTF-8"?>
<parameters>
    <parameter name="url" value="https://dev220647.service-now.com"/>
    <parameter name="mid.instance.username" value="admin"/>
    <parameter name="mid.instance.password" value="CHANGE_ME"/>
    <parameter name="name" value="${instance_name}"/>
    <parameter name="mid.platform" value="Windows"/>
    <parameter name="mid.instance.connection.timeout" value="900000"/>
    <parameter name="max.threads.init" value="25"/>
    <parameter name="max.threads.max" value="100"/>
    <parameter name="max.threads.idle" value="10"/>
</parameters>
"@
Set-Content -Path "C:\ServiceNow\MID Server\agent\config.xml" -Value $midConfig

# Create MID Server download script
$downloadScript = @'
param(
    [Parameter(Mandatory=$true)]
    [string]$MIDServerURL
)

$midDir = "C:\ServiceNow\MID Server"
$tempFile = "$env:TEMP\mid_server.zip"

Write-Host "Downloading MID Server from ServiceNow..."
Invoke-WebRequest -Uri $MIDServerURL -OutFile $tempFile

Write-Host "Extracting MID Server..."
Expand-Archive -Path $tempFile -DestinationPath $midDir -Force

Write-Host "Setting up MID Server as Windows Service..."
Set-Location "$midDir\agent"
& ".\wrapper.bat" -i ..\conf\wrapper-override.conf

Write-Host "MID Server installed successfully"
Write-Host "Please update the config.xml with your ServiceNow credentials"
Write-Host "Then start the service: Start-Service 'snc_mid'"
'@
Set-Content -Path "C:\ServiceNow\MID Server\scripts\Download-MIDServer.ps1" -Value $downloadScript

# Create WMI test script
$wmiTestScript = @'
# Test WMI connectivity
param(
    [string]$ComputerName = "localhost",
    [string]$Username,
    [string]$Password
)

Write-Host "Testing WMI connectivity to $ComputerName"

if ($Username -and $Password) {
    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($Username, $securePassword)
    $wmiParams = @{
        ComputerName = $ComputerName
        Credential = $credential
    }
} else {
    $wmiParams = @{
        ComputerName = $ComputerName
    }
}

try {
    $os = Get-WmiObject -Class Win32_OperatingSystem @wmiParams
    Write-Host "SUCCESS: Connected to $($os.Caption) - $($os.Version)"
    
    $computer = Get-WmiObject -Class Win32_ComputerSystem @wmiParams
    Write-Host "Computer: $($computer.Name)"
    Write-Host "Domain: $($computer.Domain)"
    Write-Host "Model: $($computer.Model)"
    
} catch {
    Write-Host "ERROR: Failed to connect - $_"
}
'@
Set-Content -Path "C:\ServiceNow\MID Server\scripts\Test-WMIConnectivity.ps1" -Value $wmiTestScript

# Create discovery helper scripts
$discoveryHelper = @'
# Helper functions for ServiceNow Discovery
function Test-WindowsDiscovery {
    param(
        [string]$TargetComputer,
        [string]$Username,
        [string]$Password
    )
    
    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($Username, $securePassword)
    
    Write-Host "Testing discovery connectivity to $TargetComputer"
    
    # Test WMI
    try {
        $wmi = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $TargetComputer -Credential $credential
        Write-Host "[OK] WMI Connection successful"
    } catch {
        Write-Host "[FAIL] WMI Connection failed: $_"
    }
    
    # Test WinRM
    try {
        $session = New-PSSession -ComputerName $TargetComputer -Credential $credential
        Write-Host "[OK] WinRM Connection successful"
        Remove-PSSession $session
    } catch {
        Write-Host "[FAIL] WinRM Connection failed: $_"
    }
    
    # Test Remote Registry
    try {
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $TargetComputer)
        Write-Host "[OK] Remote Registry accessible"
        $reg.Close()
    } catch {
        Write-Host "[FAIL] Remote Registry failed: $_"
    }
}
'@
Set-Content -Path "C:\ServiceNow\MID Server\scripts\Discovery-Helpers.ps1" -Value $discoveryHelper

# Install monitoring components
Write-Host "Installing monitoring components..."

# Install CloudWatch Agent
$cwAgentUrl = "https://s3.amazonaws.com/amazoncloudwatch-agent/windows/amd64/latest/amazon-cloudwatch-agent.msi"
$cwAgentPath = "C:\temp\amazon-cloudwatch-agent.msi"
Invoke-WebRequest -Uri $cwAgentUrl -OutFile $cwAgentPath
Start-Process msiexec.exe -ArgumentList "/i `"$cwAgentPath`" /quiet" -Wait

# Configure CloudWatch
$cwConfig = @"
{
  "logs": {
    "logs_collected": {
      "windows_events": {
        "collect_list": [
          {
            "event_name": "Security",
            "event_levels": ["INFORMATION", "WARNING", "ERROR", "CRITICAL"],
            "log_group_name": "/aws/ec2/windows-mid-server/${environment_name}",
            "log_stream_name": "{instance_id}/security"
          },
          {
            "event_name": "System",
            "event_levels": ["WARNING", "ERROR", "CRITICAL"],
            "log_group_name": "/aws/ec2/windows-mid-server/${environment_name}",
            "log_stream_name": "{instance_id}/system"
          }
        ]
      },
      "files": {
        "collect_list": [
          {
            "file_path": "C:\\ServiceNow\\MID Server\\agent\\logs\\agent0.log.0",
            "log_group_name": "/aws/ec2/windows-mid-server/${environment_name}",
            "log_stream_name": "{instance_id}/mid-server"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "StarWars/WindowsMIDServer",
    "metrics_collected": {
      "Processor": {
        "measurement": [
          {
            "name": "% Idle Time",
            "rename": "CPU_IDLE",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      },
      "Memory": {
        "measurement": [
          {
            "name": "% Committed Bytes In Use",
            "rename": "MEM_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
"@
Set-Content -Path "C:\ProgramData\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent.json" -Value $cwConfig

# Start CloudWatch Agent
& "C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1" -a query -m ec2 -c file:"C:\ProgramData\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent.json" -s

# Create status check script
$statusScript = @'
Write-Host "Windows MID Server Status Check"
Write-Host "=============================="

# Check services
$services = @{
    "Windows Remote Management (WS-Management)" = "WinRM"
    "Windows Management Instrumentation" = "Winmgmt"
    "Remote Registry" = "RemoteRegistry"
    "SNMP Service" = "SNMP"
}

foreach ($service in $services.GetEnumerator()) {
    $status = Get-Service -Name $service.Value
    if ($status.Status -eq "Running") {
        Write-Host "[OK] $($service.Key) is running"
    } else {
        Write-Host "[FAIL] $($service.Key) is not running"
    }
}

# Check MID Server
if (Test-Path "C:\ServiceNow\MID Server\agent\wrapper.bat") {
    Write-Host "[OK] MID Server is installed"
    $midService = Get-Service -Name "snc_mid" -ErrorAction SilentlyContinue
    if ($midService) {
        Write-Host "[OK] MID Server service exists - Status: $($midService.Status)"
    } else {
        Write-Host "[INFO] MID Server service not installed yet"
    }
} else {
    Write-Host "[INFO] MID Server not downloaded yet"
}

# Check Java
$javaVersion = & java -version 2>&1
Write-Host "Java Version: $($javaVersion[0])"

# Test WMI locally
try {
    $os = Get-WmiObject -Class Win32_OperatingSystem
    Write-Host "[OK] Local WMI is working"
} catch {
    Write-Host "[FAIL] Local WMI test failed"
}
'@
Set-Content -Path "C:\ServiceNow\MID Server\scripts\Check-Status.ps1" -Value $statusScript

# Schedule restart to complete configuration
shutdown /r /t 300 /c "Restarting to complete MID Server configuration"

# Write completion flag
Set-Content -Path "C:\deployment_complete.txt" -Value "Windows MID Server deployment completed at $(Get-Date)"
</powershell>