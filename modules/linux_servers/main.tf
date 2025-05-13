# modules/linux_servers/main.tf - Rebel Alliance Fleet

# Get AMIs for different Linux distributions
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
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

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "rhel_9" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat

  filter {
    name   = "name"
    values = ["RHEL-9*_HVM-*-x86_64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "ubuntu_2004" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# PostgreSQL Database on RHEL 8
resource "aws_instance" "millennium_falcon_db" {
  ami           = data.aws_ami.rhel_8.id
  instance_type = var.instance_types["millennium-falcon-db"]
  subnet_id     = var.private_subnet_ids[0]
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/userdata/postgresql_setup.sh", {
    instance_name     = "millennium-falcon-db"
    postgres_version  = "14"
    databases         = ["rebel_command", "jedi_archives", "resistance_data"]
    backup_enabled    = true
  })

  tags = merge(var.common_tags, {
    Name             = "millennium-falcon-db"
    OS               = "RHEL 8"
    Role             = "Database Server"
    Application      = "PostgreSQL 14"
    UpgradeCandidate = "false"
  })

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
    encrypted   = true
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 500
    volume_type = "gp3"
    iops        = 3000
    encrypted   = true
  }
}

# Apache Web Server on Ubuntu 22.04
resource "aws_instance" "x_wing_web" {
  ami           = data.aws_ami.ubuntu_2204.id
  instance_type = var.instance_types["x-wing-web"]
  subnet_id     = var.private_subnet_ids[1]
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/userdata/apache_setup.sh", {
    instance_name = "x-wing-web"
    websites = [
      {
        name   = "rebel-alliance-portal"
        domain = "rebels.starwars.local"
        port   = 80
      },
      {
        name   = "jedi-council"
        domain = "jedi.starwars.local"
        port   = 443
      }
    ]
    php_version = "8.1"
    ssl_enabled = true
  })

  tags = merge(var.common_tags, {
    Name             = "x-wing-web"
    OS               = "Ubuntu 22.04"
    Role             = "Web Server"
    Application      = "Apache/PHP"
    UpgradeCandidate = "false"
  })

  root_block_device {
    volume_size = 80
    encrypted   = true
  }
}

# Tomcat App Server on Amazon Linux 2
resource "aws_instance" "y_wing_app" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_types["y-wing-app"]
  subnet_id     = var.private_subnet_ids[0]
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/userdata/tomcat_setup.sh", {
    instance_name    = "y-wing-app"
    java_version     = "11"
    tomcat_version   = "9"
    applications     = ["RebelMissionControl", "ForceTracker", "XWingSimulator"]
    security_software = "RebelGuard"
    security_version  = "2.1.8"
  })

  tags = merge(var.common_tags, {
    Name             = "y-wing-app"
    OS               = "Amazon Linux 2"
    Role             = "Application Server"
    Application      = "Tomcat"
    UpgradeCandidate = "true"
    UpgradePriority  = "Medium"
  })

  root_block_device {
    volume_size = 100
    encrypted   = true
  }
}

# Node.js App Server on Ubuntu 20.04
resource "aws_instance" "rebel_cruiser_app" {
  ami           = data.aws_ami.ubuntu_2004.id
  instance_type = var.instance_types["rebel-cruiser-app"]
  subnet_id     = var.private_subnet_ids[1]
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/userdata/nodejs_setup.sh", {
    instance_name = "rebel-cruiser-app"
    node_version  = "18"
    applications = [
      {
        name = "rebel-communications"
        port = 3000
        repo = "https://github.com/rebel-alliance/comms-app"
      },
      {
        name = "resistance-tracker"
        port = 3001
        repo = "https://github.com/rebel-alliance/resistance-app"
      }
    ]
    pm2_enabled = true
  })

  tags = merge(var.common_tags, {
    Name             = "rebel-cruiser-app"
    OS               = "Ubuntu 20.04"
    Role             = "Application Server"
    Application      = "Node.js"
    UpgradeCandidate = "false"
  })

  root_block_device {
    volume_size = 80
    encrypted   = true
  }
}

# MySQL Database on RHEL 9
resource "aws_instance" "mon_calamari_db" {
  ami           = data.aws_ami.rhel_9.id
  instance_type = var.instance_types["mon-calamari-db"]
  subnet_id     = var.private_subnet_ids[0]
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/userdata/mysql_setup.sh", {
    instance_name    = "mon-calamari-db"
    mysql_version    = "8.0"
    databases        = ["fleet_registry", "star_charts", "rebel_intel"]
    replication_role = "master"
  })

  tags = merge(var.common_tags, {
    Name             = "mon-calamari-db"
    OS               = "RHEL 9"
    Role             = "Database Server"
    Application      = "MySQL 8.0"
    UpgradeCandidate = "false"
  })

  root_block_device {
    volume_size = 100
    encrypted   = true
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 300
    volume_type = "gp3"
    encrypted   = true
  }
}

