# modules/domain_controllers/main.tf - Imperial Command

# Get Windows Server AMIs
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

# Primary Domain Controller - Death Star
resource "aws_instance" "death_star_dc1" {
  ami           = data.aws_ami.windows_2019.id
  instance_type = var.instance_types["death-star-dc1"]
  subnet_id     = var.private_subnet_ids[0]
  key_name      = var.key_name
  private_ip    = "10.0.10.10"  # Static IP for primary DC

  vpc_security_group_ids = [var.security_group_id]

  user_data = templatefile("${path.module}/userdata/primary_dc_setup.ps1", {
    domain_name           = "starwars.local"
    domain_netbios_name   = "STARWARS"
    safe_mode_password    = var.safe_mode_password
    restore_mode_password = var.restore_mode_password
    instance_name         = "death-star-dc1"
    users = [
      {
        username    = "darth-vader"
        password    = var.domain_admin_password
        first_name  = "Darth"
        last_name   = "Vader"
        description = "Supreme Commander"
        groups      = ["Domain Admins", "Enterprise Admins", "Schema Admins"]
      },
      {
        username    = "emperor-palpatine"
        password    = var.domain_admin_password
        first_name  = "Emperor"
        last_name   = "Palpatine"
        description = "Emperor of the Galactic Empire"
        groups      = ["Domain Admins", "Enterprise Admins"]
      },
      {
        username    = "grand-moff-tarkin"
        password    = var.domain_user_password
        first_name  = "Grand Moff"
        last_name   = "Tarkin"
        description = "Death Star Commander"
        groups      = ["Domain Users", "Death Star Operators"]
      },
      {
        username    = "luke-skywalker"
        password    = var.domain_user_password
        first_name  = "Luke"
        last_name   = "Skywalker"
        description = "Jedi Knight"
        groups      = ["Domain Users", "Rebel Alliance"]
      },
      {
        username    = "leia-organa"
        password    = var.domain_user_password
        first_name  = "Princess Leia"
        last_name   = "Organa"
        description = "Rebel Leader"
        groups      = ["Domain Users", "Rebel Alliance"]
      },
      {
        username    = "han-solo"
        password    = var.domain_user_password
        first_name  = "Han"
        last_name   = "Solo"
        description = "Smuggler"
        groups      = ["Domain Users", "Millennium Falcon Crew"]
      }
    ]
    organizational_units = [
      "Imperial Forces",
      "Rebel Alliance",
      "Jedi Order",
      "Death Star",
      "Service Accounts",
      "Servers",
      "Workstations"
    ]
    groups = [
      {
        name        = "Death Star Operators"
        path        = "OU=Imperial Forces"
        description = "Death Star operational staff"
      },
      {
        name        = "Stormtroopers"
        path        = "OU=Imperial Forces"
        description = "Imperial Stormtrooper Corps"
      },
      {
        name        = "Rebel Alliance"
        path        = "OU=Rebel Alliance"
        description = "Members of the Rebel Alliance"
      },
      {
        name        = "Jedi Council"
        path        = "OU=Jedi Order"
        description = "Members of the Jedi Council"
      },
      {
        name        = "Millennium Falcon Crew"
        path        = "OU=Rebel Alliance"
        description = "Crew of the Millennium Falcon"
      }
    ]
    discovery_accounts = [
      {
        username    = "svc-discovery"
        password    = var.discovery_service_password
        description = "ServiceNow Discovery Service Account"
        ou         = "Service Accounts"
      },
      {
        username    = "svc-monitoring"
        password    = var.monitoring_service_password
        description = "Monitoring Service Account"
        ou         = "Service Accounts"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name             = "death-star-dc1"
    OS               = "Windows Server 2019"
    Role             = "Primary Domain Controller"
    Application      = "Active Directory"
    CriticalityLevel = "Critical"
    BackupRequired   = "true"
  })

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
    encrypted   = true
  }

  # SYSVOL and NTDS volume
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }
}

