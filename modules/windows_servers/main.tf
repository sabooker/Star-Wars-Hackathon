# modules/windows_servers/main.tf - Imperial Fleet

# Get AMIs for different Windows versions
data "aws_ami" "windows_2016" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "windows_2019" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# SQL Server with Windows Server 2022
resource "aws_instance" "star_destroyer_sql" {
  ami           = data.aws_ami.windows_2022.id
  instance_type = var.instance_types["star-destroyer-sql"]
  subnet_id     = var.private_subnet_ids[0]
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/userdata/sql_server.ps1", {
    domain_controller_ip = var.domain_controller_ip
    instance_name       = "star-destroyer-sql"
    sql_version        = "2019"
    databases          = ["DeathStarPlans", "ImperialFleet", "TrooperRegistry"]
  })

  tags = merge(var.common_tags, {
    Name             = "star-destroyer-sql"
    OS               = "Windows Server 2022"
    Role             = "Database Server"
    Application      = "SQL Server 2019"
    UpgradeCandidate = "false"
  })

  root_block_device {
    volume_size = 200
    encrypted   = true
  }

  # Additional data disk for SQL databases
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 500
    volume_type = "gp3"
    encrypted   = true
  }
}

# Legacy App Server with Windows 2016
resource "aws_instance" "imperial_cruiser_app" {
  ami           = data.aws_ami.windows_2016.id
  instance_type = var.instance_types["imperial-cruiser-app"]
  subnet_id     = var.private_subnet_ids[1]
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/userdata/legacy_app_server.ps1", {
    domain_controller_ip = var.domain_controller_ip
    instance_name       = "imperial-cruiser-app"
    java_version        = "8"
    app_name           = "LegacyEmpireControl"
  })

  tags = merge(var.common_tags, {
    Name             = "imperial-cruiser-app"
    OS               = "Windows Server 2016"
    Role             = "Application Server"
    Application      = "Legacy Java App"
    UpgradeCandidate = "true"
    UpgradePriority  = "High"
  })

  root_block_device {
    volume_size = 100
    encrypted   = true
  }
}

# Modern Web Server with IIS
resource "aws_instance" "tie_fighter_web" {
  ami           = data.aws_ami.windows_2019.id
  instance_type = var.instance_types["tie-fighter-web"]
  subnet_id     = var.private_subnet_ids[0]
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/userdata/iis_web_server.ps1", {
    domain_controller_ip = var.domain_controller_ip
    instance_name       = "tie-fighter-web"
    websites = [
      {
        name = "DeathStarPortal"
        port = 80
        path = "C:\\inetpub\\deathstar"
      },
      {
        name = "ImperialCommand"
        port = 443
        path = "C:\\inetpub\\imperial"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name             = "tie-fighter-web"
    OS               = "Windows Server 2019"
    Role             = "Web Server"
    Application      = "IIS"
    UpgradeCandidate = "false"
  })

  root_block_device {
    volume_size = 80
    encrypted   = true
  }
}

# Modern App Server with Windows 2022
resource "aws_instance" "at_at_walker_app" {
  ami           = data.aws_ami.windows_2022.id
  instance_type = var.instance_types["at-at-walker-app"]
  subnet_id     = var.private_subnet_ids[1]
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/userdata/modern_app_server.ps1", {
    domain_controller_ip = var.domain_controller_ip
    instance_name       = "at-at-walker-app"
    java_version        = "17"
    app_name           = "ImperialFleetManager"
    security_software   = "BlastShield"
    security_version    = "5.4.2"
  })

  tags = merge(var.common_tags, {
    Name             = "at-at-walker-app"
    OS               = "Windows Server 2022"
    Role             = "Application Server"
    Application      = "Modern Java App"
    UpgradeCandidate = "false"
    SecurityCompliant = "true"
  })

  root_block_device {
    volume_size = 100
    encrypted   = true
  }
}

# Service Host Server
resource "aws_instance" "storm_trooper_svc" {
  ami           = data.aws_ami.windows_2019.id
  instance_type = var.instance_types["storm-trooper-svc"]
  subnet_id     = var.private_subnet_ids[0]
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/userdata/service_host.ps1", {
    domain_controller_ip = var.domain_controller_ip
    instance_name       = "storm-trooper-svc"
    services = [
      "ImperialMessageQueue",
      "TrooperDeploymentService",
      "DeathStarMonitoring"
    ]
  })

  tags = merge(var.common_tags, {
    Name             = "storm-trooper-svc"
    OS               = "Windows Server 2019"
    Role             = "Service Host"
    Application      = "Windows Services"
    UpgradeCandidate = "false"
  })

  root_block_device {
    volume_size = 80
    encrypted   = true
  }
}

