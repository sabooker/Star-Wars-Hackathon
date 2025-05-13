# variables.tf - Star Wars Hackathon Variables

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_profile" {
  description = "AWS profile setup in ~/.aws/credentials"
  type        = string
  default     = "profile-582482956935"
}

variable "environment_name" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "star-wars-hackathon"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24", "10.0.40.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for deployment"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "lightsaber-key"
}

# Windows Instance Types - Varied for real-world scenario
variable "windows_instance_types" {
  description = "Instance types for Windows servers"
  type        = map(string)
  default = {
    "death-star-dc1"        = "t3.large"     # Primary Domain Controller
    "death-star-dc2"        = "t3.medium"    # Secondary Domain Controller
    "star-destroyer-sql"    = "m5.xlarge"    # SQL Server Database
    "imperial-cruiser-app"  = "m5.large"     # Legacy App Server (2016)
    "tie-fighter-web"       = "t3.large"     # IIS Web Server
    "at-at-walker-app"      = "m5.large"     # Modern App Server (2022)
    "storm-trooper-svc"     = "t3.medium"    # Service Host
    "imperial-shuttle-mgt"  = "t3.medium"    # Management Server
  }
}

# Linux Instance Types - Diverse ecosystem
variable "linux_instance_types" {
  description = "Instance types for Linux servers"
  type        = map(string)
  default = {
    "millennium-falcon-db"   = "m5.xlarge"    # PostgreSQL Database
    "x-wing-web"            = "t3.large"      # Apache Web Server
    "y-wing-app"            = "m5.large"      # Tomcat App Server
    "rebel-cruiser-app"     = "t3.large"      # Node.js App Server
    "mon-calamari-db"       = "m5.large"      # MySQL Database
    "a-wing-web"            = "t3.medium"     # Nginx Web Server
    "b-wing-app"            = "t3.medium"     # Java App Server
    "rebel-transport-cache" = "r5.large"      # Redis Cache Server
  }
}

# Database Instance Types
variable "database_instance_types" {
  description = "Instance types specifically for database servers"
  type        = map(string)
  default = {
    "death-star-core-sql"    = "r5.xlarge"    # Primary SQL Server
    "imperial-vault-sql"     = "r5.large"     # Secondary SQL Server
    "rebel-base-postgres"    = "r5.xlarge"    # Primary PostgreSQL
    "hidden-fortress-mysql"  = "r5.large"     # MySQL Database
    "jedi-archive-oracle"    = "r5.2xlarge"   # Oracle Database (if needed)
  }
}

# MID Server Configuration
variable "mid_server_instance_type" {
  description = "Instance type for ServiceNow MID Server"
  type        = string
  default     = "t3.large"
}

variable "servicenow_instance_url" {
  description = "URL of your ServiceNow instance"
  type        = string
  default     = "https://your-instance.service-now.com"
}

# Operating System Versions
variable "windows_os_versions" {
  description = "Windows Server versions to deploy"
  type        = map(string)
  default = {
    "2016" = "Windows_Server-2016-English-Full-Base-*"
    "2019" = "Windows_Server-2019-English-Full-Base-*"
    "2022" = "Windows_Server-2022-English-Full-Base-*"
  }
}

variable "linux_distributions" {
  description = "Linux distributions to deploy"
  type        = map(object({
    ami_name_pattern = string
    ami_owner       = string
  }))
  default = {
    "amazon-linux-2" = {
      ami_name_pattern = "amzn2-ami-hvm-*-x86_64-gp2"
      ami_owner       = "amazon"
    }
    "rhel-8" = {
      ami_name_pattern = "RHEL-8*_HVM-*-x86_64-*"
      ami_owner       = "309956199498"  # Red Hat owner ID
    }
    "rhel-9" = {
      ami_name_pattern = "RHEL-9*_HVM-*-x86_64-*"
      ami_owner       = "309956199498"
    }
    "ubuntu-2004" = {
      ami_name_pattern = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      ami_owner       = "099720109477"  # Canonical owner ID
    }
    "ubuntu-2204" = {
      ami_name_pattern = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      ami_owner       = "099720109477"
    }
  }
}

# Software Versions for SAM Pro Demo
variable "java_versions" {
  description = "Java versions to install across servers"
  type        = list(string)
  default     = ["8", "11", "17", "21"]
}

variable "database_versions" {
  description = "Database versions to deploy"
  type        = map(string)
  default = {
    "sql_server"  = "2019"
    "postgresql"  = "14"
    "mysql"       = "8.0"
    "oracle"      = "19c"
  }
}

# Security Software Simulation
variable "security_software" {
  description = "Security software to simulate for SAM Pro"
  type        = map(object({
    version = string
    vendor  = string
  }))
  default = {
    "blastshield" = {
      version = "5.4.2"
      vendor  = "Imperial Security Systems"
    }
    "forcefield" = {
      version = "3.2.1"
      vendor  = "Jedi Defense Corps"
    }
    "rebelguard" = {
      version = "2.1.8"
      vendor  = "Rebel Alliance Security"
    }
  }
}

# Tagging Strategy
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "Star-Wars-Hackathon"
    ManagedBy   = "Terraform"
    Purpose     = "ServiceNow-Discovery-POC"
    CostCenter  = "Rebel-Alliance-IT"
  }
}

# Discovery Configuration
variable "discovery_credentials" {
  description = "Credentials for ServiceNow Discovery"
  type        = map(object({
    username = string
    password = string
  }))
  default = {
    windows_domain = {
      username = "darth-vader"
      password = "Emp1reP@ss123!"
    }
    windows_local = {
      username = "empire-discovery-admin"
      password = "Emp1reD1sc0v3ryP@ss!"
    }
    linux_ssh = {
      username = "rebel-discovery-user"
      password = "R3belD1sc0v3ryP@ss!"
    }
  }
  sensitive = true
}

# Application Configurations
variable "applications" {
  description = "Applications to deploy for discovery"
  type        = map(object({
    port    = number
    path    = string
    version = string
  }))
  default = {
    "death-star-control" = {
      port    = 8080
      path    = "/death-star"
      version = "1.0.0"
    }
    "rebel-comms" = {
      port    = 3000
      path    = "/rebel-alliance"
      version = "2.1.5"
    }
    "jedi-council" = {
      port    = 8443
      path    = "/jedi"
      version = "3.0.0"
    }
  }
}