# Nginx Web Server on Ubuntu 22.04
resource "aws_instance" "a_wing_web" {
  ami           = data.aws_ami.ubuntu_2204.id
  instance_type = var.instance_types["a-wing-web"]
  subnet_id     = var.private_subnet_ids[1]
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/userdata/nginx_setup.sh", {
    instance_name = "a-wing-web"
    sites = [
      {
        name      = "rebel-news"
        domain    = "news.rebels.local"
        upstream  = "rebel-cruiser-app:3000"
        cache     = true
      }
    ]
    ssl_enabled = true
    http2_enabled = true
  })

  tags = merge(var.common_tags, {
    Name             = "a-wing-web"
    OS               = "Ubuntu 22.04"
    Role             = "Web Server/Proxy"
    Application      = "Nginx"
    UpgradeCandidate = "false"
  })

  root_block_device {
    volume_size = 60
    encrypted   = true
  }
}

# Java App Server on RHEL 8
resource "aws_instance" "b_wing_app" {
  ami           = data.aws_ami.rhel_8.id
  instance_type = var.instance_types["b-wing-app"]
  subnet_id     = var.private_subnet_ids[0]
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/userdata/java_app_setup.sh", {
    instance_name     = "b-wing-app"
    java_version      = "17"
    app_server        = "wildfly"
    applications      = ["RebelFinance", "AllianceHR", "JediRecruitment"]
    jvm_heap_size     = "4g"
    security_software = "ForceField"
    security_version  = "3.2.1"
  })

  tags = merge(var.common_tags, {
    Name             = "b-wing-app"
    OS               = "RHEL 8"
    Role             = "Application Server"
    Application      = "WildFly/Java"
    UpgradeCandidate = "false"
    SecurityCompliant = "true"
  })

  root_block_device {
    volume_size = 100
    encrypted   = true
  }
}

# Redis Cache Server on Amazon Linux 2
resource "aws_instance" "rebel_transport_cache" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_types["rebel-transport-cache"]
  subnet_id     = var.private_subnet_ids[1]
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/userdata/redis_setup.sh", {
    instance_name = "rebel-transport-cache"
    redis_version = "7.0"
    cluster_mode  = false
    persistence   = true
    memory_policy = "allkeys-lru"
  })

  tags = merge(var.common_tags, {
    Name             = "rebel-transport-cache"
    OS               = "Amazon Linux 2"
    Role             = "Cache Server"
    Application      = "Redis"
    UpgradeCandidate = "false"
  })

  root_block_device {
    volume_size = 60
    encrypted   = true
  }
}

# Outputs
output "all_instance_ids" {
  description = "All Linux instance IDs"
  value = {
    millennium_falcon_db   = aws_instance.millennium_falcon_db.id
    x_wing_web            = aws_instance.x_wing_web.id
    y_wing_app            = aws_instance.y_wing_app.id
    rebel_cruiser_app     = aws_instance.rebel_cruiser_app.id
    mon_calamari_db       = aws_instance.mon_calamari_db.id
    a_wing_web            = aws_instance.a_wing_web.id
    b_wing_app            = aws_instance.b_wing_app.id
    rebel_transport_cache = aws_instance.rebel_transport_cache.id
  }
}

output "web_server_ids" {
  description = "Web server instance IDs"
  value = [
    aws_instance.x_wing_web.id,
    aws_instance.a_wing_web.id
  ]
}

output "app_server_ids" {
  description = "Application server instance IDs"
  value = [
    aws_instance.y_wing_app.id,
    aws_instance.rebel_cruiser_app.id,
    aws_instance.b_wing_app.id
  ]
}

output "database_server_ids" {
  description = "Database server instance IDs"
  value = [
    aws_instance.millennium_falcon_db.id,
    aws_instance.mon_calamari_db.id
  ]
}

output "instance_details" {
  description = "Detailed information about Linux instances"
  value = {
    for k, v in {
      millennium_falcon_db   = aws_instance.millennium_falcon_db
      x_wing_web            = aws_instance.x_wing_web
      y_wing_app            = aws_instance.y_wing_app
      rebel_cruiser_app     = aws_instance.rebel_cruiser_app
      mon_calamari_db       = aws_instance.mon_calamari_db
      a_wing_web            = aws_instance.a_wing_web
      b_wing_app            = aws_instance.b_wing_app
      rebel_transport_cache = aws_instance.rebel_transport_cache
    } : k => {
      id               = v.id
      private_ip       = v.private_ip
      instance_type    = v.instance_type
      os_version       = v.tags.OS
      role            = v.tags.Role
      application     = v.tags.Application
      upgrade_candidate = try(v.tags.UpgradeCandidate, "false") == "true"
    }
  }
}

# Variables
variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for Linux servers"
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
  description = "Instance types for Linux servers"
  type        = map(string)
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

