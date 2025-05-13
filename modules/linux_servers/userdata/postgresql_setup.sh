# modules/linux_servers/userdata/postgresql_setup.sh
#!/bin/bash

# Set variables
INSTANCE_NAME="${instance_name}"
POSTGRES_VERSION="${postgres_version}"
BACKUP_ENABLED="${backup_enabled}"

# Update hostname
hostnamectl set-hostname $INSTANCE_NAME

# Update system
yum update -y || apt-get update && apt-get upgrade -y

# Determine OS type
if [ -f /etc/redhat-release ]; then
    OS_TYPE="rhel"
elif [ -f /etc/lsb-release ]; then
    OS_TYPE="ubuntu"
else
    OS_TYPE="unknown"
fi

# Create discovery user
useradd -m -s /bin/bash rebel-discovery-user
echo "rebel-discovery-user:R3belD1sc0v3ryP@ss!" | chpasswd
echo "rebel-discovery-user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/rebel-discovery-user
chmod 0440 /etc/sudoers.d/rebel-discovery-user

# Configure SSH for discovery
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Install PostgreSQL based on OS
if [ "$OS_TYPE" = "rhel" ]; then
    # Install PostgreSQL on RHEL/CentOS/Amazon Linux
    yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
    yum install -y postgresql${POSTGRES_VERSION}-server postgresql${POSTGRES_VERSION}-contrib
    /usr/pgsql-${POSTGRES_VERSION}/bin/postgresql-${POSTGRES_VERSION}-setup initdb
    systemctl enable postgresql-${POSTGRES_VERSION}
    systemctl start postgresql-${POSTGRES_VERSION}
    
    PGDATA="/var/lib/pgsql/${POSTGRES_VERSION}/data"
    PGBIN="/usr/pgsql-${POSTGRES_VERSION}/bin"
elif [ "$OS_TYPE" = "ubuntu" ]; then
    # Install PostgreSQL on Ubuntu
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
    apt-get update
    apt-get install -y postgresql-${POSTGRES_VERSION} postgresql-contrib-${POSTGRES_VERSION}
    
    PGDATA="/var/lib/postgresql/${POSTGRES_VERSION}/main"
    PGBIN="/usr/lib/postgresql/${POSTGRES_VERSION}/bin"
fi

# Configure PostgreSQL
cat >> $PGDATA/postgresql.conf << EOF

# Performance settings
shared_buffers = 2GB
effective_cache_size = 8GB
maintenance_work_mem = 512MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 50MB
min_wal_size = 1GB
max_wal_size = 4GB

# Monitoring
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all

# Logging
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB
log_line_prefix = '%m [%p] %u@%d '
log_statement = 'ddl'
log_duration = on
log_min_duration_statement = 100

# Network settings
listen_addresses = '*'
EOF

# Configure authentication
cat > $PGDATA/pg_hba.conf << EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     peer
host    all             all             127.0.0.1/32            md5
host    all             all             10.0.0.0/16             md5
host    all             all             ::1/128                 md5
EOF

# Restart PostgreSQL to apply configurations
systemctl restart postgresql-${POSTGRES_VERSION}

# Create databases and users
sudo -u postgres psql << EOF
-- Create replication user
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'R3pl1c@t0rP@ss!';

-- Create backup user
CREATE ROLE backup_user WITH LOGIN PASSWORD 'B@ckupP@ss123!';
ALTER ROLE backup_user SET default_transaction_read_only = on;

-- Create application users
CREATE ROLE rebel_app WITH LOGIN PASSWORD 'R3b3lAppP@ss!';
CREATE ROLE jedi_app WITH LOGIN PASSWORD 'J3d1AppP@ss!';

-- Create databases
%{ for db in databases ~}
CREATE DATABASE ${db.name} WITH ENCODING='${db.encoding}' LC_COLLATE='en_US.UTF-8' LC_CTYPE='en_US.UTF-8';
GRANT CONNECT ON DATABASE ${db.name} TO rebel_app;
GRANT CONNECT ON DATABASE ${db.name} TO jedi_app;
GRANT CONNECT ON DATABASE ${db.name} TO backup_user;
%{ endfor ~}

-- Enable extensions
\c rebel_command
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS uuid-ossp;

\c jedi_council
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS uuid-ossp;
EOF

# Set up data directories on attached volumes
systemctl stop postgresql-${POSTGRES_VERSION}

# Move data to dedicated volume
if [ -b /dev/xvdf ]; then
    mkfs.ext4 /dev/xvdf
    mkdir -p /pgdata
    mount /dev/xvdf /pgdata
    echo "/dev/xvdf /pgdata ext4 defaults,nofail 0 2" >> /etc/fstab
    
    # Move PostgreSQL data
    mv $PGDATA /pgdata/
    ln -s /pgdata/$(basename $PGDATA) $PGDATA