# Management Server (this is where your snippet started)
resource "aws_instance" "imperial_shuttle_mgt" {
  ami           = data.aws_ami.windows_2022.id
  instance_type = var.instance_types["imperial-shuttle-mgt"]
  subnet_id     = var.private_subnet_ids[1]
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/userdata/management_server.ps1", {
    domain_controller_ip = var.domain_controller_ip
    instance_name       = "imperial-shuttle-mgt"
    management_tools = [
      "SCCM",
      "WSUS",
      "ImperialMonitoring"
    ]
  })

  tags = merge(var.common_tags, {
    Name             = "imperial-shuttle-mgt"
    OS               = "Windows Server 2022"
    Role             = "Management Server"
    Application      = "System Center"
    UpgradeCandidate = "false"
  })

  root_block_device {
    volume_size = 150
    encrypted   = true
  }
}

# Secondary SQL Server
resource "aws_instance" "imperial_vault_sql" {
  ami           = data.aws_ami.windows_2019.id
  instance_type = var.database_instance_types["imperial-vault-sql"]
  subnet_id     = var.private_subnet_ids[0]
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/userdata/sql_server.ps1", {
    domain_controller_ip = var.domain_controller_ip
    instance_name       = "imperial-vault-sql"
    sql_version        = "2017"
    databases          = ["ImperialVault", "SithArchives", "EmpireSecrets"]
  })

  tags = merge(var.common_tags, {
    Name             = "imperial-vault-sql"
    OS               = "Windows Server 2019"
    Role             = "Database Server"
    Application      = "SQL Server 2017"
    UpgradeCandidate = "true"
    UpgradePriority  = "Medium"
  })

  root_block_device {
    volume_size = 200
    encrypted   = true
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 300
    volume_type = "gp3"
    encrypted   = true
  }
}

# Outputs
output "all_instance_ids" {
  description = "All Windows instance IDs"
  value = {
    star_destroyer_sql    = aws_instance.star_destroyer_sql.id
    imperial_cruiser_app  = aws_instance.imperial_cruiser_app.id
    tie_fighter_web       = aws_instance.tie_fighter_web.id
    at_at_walker_app      = aws_instance.at_at_walker_app.id
    storm_trooper_svc     = aws_instance.storm_trooper_svc.id
    imperial_shuttle_mgt  = aws_instance.imperial_shuttle_mgt.id
    imperial_vault_sql    = aws_instance.imperial_vault_sql.id
  }
}

output "web_server_ids" {
  description = "Web server instance IDs"
  value = [aws_instance.tie_fighter_web.id]
}

output "app_server_ids" {
  description = "Application server instance IDs"
  value = [
    aws_instance.imperial_cruiser_app.id,
    aws_instance.at_at_walker_app.id
  ]
}

output "instance_details" {
  description = "Detailed information about Windows instances"
  value = {
    star_destroyer_sql = {
      id               = aws_instance.star_destroyer_sql.id
      private_ip       = aws_instance.star_destroyer_sql.private_ip
      instance_type    = aws_instance.star_destroyer_sql.instance_type
      os_version       = "Windows Server 2022"
      role            = "SQL Server 2019"
      upgrade_candidate = false
    }
    imperial_cruiser_app = {
      id               = aws_instance.imperial_cruiser_app.id
      private_ip       = aws_instance.imperial_cruiser_app.private_ip
      instance_type    = aws_instance.imperial_cruiser_app.instance_type
      os_version       = "Windows Server 2016"
      role            = "Legacy App Server"
      upgrade_candidate = true
    }
    tie_fighter_web = {
      id               = aws_instance.tie_fighter_web.id
      private_ip       = aws_instance.tie_fighter_web.private_ip
      instance_type    = aws_instance.tie_fighter_web.instance_type
      os_version       = "Windows Server 2019"
      role            = "IIS Web Server"
      upgrade_candidate = false
    }
    at_at_walker_app = {
      id               = aws_instance.at_at_walker_app.id
      private_ip       = aws_instance.at_at_walker_app.private_ip
      instance_type    = aws_instance.at_at_walker_app.instance_type
      os_version       = "Windows Server 2022"
      role            = "Modern App Server"
      upgrade_candidate = false
    }
  }
}

# Variables
variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for Windows servers"
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

variable "instance_types" {
  description = "Instance types for Windows servers"
  type        = map(string)
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
