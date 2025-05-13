# modules/databases/main.tf - Data Vaults

# Data sources for AMIs
data "aws_ami" "windows_sql_2019" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-SQL_2019_*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "rhel_8" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat

  filter {
    name   = "name"
    values = ["RHEL-8*_HVM-*-x86_64-*"]
  }
}

data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Primary SQL Server Database - Death Star Core
resource "aws_instance" "death_star_core_sql" {
  ami           = data.aws_ami.windows_sql_2019.id
  instance_type = var.database_instance_types["death-star-core-sql"]
  subnet_id     = var.private_subnet_ids[0]
  key_name      = var.key_name

  vpc_security_group_ids = [var.windows_security_group]

  user_data = templatefile("${path.module}/userdata/sql_server_enterprise.ps1", {
    domain_controller_ip = var.domain_controller_ip
    instance_name       = "death-star-core-sql"
    sql_instance        = "DEATHSTAR"
    sql_version         = "2019"
    databases = [
      {
        name = "EmpireCore"
        size = "50GB"
        purpose = "Central Empire Database"
      },
      {
        name = "ImperialFleet"
        size = "100GB"
        purpose = "Fleet Management"
      },
      {
        name = "TrooperRegistry"
        size = "75GB"
        purpose = "Stormtrooper Records"
      },
      {
        name = "SithArchives"
        size = "200GB"
        purpose = "Dark Side Knowledge"
      }
    ]
    alwayson_enabled = true
    backup_encryption = true
  })

  tags = merge(var.common_tags, {
    Name              = "death-star-core-sql"
    OS                = "Windows Server 2019"
    Role              = "Primary Database"
    Application       = "SQL Server 2019 Enterprise"
    DatabaseEngine    = "SQL Server"
    CriticalityLevel  = "High"
    BackupRequired    = "true"
    HAEnabled         = "true"
  })

  root_block_device {
    volume_size = 200
    volume_type = "io2"
    iops        = 3000
    encrypted   = true
  }

  # Data drive
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 1000
    volume_type = "io2"
    iops        = 10000
    encrypted   = true
  }

  # Log drive
  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = 500
    volume_type = "io2"
    iops        = 5000
    encrypted   = true
  }

  # TempDB drive
  ebs_block_device {
    device_name = "/dev/sdh"
    volume_size = 200
    volume_type = "gp3"
    iops        = 3000
    encrypted   = true
  }
}

# Primary PostgreSQL Database - Rebel Base
resource "aws_instance" "rebel_base_postgres" {
  ami           = data.aws_ami.rhel_8.id
  instance_type = var.database_instance_types["rebel-base-postgres"]
  subnet_id     = var.private_subnet_ids[1]
  key_name      = var.key_name

  vpc_security_group_ids = [var.linux_security_group]

  user_data = templatefile("${path.module}/userdata/postgresql_enterprise.sh", {
    instance_name    = "rebel-base-postgres"
    postgres_version = "14"
    cluster_name     = "rebel_alliance"
    databases = [
      {
        name = "rebel_command"
        size = "100GB"
        encoding = "UTF8"
      },
      {
        name = "jedi_council"
        size = "50GB"
        encoding = "UTF8"
      },
      {
        name = "resistance_intel"
        size = "200GB"
        encoding = "UTF8"
      },
      {
        name = "starfighter_logs"
        size = "150GB"
        encoding = "UTF8"
      }
    ]
    replication_enabled = true
    ssl_enabled        = true
    backup_retention   = "30 days"
    monitoring_enabled = true
  })

  tags = merge(var.common_tags, {
    Name              = "rebel-base-postgres"
    OS                = "RHEL 8"
    Role              = "Primary Database"
    Application       = "PostgreSQL 14"
    DatabaseEngine    = "PostgreSQL"
    CriticalityLevel  = "High"
    BackupRequired    = "true"
    HAEnabled         = "true"
  })

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
    encrypted   = true
  }

  # Data directory
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 1000
    volume_type = "io2"
    iops        = 10000
    encrypted   = true
  }

  # WAL logs
  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = 500
    volume_type = "io2"
    iops        = 5000
    encrypted   = true
  }

  # Backup volume
  ebs_block_device {
    device_name = "/dev/sdh"
    volume_size = 1500
    volume_type = "gp3"
    encrypted   = true
  }
}

# MySQL Database - Hidden Fortress
resource "aws_instance" "hidden_fortress_mysql" {
  ami           = data.aws_ami.ubuntu_2204.id
  instance_type = var.database_instance_types["hidden-fortress-mysql"]
  subnet_id     = var.private_subnet_ids[0]
  key_name      = var.key_name

  vpc_security_group_ids = [var.linux_security_group]

  user_data = templatefile("${path.module}/userdata/mysql_enterprise.sh", {
    instance_name = "hidden-fortress-mysql"
    mysql_version = "8.0"
    databases = [
      {
        name = "rebel_communications"
        charset = "utf8mb4"
        collation = "utf8mb4_unicode_ci"
      },
      {
        name = "supply_logistics"
        charset = "utf8mb4"
        collation = "utf8mb4_unicode_ci"
      },
      {
        name = "mission_planning"
        charset = "utf8mb4"
        collation = "utf8mb4_unicode_ci"
      }
    ]
    innodb_buffer_pool_size = "8G"
    max_connections        = "500"
    replication_enabled    = true
    binlog_format         = "ROW"
    gtid_mode            = "ON"
  })

  tags = merge(var.common_tags, {
    Name              = "hidden-fortress-mysql"
    OS                = "Ubuntu 22.04"
    Role              = "Database Server"
    Application       = "MySQL 8.0"
    DatabaseEngine    = "MySQL"
    CriticalityLevel  = "Medium"
    BackupRequired    = "true"
  })

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
    encrypted   = true
  }

  # Data directory
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 500
    volume_type = "gp3"
    iops        = 3000
    encrypted   = true
  }

  # Binary logs
  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = 200
    volume_type = "gp3"
    encrypted   = true
  }
}