# Secondary Domain Controller - Death Star Backup
resource "aws_instance" "death_star_dc2" {
  ami           = data.aws_ami.windows_2022.id
  instance_type = var.instance_types["death-star-dc2"]
  subnet_id     = var.private_subnet_ids[1]
  key_name      = var.key_name
  private_ip    = "10.0.20.10"  # Static IP for secondary DC

  vpc_security_group_ids = [var.security_group_id]

  # Wait for primary DC to be ready
  depends_on = [aws_instance.death_star_dc1]

  user_data = templatefile("${path.module}/userdata/secondary_dc_setup.ps1", {
    domain_name          = "starwars.local"
    domain_netbios_name  = "STARWARS"
    primary_dc_ip        = aws_instance.death_star_dc1.private_ip
    safe_mode_password   = var.safe_mode_password
    domain_admin_user    = "darth-vader"
    domain_admin_pass    = var.domain_admin_password
    instance_name        = "death-star-dc2"
  })

  tags = merge(var.common_tags, {
    Name             = "death-star-dc2"
    OS               = "Windows Server 2022"
    Role             = "Secondary Domain Controller"
    Application      = "Active Directory"
    CriticalityLevel = "Critical"
    BackupRequired   = "true"
  })

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
    encrypted   = true
  }

  # SYSVOL and NTDS volume
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }
}

# Create DNS records for domain controllers
resource "aws_route53_zone" "starwars_local" {
  name = "starwars.local"

  vpc {
    vpc_id = var.vpc_id
  }

  tags = merge(var.common_tags, {
    Name = "starwars.local"
  })
}

resource "aws_route53_record" "dc1" {
  zone_id = aws_route53_zone.starwars_local.zone_id
  name    = "dc1.starwars.local"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.death_star_dc1.private_ip]
}

resource "aws_route53_record" "dc2" {
  zone_id = aws_route53_zone.starwars_local.zone_id
  name    = "dc2.starwars.local"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.death_star_dc2.private_ip]
}

# Outputs
output "primary_dc_id" {
  description = "Primary domain controller instance ID"
  value       = aws_instance.death_star_dc1.id
}

output "secondary_dc_id" {
  description = "Secondary domain controller instance ID"
  value       = aws_instance.death_star_dc2.id
}

output "primary_dc_private_ip" {
  description = "Primary domain controller private IP"
  value       = aws_instance.death_star_dc1.private_ip
}

output "secondary_dc_private_ip" {
  description = "Secondary domain controller private IP"
  value       = aws_instance.death_star_dc2.private_ip
}

output "domain_name" {
  description = "Active Directory domain name"
  value       = "starwars.local"
}

output "domain_dns_ips" {
  description = "DNS server IPs for domain"
  value = [
    aws_instance.death_star_dc1.private_ip,
    aws_instance.death_star_dc2.private_ip
  ]
}

# Variables
variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for domain controllers"
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

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "instance_types" {
  description = "Instance types for domain controllers"
  type        = map(string)
  default = {
    "death-star-dc1" = "t3.large"
    "death-star-dc2" = "t3.medium"
  }
}

variable "safe_mode_password" {
  description = "DSRM password"
  type        = string
  sensitive   = true
  default     = "Emp1reD$RM123!"
}

variable "restore_mode_password" {
  description = "Restore mode password"
  type        = string
  sensitive   = true
  default     = "Emp1reR3st0re!"
}

variable "domain_admin_password" {
  description = "Domain admin password"
  type        = string
  sensitive   = true
  default     = "Emp1reAdm1n123!"
}

variable "domain_user_password" {
  description = "Standard domain user password"
  type        = string
  sensitive   = true
  default     = "R3b3lP@ss123!"
}

variable "discovery_service_password" {
  description = "ServiceNow discovery service account password"
  type        = string
  sensitive   = true
  default     = "D1sc0v3ryP@ss!"
}

variable "monitoring_service_password" {
  description = "Monitoring service account password"
  type        = string
  sensitive   = true
  default     = "M0n1t0r1ngP@ss!"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}