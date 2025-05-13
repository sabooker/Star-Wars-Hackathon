# modules/security_groups/main.tf - Imperial and Rebel Security

# Windows Security Group - Imperial Forces
resource "aws_security_group" "windows_security" {
  name        = "${var.environment_name}-windows-security"
  description = "Security group for Windows servers"
  vpc_id      = var.vpc_id

  # RDP Access
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "RDP from VPC"
  }

  # WinRM
  ingress {
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "WinRM"
  }

  # AD Domain Services
  ingress {
    from_port   = 135
    to_port     = 135
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "RPC Endpoint Mapper"
  }

  ingress {
    from_port   = 139
    to_port     = 139
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "NetBIOS Session Service"
  }

  ingress {
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SMB"
  }

  ingress {
    from_port   = 464
    to_port     = 464
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Kerberos Password Change"
  }

  ingress {
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Kerberos"
  }

  ingress {
    from_port   = 88
    to_port     = 88
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "Kerberos UDP"
  }

  # LDAP
  ingress {
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "LDAP"
  }

  ingress {
    from_port   = 636
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "LDAPS"
  }

  # DNS
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "DNS TCP"
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "DNS UDP"
  }

  # Dynamic RPC
  ingress {
    from_port   = 49152
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Dynamic RPC"
  }

  # Web Services
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment_name}-windows-security"
  })
}

# Linux Security Group - Rebel Alliance
resource "aws_security_group" "linux_security" {
  name        = "${var.environment_name}-linux-security"
  description = "Security group for Linux servers"
  vpc_id      = var.vpc_id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SSH from VPC"
  }

  # Web Services
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # Application Ports
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Tomcat"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Node.js"
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS Alt"
  }

  # Database Ports (for client access)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "PostgreSQL"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "MySQL"
  }

  # Redis
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Redis"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment_name}-linux-security"
  })
}

# Database Security Group - Data Vaults
resource "aws_security_group" "database_security" {
  name        = "${var.environment_name}-database-security"
  description = "Security group for database servers"
  vpc_id      = var.vpc_id

  # SQL Server
  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SQL Server"
  }

  # SQL Server Analysis Services
  ingress {
    from_port   = 2383
    to_port     = 2383
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SQL Server Analysis Services"
  }

  # PostgreSQL
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "PostgreSQL"
  }

  # MySQL
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "MySQL"
  }

  # Oracle
  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Oracle"
  }

  # Allow all from Windows and Linux security groups
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.windows_security.id, aws_security_group.linux_security.id]
    description     = "All TCP from app servers"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment_name}-database-security"
  })
}

# MID Server Security Group - R2-D2 and C-3PO
resource "aws_security_group" "mid_server_security" {
  name        = "${var.environment_name}-mid-server-security"
  description = "Security group for ServiceNow MID Servers"
  vpc_id      = var.vpc_id

  # SSH Access for Linux MID Server
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Needs external access for management
    description = "SSH"
  }

  # RDP Access for Windows MID Server
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Needs external access for management
    description = "RDP"
  }

  # ServiceNow communication
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS to ServiceNow"
  }

  # Discovery ports - full VPC access
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "All TCP to VPC for discovery"
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "All UDP to VPC for discovery"
  }

  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
    description = "ICMP to VPC"
  }

  # DNS resolution
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS TCP"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS UDP"
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment_name}-mid-server-security"
  })
}

# Monitoring Security Group - C-3PO
resource "aws_security_group" "monitoring_security" {
  name        = "${var.environment_name}-monitoring-security"
  description = "Security group for monitoring servers"
  vpc_id      = var.vpc_id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SSH from VPC"
  }

  # Monitoring UI
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Grafana"
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Prometheus"
  }

  # Allow all monitoring traffic from VPC
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "All TCP to VPC for monitoring"
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
    description = "All UDP to VPC for monitoring"
  }

  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
    description = "ICMP to VPC"
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment_name}-monitoring-security"
  })
}

# Application Load Balancer Security Group
resource "aws_security_group" "alb_security" {
  name        = "${var.environment_name}-alb-security"
  description = "Security group for Application Load Balancers"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from Internet"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from Internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment_name}-alb-security"
  })
}

# Outputs
output "windows_security_group_id" {
  description = "Security group ID for Windows servers"
  value       = aws_security_group.windows_security.id
}

output "linux_security_group_id" {
  description = "Security group ID for Linux servers"
  value       = aws_security_group.linux_security.id
}

output "database_security_group_id" {
  description = "Security group ID for database servers"
  value       = aws_security_group.database_security.id
}

output "mid_server_security_group_id" {
  description = "Security group ID for MID Server"
  value       = aws_security_group.mid_server_security.id
}

output "monitoring_security_group_id" {
  description = "Security group ID for monitoring servers"
  value       = aws_security_group.monitoring_security.id
}

output "alb_security_group_id" {
  description = "Security group ID for Application Load Balancers"
  value       = aws_security_group.alb_security.id
}

# Variables
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "environment_name" {
  description = "Environment name for tagging"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}