# Oracle Database - Jedi Archive (Optional, for demonstration)
resource "aws_instance" "jedi_archive_oracle" {
  count         = var.deploy_oracle ? 1 : 0
  ami           = data.aws_ami.rhel_8.id
  instance_type = var.database_instance_types["jedi-archive-oracle"]
  subnet_id     = var.private_subnet_ids[1]
  key_name      = var.key_name

  vpc_security_group_ids = [var.linux_security_group]

  user_data = templatefile("${path.module}/userdata/oracle_setup.sh", {
    instance_name   = "jedi-archive-oracle"
    oracle_version  = "19c"
    oracle_edition  = "enterprise"
    databases = [
      {
        name = "JEDIARCH"
        size = "500GB"
        pdb_name = "JEDIPDB"
      }
    ]
    memory_target = "8G"
    processes    = "500"
  })

  tags = merge(var.common_tags, {
    Name              = "jedi-archive-oracle"
    OS                = "RHEL 8"
    Role              = "Database Server"
    Application       = "Oracle 19c"
    DatabaseEngine    = "Oracle"
    CriticalityLevel  = "High"
    BackupRequired    = "true"
  })

  root_block_device {
    volume_size = 150
    volume_type = "gp3"
    encrypted   = true
  }

  # Oracle data files
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 1000
    volume_type = "io2"
    iops        = 10000
    encrypted   = true
  }

  # Fast recovery area
  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = 500
    volume_type = "gp3"
    encrypted   = true
  }
}

# Outputs
output "all_instance_ids" {
  description = "All database instance IDs"
  value = merge(
    {
      death_star_core_sql   = aws_instance.death_star_core_sql.id
      rebel_base_postgres   = aws_instance.rebel_base_postgres.id
      hidden_fortress_mysql = aws_instance.hidden_fortress_mysql.id
    },
    var.deploy_oracle ? {
      jedi_archive_oracle = aws_instance.jedi_archive_oracle[0].id
    } : {}
  )
}

output "sql_server_ids" {
  description = "SQL Server instance IDs"
  value = [aws_instance.death_star_core_sql.id]
}

output "postgresql_ids" {
  description = "PostgreSQL instance IDs"
  value = [aws_instance.rebel_base_postgres.id]
}

output "mysql_ids" {
  description = "MySQL instance IDs"
  value = [aws_instance.hidden_fortress_mysql.id]
}

output "instance_details" {
  description = "Detailed information about database instances"
  value = merge(
    {
      death_star_core_sql = {
        id                = aws_instance.death_star_core_sql.id
        private_ip        = aws_instance.death_star_core_sql.private_ip
        instance_type     = aws_instance.death_star_core_sql.instance_type
        os_version        = "Windows Server 2019"
        database_engine   = "SQL Server 2019 Enterprise"
        criticality_level = "High"
        ha_enabled        = true
      }
      rebel_base_postgres = {
        id                = aws_instance.rebel_base_postgres.id
        private_ip        = aws_instance.rebel_base_postgres.private_ip
        instance_type     = aws_instance.rebel_base_postgres.instance_type
        os_version        = "RHEL 8"
        database_engine   = "PostgreSQL 14"
        criticality_level = "High"
        ha_enabled        = true
      }
      hidden_fortress_mysql = {
        id                = aws_instance.hidden_fortress_mysql.id
        private_ip        = aws_instance.hidden_fortress_mysql.private_ip
        instance_type     = aws_instance.hidden_fortress_mysql.instance_type
        os_version        = "Ubuntu 22.04"
        database_engine   = "MySQL 8.0"
        criticality_level = "Medium"
        ha_enabled        = false
      }
    },
    var.deploy_oracle ? {
      jedi_archive_oracle = {
        id                = aws_instance.jedi_archive_oracle[0].id
        private_ip        = aws_instance.jedi_archive_oracle[0].private_ip
        instance_type     = aws_instance.jedi_archive_oracle[0].instance_type
        os_version        = "RHEL 8"
        database_engine   = "Oracle 19c"
        criticality_level = "High"
        ha_enabled        = false
      }
    } : {}
  )
}

# Variables
variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "windows_security_group" {
  description = "Security group ID for Windows database servers"
  type        = string
}

variable "linux_security_group" {
  description = "Security group ID for Linux database servers"
  type        = string
}

variable "domain_controller_ip" {
  description = "IP address of the domain controller"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "environment_name" {
  description = "Environment name for tagging"
  type        = string
}

variable "database_instance_types" {
  description = "Instance types for database servers"
  type        = map(string)
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "deploy_oracle" {
  description = "Whether to deploy Oracle database"
  type        = bool
  default     = false
}