fi

# Set up WAL archive on separate volume
if [ -b /dev/xvdg ]; then
    mkfs.ext4 /dev/xvdg
    mkdir -p /pgwal
    mount /dev/xvdg /pgwal
    echo "/dev/xvdg /pgwal ext4 defaults,nofail 0 2" >> /etc/fstab
    
    mkdir -p /pgwal/archive
    chown postgres:postgres /pgwal/archive
fi

# Set up backup volume
if [ -b /dev/xvdh ]; then
    mkfs.ext4 /dev/xvdh
    mkdir -p /pgbackup
    mount /dev/xvdh /pgbackup
    echo "/dev/xvdh /pgbackup ext4 defaults,nofail 0 2" >> /etc/fstab
    
    mkdir -p /pgbackup/base
    mkdir -p /pgbackup/wal
    chown -R postgres:postgres /pgbackup
fi

# Configure archiving and backup
if [ "$BACKUP_ENABLED" = "true" ]; then
    cat >> $PGDATA/postgresql.conf << EOF

# Archive settings
archive_mode = on
archive_command = 'test ! -f /pgwal/archive/%f && cp %p /pgwal/archive/%f'
archive_timeout = 300
EOF
fi

# Start PostgreSQL
systemctl start postgresql-${POSTGRES_VERSION}

# Create backup script
cat > /usr/local/bin/pg_backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/pgbackup/base"
WAL_BACKUP_DIR="/pgbackup/wal"
DATE=$(date +%Y%m%d_%H%M%S)

# Perform base backup
sudo -u postgres pg_basebackup -D $BACKUP_DIR/backup_$DATE -Ft -z -P

# Backup WAL files
rsync -av /pgwal/archive/ $WAL_BACKUP_DIR/

# Clean old backups (keep 7 days)
find $BACKUP_DIR -name "backup_*" -mtime +7 -delete
find $WAL_BACKUP_DIR -name "*.backup" -mtime +7 -delete

echo "Backup completed at $(date)"
EOF

chmod +x /usr/local/bin/pg_backup.sh

# Schedule daily backups
echo "0 2 * * * /usr/local/bin/pg_backup.sh >> /var/log/pg_backup.log 2>&1" | crontab -

# Install monitoring tools
if [ "$OS_TYPE" = "rhel" ]; then
    yum install -y pg_top iotop htop sysstat
else
    apt-get install -y pgtop iotop htop sysstat
fi

# Install simulated security software
mkdir -p /opt/rebel-shield/{bin,conf,logs}
cat > /opt/rebel-shield/version.txt << EOF
3.2.1
EOF

cat > /opt/rebel-shield/conf/shield.conf << EOF
# Rebel Shield Configuration
version=3.2.1
vendor=Rebel Alliance Security
mode=active
scan_interval=300
update_server=updates.rebels.local
features:
  - database_firewall
  - query_analysis
  - intrusion_detection
  - compliance_scanning
EOF

# Create systemd service for security software
cat > /etc/systemd/system/rebel-shield.service << EOF
[Unit]
Description=Rebel Shield Security Software
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/echo "Rebel Shield Active"
RemainAfterExit=yes
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl enable rebel-shield
systemctl start rebel-shield

# Configure SNMP for monitoring
if [ "$OS_TYPE" = "rhel" ]; then
    yum install -y net-snmp net-snmp-utils
else
    apt-get install -y snmpd snmp
fi

# Configure SNMP
cat > /etc/snmp/snmpd.conf << EOF
syslocation Rebel Base Data Center
syscontact rebel-it@rebels.local
rocommunity public 10.0.0.0/16
EOF

systemctl enable snmpd
systemctl start snmpd

# Create database info file for discovery
cat > /var/lib/postgresql/database_info.json << EOF
{
  "instance_name": "${INSTANCE_NAME}",
  "engine": "PostgreSQL",
  "version": "${POSTGRES_VERSION}",
  "port": 5432,
  "databases": [
%{ for idx, db in databases ~}
    {
      "name": "${db.name}",
      "size": "${db.size}",
      "encoding": "${db.encoding}"
    }%{ if idx < length(databases) - 1 },%{ endif }
%{ endfor ~}
  ],
  "replication": {
    "enabled": true,
    "role": "primary"
  },
  "backup": {
    "enabled": ${BACKUP_ENABLED},
    "schedule": "daily",
    "retention": "7 days"
  }
}
EOF

# Set completion flag
echo "PostgreSQL deployment completed at $(date)" > /tmp/deployment_complete.txt

# Log completion
logger "PostgreSQL ${POSTGRES_VERSION} installation completed on ${INSTANCE_NAME}"