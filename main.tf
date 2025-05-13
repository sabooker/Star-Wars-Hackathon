# MID Servers - R2-D2 (Linux) and C-3PO (Windows)
module "mid_server_linux" {
  source = "./modules/mid_server"
  
  public_subnet_id     = module.vpc.public_subnet_ids[0]
  security_group_id    = module.security_groups.mid_server_security_group_id
  key_name            = var.key_name
  environment_name    = var.environment_name
  instance_type       = var.mid_server_instance_type
  servicenow_instance = var.servicenow_instance_url
}

module "mid_server_windows" {
  source = "./modules/mid_server_windows"
  
  public_subnet_id     = module.vpc.public_subnet_ids[1]
  security_group_id    = module.security_groups.mid_server_security_group_id
  key_name            = var.key_name
  environment_name    = var.environment_name
  instance_type       = var.mid_server_instance_type
  servicenow_instance = var.servicenow_instance_url
  domain_controller_ip = module.domain_controllers.primary_dc_private_ip
}# main.tf - Star Wars Hackathon Infrastructure



# VPC Module - The Galaxy
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# Security Groups - Imperial and Rebel Forces
module "security_groups" {
  source           = "./modules/security_groups"
  vpc_cidr         = var.vpc_cidr
  vpc_id           = module.vpc.vpc_id
  environment_name = var.environment_name
}

# Domain Controllers - The Empire
module "domain_controllers" {
  source = "./modules/domain_controllers"
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  security_group_id   = module.security_groups.windows_security_group_id
  key_name            = var.key_name
  environment_name    = var.environment_name
}

# Windows Servers - Imperial Fleet
module "windows_servers" {
  source = "./modules/windows_servers"
  database_instance_types = var.database_instance_types
  private_subnet_ids      = module.vpc.private_subnet_ids
  security_group_id       = module.security_groups.windows_security_group_id
  domain_controller_ip    = module.domain_controllers.primary_dc_private_ip
  key_name                = var.key_name
  environment_name        = var.environment_name
  instance_types          = var.windows_instance_types
}

# Linux Servers - Rebel Alliance
module "linux_servers" {
  source = "./modules/linux_servers"
  
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security_groups.linux_security_group_id
  key_name          = var.key_name
  environment_name  = var.environment_name
  instance_types    = var.linux_instance_types
}

# Database Servers - Data Vaults
module "databases" {
  source = "./modules/databases"
  
  private_subnet_ids       = module.vpc.private_subnet_ids
  windows_security_group   = module.security_groups.database_security_group_id
  linux_security_group     = module.security_groups.database_security_group_id
  domain_controller_ip     = module.domain_controllers.primary_dc_private_ip
  key_name                = var.key_name
  environment_name        = var.environment_name
  database_instance_types = var.database_instance_types
}

# MID Server - R2-D2
module "mid_server" {
  source = "./modules/mid_server"
  
  public_subnet_id     = module.vpc.public_subnet_ids[0]
  security_group_id    = module.security_groups.mid_server_security_group_id
  key_name            = var.key_name
  environment_name    = var.environment_name
  instance_type       = var.mid_server_instance_type
  servicenow_instance = var.servicenow_instance_url
}

# Discovery Credentials Management
#module "discovery_credentials" {
#  source = "./modules/discovery_credentials"
#  
#  environment_name = var.environment_name
#  vpc_id          = module.vpc.vpc_id
#}

# Monitoring Server - C-3PO
module "monitoring" {
  source = "./modules/monitoring"
  
  private_subnet_id = module.vpc.private_subnet_ids[0]
  security_group_id = module.security_groups.monitoring_security_group_id
  key_name         = var.key_name
  environment_name = var.environment_name
}

# Application Load Balancers
module "load_balancers" {
  source = "./modules/load_balancers"
  
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_id  = module.security_groups.alb_security_group_id
  environment_name   = var.environment_name
  
  windows_targets = [
    module.windows_servers.web_server_ids,
    module.windows_servers.app_server_ids
  ]
  
  linux_targets = [
    module.linux_servers.web_server_ids,
    module.linux_servers.app_server_ids
  ]
}

# CloudWatch Monitoring and Alarms
module "cloudwatch" {
  source = "./modules/cloudwatch"
  
  environment_name = var.environment_name
  
  monitored_instances = concat(
    values(module.windows_servers.all_instance_ids),
    values(module.linux_servers.all_instance_ids),
    values(module.databases.all_instance_ids),
    [module.mid_server.instance_id]
  )
}

# Outputs for ServiceNow Configuration
output "servicenow_discovery_config" {
  description = "Configuration needed for ServiceNow Discovery setup"
  value = {
    mid_server_public_ip  = module.mid_server.public_ip
    mid_server_private_ip = module.mid_server.private_ip
    vpc_cidr             = var.vpc_cidr
    domain_controller_ip = module.domain_controllers.primary_dc_private_ip
    discovery_subnets    = var.private_subnet_cidrs
  }
  sensitive = false
}

output "instances_inventory" {
  description = "Complete inventory of deployed instances"
  value = {
    windows_servers = module.windows_servers.instance_details
    linux_servers   = module.linux_servers.instance_details
    databases      = module.databases.instance_details
    mid_server     = module.mid_server.instance_details
  }
}

output "cost_optimization_data" {
  description = "Data for cost optimization analysis"
  value = {
    instance_types = {
      windows = var.windows_instance_types
      linux   = var.linux_instance_types
      database = var.database_instance_types
    }
    total_instances = {
      windows  = length(module.windows_servers.all_instance_ids)
      linux    = length(module.linux_servers.all_instance_ids)
      database = length(module.databases.all_instance_ids)
    }
  }
}

output "software_inventory" {
  description = "Software installed across the environment"
  value = {
    java_versions     = ["8", "11", "17", "21"]
    web_servers      = ["IIS", "Apache", "Nginx"]
    app_servers      = ["Tomcat", "WebLogic", "JBoss", "Node.js"]
    databases        = ["SQL Server", "PostgreSQL", "MySQL", "Oracle"]
    security_software = ["BlastShield", "ForceField", "RebelGuard"]
  }
}