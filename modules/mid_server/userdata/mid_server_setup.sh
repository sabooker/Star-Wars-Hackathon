# Create MID Server configuration placeholder
cat > /opt/servicenow/mid-server/conf/config.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<parameters>
    <parameter name="url" value="https://dev220647.service-now.com"/>
    <parameter name="mid.instance.username" value="admin"/>
    <parameter name="mid.instance.password" value="CHANGE_ME"/>
    <parameter name="name" value="${INSTANCE_NAME}"/>
    <parameter name="mid.instance.connection.timeout" value="900000"/>
    <parameter name="max.threads.init" value="25"/>
    <parameter name="max.threads.max" value="100"/>
    <parameter name="max.threads.idle" value="10"/>
</parameters>
EOF

# Create MID Server download script
cat > /opt/servicenow/mid-server/scripts/download_mid_server.sh << 'EOF'
#!/bin/bash
# This script should be run after obtaining the MID Server download URL from ServiceNow
# Usage: ./download_mid_server.sh <MID_SERVER_URL>

if [ $# -eq 0 ]; then
    echo "Please provide the MID Server download URL"
    echo "Usage: $0 <MID_SERVER_URL>"
    exit 1
fi

MID_URL=$1
MID_DIR="/opt/servicenow/mid-server"

echo "Downloading MID Server from ServiceNow..."
wget -O /tmp/mid_server.zip "$MID_URL"

echo "Extracting MID Server..."
unzip -o /tmp/mid_server.zip -d $MID_DIR

echo "Setting permissions..."
chown -R midserver:midserver $MID_DIR
chmod +x $MID_DIR/agent/start.sh
chmod +x $MID_DIR/agent/stop.sh

echo "MID Server downloaded and extracted successfully"
echo "Please update $MID_DIR/agent/config.xml with your ServiceNow credentials"
EOF

chmod +x /opt/servicenow/mid-server/scripts/download_mid_server.sh

# Create MID Server systemd service
cat > /etc/systemd/system/mid-server.service << EOF
[Unit]
Description=ServiceNow MID Server
After=network.target

[Service]
Type=forking
User=midserver
Group=midserver
WorkingDirectory=/opt/servicenow/mid-server/agent
ExecStart=/opt/servicenow/mid-server/agent/start.sh
ExecStop=/opt/servicenow/mid-server/agent/stop.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create AWS credentials retrieval script
cat > /opt/servicenow/mid-server/scripts/get_aws_credentials.py << 'EOF'
#!/usr/bin/env python3
import boto3
import json
import os
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_secret(secret_name, region_name="us-east-1"):
    """Retrieve secret from AWS Secrets Manager"""
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    
    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
        secret = get_secret_value_response['SecretString']
        return json.loads(secret)
    except Exception as e:
        logger.error(f"Error retrieving secret {secret_name}: {str(e)}")
        return None

def get_ssm_parameter(parameter_name, region_name="us-east-1"):
    """Retrieve parameter from AWS Systems Manager Parameter Store"""
    ssm = boto3.client('ssm', region_name=region_name)
    
    try:
        response = ssm.get_parameter(
            Name=parameter_name,
            WithDecryption=True
        )
        return response['Parameter']['Value']
    except Exception as e:
        logger.error(f"Error retrieving parameter {parameter_name}: {str(e)}")
        return None

# Example usage for ServiceNow credentials
environment = os.environ.get('ENVIRONMENT', 'star-wars-hackathon')

# Get ServiceNow credentials from Secrets Manager
servicenow_secret_name = f"{environment}/servicenow/mid-server"
servicenow_creds = get_secret(servicenow_secret_name)

if servicenow_creds:
    logger.info("Retrieved ServiceNow credentials successfully")
    # Update MID Server configuration
    config_file = "/opt/servicenow/mid-server/agent/config.xml"
    if os.path.exists(config_file):
        # Update config.xml with retrieved credentials
        # This is a placeholder - implement XML update logic
        pass
else:
    logger.warning("Could not retrieve ServiceNow credentials")

# Get discovery credentials
discovery_secret_name = f"{environment}/discovery/credentials"
discovery_creds = get_secret(discovery_secret_name)

if discovery_creds:
    logger.info("Retrieved discovery credentials successfully")
    # Store credentials for discovery use
    with open('/opt/servicenow/mid-server/conf/discovery_credentials.json', 'w') as f:
        json.dump(discovery_creds, f)
EOF

chmod +x /opt/servicenow/mid-server/scripts/get_aws_credentials.py

# Create discovery tools installation script
cat > /opt/servicenow/mid-server/scripts/install_discovery_tools.sh << 'EOF'
#!/bin/bash

echo "Installing discovery tools..."

# Install nmap for network discovery
yum install -y nmap nmap-ncat

# Install SNMP tools
yum install -y net-snmp net-snmp-utils

# Install database clients
# PostgreSQL client
amazon-linux-extras install postgresql13 -y

# MySQL client
yum install -y mysql

# Install Microsoft SQL Server tools (for Linux)
curl https://packages.microsoft.com/config/rhel/8/prod.repo > /etc/yum.repos.d/msprod.repo
ACCEPT_EULA=Y yum install -y mssql-tools unixODBC-devel
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> /etc/profile.d/mssql-tools.sh

# Install jmxterm for JMX discovery
wget https://github.com/jiaqi/jmxterm/releases/download/v1.0.2/jmxterm-1.0.2-uber.jar -O /opt/servicenow/mid-server/jmxterm.jar

# Install PowerShell for cross-platform scripting
curl https://packages.microsoft.com/config/rhel/7/prod.repo | tee /etc/yum.repos.d/microsoft.repo
yum install -y powershell

# Create discovery helper scripts directory
mkdir -p /opt/servicenow/mid-server/discovery-helpers

# Create Windows discovery helper
cat > /opt/servicenow/mid-server/discovery-helpers/windows_discovery.ps1 << 'PWSH'
# PowerShell script for Windows discovery
param(
    [string]$Target,
    [string]$Username,
    [string]$Password
)

$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($Username, $securePassword)

# Test WMI connectivity
try {
    $computerInfo = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Target -Credential $credential
    Write-Output "Successfully connected to $Target"
    Write-Output "Computer Name: $($computerInfo.Name)"
    Write-Output "Domain: $($computerInfo.Domain)"
    Write-Output "Manufacturer: $($computerInfo.Manufacturer)"
    Write-Output "Model: $($computerInfo.Model)"
} catch {
    Write-Error "Failed to connect to $Target: $_"
}
PWSH

chmod +x /opt/servicenow/mid-server/discovery-helpers/windows_discovery.ps1

echo "Discovery tools installation completed"
EOF

chmod +x /opt/servicenow/mid-server/scripts/install_discovery_tools.sh

# Run discovery tools installation
/opt/servicenow/mid-server/scripts/install_discovery_tools.sh

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/opt/servicenow/mid-server/agent/logs/agent0.log.0",
            "log_group_name": "/aws/ec2/mid-server/${ENVIRONMENT}",
            "log_stream_name": "{instance_id}/mid-server",
            "retention_in_days": 30
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/mid-server/${ENVIRONMENT}",
            "log_stream_name": "{instance_id}/system",
            "retention_in_days": 30
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "StarWars/MIDServer",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_USAGE_IDLE",
            "unit": "Percent"
          },
          {
            "name": "cpu_usage_iowait",
            "rename": "CPU_USAGE_IOWAIT",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DISK_USED_PERCENT",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED_PERCENT",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Create connectivity test script
cat > /opt/servicenow/mid-server/scripts/test_connectivity.sh << 'EOF'
#!/bin/bash

echo "Testing connectivity to internal resources..."

# Test DNS resolution
echo "Testing DNS resolution..."
nslookup starwars.local

# Test connectivity to domain controllers
echo "Testing connectivity to domain controllers..."
nc -zv 10.0.10.10 389  # LDAP
nc -zv 10.0.10.10 445  # SMB
nc -zv 10.0.20.10 389  # Secondary DC

# Test connectivity to databases
echo "Testing connectivity to databases..."
nc -zv 10.0.10.0/24 1433  # SQL Server
nc -zv 10.0.20.0/24 5432  # PostgreSQL
nc -zv 10.0.30.0/24 3306  # MySQL

# Test SNMP connectivity
echo "Testing SNMP connectivity..."
snmpwalk -v2c -c public 10.0.10.0/24 system 2>/dev/null | head -5

echo "Connectivity tests completed"
EOF

chmod +x /opt/servicenow/mid-server/scripts/test_connectivity.sh

# Create status check script
cat > /opt/servicenow/mid-server/scripts/check_status.sh << 'EOF'
#!/bin/bash

echo "MID Server Status Check"
echo "======================"

# Check if MID Server is downloaded
if [ -f /opt/servicenow/mid-server/agent/start.sh ]; then
    echo "✓ MID Server downloaded"
else
    echo "✗ MID Server not downloaded"
    echo "  Run: /opt/servicenow/mid-server/scripts/download_mid_server.sh <URL>"
fi

# Check Java version
java_version=$(java -version 2>&1 | head -n 1)
echo "Java Version: $java_version"

# Check connectivity to ServiceNow
if curl -s -o /dev/null -w "%{http_code}" ${SERVICENOW_INSTANCE}/stats.do | grep -q "200"; then
    echo "✓ Can reach ServiceNow instance"
else
    echo "✗ Cannot reach ServiceNow instance"
fi

# Check system resources
echo ""
echo "System Resources:"
echo "================="
echo "CPU: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
echo "Memory: $(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')"
echo "Disk: $(df -h / | awk 'NR==2{print $5}')"

# Check services
echo ""
echo "Services Status:"
echo "==============="
systemctl is-active --quiet sshd && echo "✓ SSH" || echo "✗ SSH"
systemctl is-active --quiet amazon-cloudwatch-agent && echo "✓ CloudWatch Agent" || echo "✗ CloudWatch Agent"

# Check logs
echo ""
echo "Recent Log Entries:"
echo "=================="
if [ -f /opt/servicenow/mid-server/agent/logs/agent0.log.0 ]; then
    tail -5 /opt/servicenow/mid-server/agent/logs/agent0.log.0
else
    echo "No MID Server logs found"
fi

echo ""
echo "Next Steps:"
echo "=========="
echo "1. Download MID Server from ServiceNow"
echo "2. Update configuration with ServiceNow credentials"
echo "3. Start MID Server service: sudo systemctl start mid-server"
echo "4. Check MID Server status in ServiceNow"
EOF

chmod +x /opt/servicenow/mid-server/scripts/check_status.sh

# Create README for MID Server setup
cat > /opt/servicenow/mid-server/README.md << EOF
# ServiceNow MID Server - R2-D2

This is the MID Server for the Star Wars Hackathon environment.

## Quick Start

1. **Download MID Server**
   \`\`\`bash
   sudo /opt/servicenow/mid-server/scripts/download_mid_server.sh <MID_SERVER_URL>
   \`\`\`

2. **Configure Credentials**
   - Edit /opt/servicenow/mid-server/agent/config.xml
   - Update username and password for ServiceNow instance

3. **Start MID Server**
   \`\`\`bash
   sudo systemctl start mid-server
   sudo systemctl enable mid-server
   \`\`\`

4. **Check Status**
   \`\`\`bash
   sudo /opt/servicenow/mid-server/scripts/check_status.sh
   \`\`\`

## Discovery Configuration

- Windows Domain: starwars.local
- Discovery User: svc-discovery
- Linux Discovery: rebel-discovery-user

## Scripts Available

- \`download_mid_server.sh\` - Download MID Server from ServiceNow
- \`get_aws_credentials.py\` - Retrieve credentials from AWS
- \`install_discovery_tools.sh\` - Install discovery utilities
- \`test_connectivity.sh\` - Test network connectivity
- \`check_status.sh\` - Check MID Server status

## Logs

- MID Server: /opt/servicenow/mid-server/agent/logs/
- CloudWatch: /aws/ec2/mid-server/${ENVIRONMENT}

## Support

Contact: rebel-it@starwars.local
EOF

# Set final permissions
chown -R midserver:midserver /opt/servicenow
chmod -R 755 /opt/servicenow/mid-server/scripts

# Create completion flag
echo "MID Server setup completed at $(date)" > /opt/servicenow/mid-server/setup_complete.txt

# Display completion message
echo "R2-D2 MID Server initial setup completed"
echo "Next steps:"
echo "1. Download MID Server from ServiceNow: /opt/servicenow/mid-server/scripts/download_mid_server.sh"
echo "2. Configure credentials in config.xml"
echo "3. Start MID Server: sudo systemctl start mid-server"
echo "4. Validate in ServiceNow"