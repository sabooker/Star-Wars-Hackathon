# outputs.tf - Star Wars Hackathon Outputs

# ServiceNow Discovery Configuration
output "servicenow_configuration" {
  description = "Complete configuration for ServiceNow Discovery"
  value = {
    mid_servers = {
      linux = {
        public_ip  = module.mid_server_linux.public_ip
        private_ip = module.mid_server_linux.private_ip
        ssh_key    = var.key_name
        target_os  = "Linux/Unix"
      }
      windows = {
        public_ip  = module.mid_server_windows.public_ip
        private_ip = module.mid_server_windows.private_ip
        rdp_access = "mstsc /v:${module.mid_server_windows.public_ip}"
        target_os  = "Windows"
      }
    }
    
    discovery_credentials = {
      windows_domain = {
        domain      = "starwars.local"
        username    = "svc-discovery"
        description = "Use for Windows domain-joined servers"
        mid_server  = "c-3po-windows-mid"
      }
      windows_local = {
        username    = "empire-discovery-admin"
        description = "Use for Windows workgroup servers"
        mid_server  = "c-3po-windows-mid"
      }
      linux_ssh = {
        username    = "rebel-discovery-user"
        description = "Use for all Linux servers"
        mid_server  = "r2-d2-mid"
      }
    }
    
    discovery_ranges = {
      primary   = var.private_subnet_cidrs[0]
      secondary = var.private_subnet_cidrs[1]
      database  = var.private_subnet_cidrs[2]
      apps      = var.private_subnet_cidrs[3]
    }
    
    domain_controllers = module.domain_controllers.domain_dns_ips
  }
}

# Complete Instance Inventory
output "instance_inventory" {
  description = "Complete inventory of all deployed instances"
  value = {
    domain_controllers = {
      primary = {
        id         = module.domain_controllers.primary_dc_id
        private_ip = module.domain_controllers.primary_dc_private_ip
        role       = "Primary Domain Controller"
        os         = "Windows Server 2019"
      }
      secondary = {
        id         = module.domain_controllers.secondary_dc_id
        private_ip = module.domain_controllers.secondary_dc_private_ip
        role       = "Secondary Domain Controller"
        os         = "Windows Server 2022"
      }
    }
    
    windows_servers = {
      for k, v in module.windows_servers.instance_details : k => merge(v, {
        domain = "starwars.local"
      })
    }
    
    linux_servers = {
      for k, v in module.linux_servers.instance_details : k => v
    }
    
    databases = {
      for k, v in module.databases.instance_details : k => merge(v, {
        data_volumes    = true
        backup_enabled  = true
        monitoring      = "enabled"
      })
    }
    
    mid_servers = {
      linux = {
        id         = module.mid_server_linux.instance_id
        public_ip  = module.mid_server_linux.public_ip
        private_ip = module.mid_server_linux.private_ip
        hostname   = "r2-d2-mid"
        role       = "ServiceNow Linux MID Server"
        os         = "Amazon Linux 2"
      }
      windows = {
        id         = module.mid_server_windows.instance_id
        public_ip  = module.mid_server_windows.public_ip
        private_ip = module.mid_server_windows.private_ip
        hostname   = "c-3po-windows-mid"
        role       = "ServiceNow Windows MID Server"
        os         = "Windows Server 2022"
      }
    }
    
    monitoring = {
      id         = module.monitoring.instance_id
      private_ip = module.monitoring.private_ip
      role       = "Monitoring Server"
      os         = "Ubuntu 22.04"
      services   = ["Prometheus", "Grafana", "Alertmanager"]
    }
  }
}

# Software Asset Management (SAM) Data
output "sam_software_inventory" {
  description = "Software inventory for SAM Pro demonstrations"
  value = {
    operating_systems = {
      windows = {
        "Windows Server 2016" = [
          module.windows_servers.instance_details.imperial_cruiser_app.id
        ]
        "Windows Server 2019" = [
          module.windows_servers.instance_details.tie_fighter_web.id,
          module.windows_servers.instance_details.storm_trooper_svc.id,
          module.domain_controllers.primary_dc_id
        ]
        "Windows Server 2022" = [
          module.windows_servers.instance_details.at_at_walker_app.id,
          module.windows_servers.instance_details.imperial_shuttle_mgt.id,
          module.domain_controllers.secondary_dc_id
        ]
      }
      linux = {
        "Amazon Linux 2" = [
          module.linux_servers.instance_details.y_wing_app.id,
          module.linux_servers.instance_details.rebel_transport_cache.id,
          module.mid_server_linux.instance_id
        ]
        "RHEL 8" = [
          module.linux_servers.instance_details.millennium_falcon_db.id,
          module.linux_servers.instance_details.b_wing_app.id
        ]
        "RHEL 9" = [
          module.linux_servers.instance_details.mon_calamari_db.id
        ]
        "Ubuntu 20.04" = [
          module.linux_servers.instance_details.rebel_cruiser_app.id
        ]
        "Ubuntu 22.04" = [
          module.linux_servers.instance_details.x_wing_web.id,
          module.linux_servers.instance_details.a_wing_web.id,
          module.monitoring.instance_id
        ]
      }
    }
    
    databases = {
      "SQL Server 2019" = [module.databases.sql_server_ids[0]]
      "PostgreSQL 14"   = module.databases.postgresql_ids
      "MySQL 8.0"       = module.databases.mysql_ids
    }
    
    web_servers = {
      "IIS"     = module.windows_servers.web_server_ids
      "Apache"  = [module.linux_servers.instance_details.x_wing_web.id]
      "Nginx"   = [module.linux_servers.instance_details.a_wing_web.id]
    }
    
    application_servers = {
      "Tomcat"   = [module.linux_servers.instance_details.y_wing_app.id]
      "Node.js"  = [module.linux_servers.instance_details.rebel_cruiser_app.id]
      "WildFly"  = [module.linux_servers.instance_details.b_wing_app.id]
    }
    
    java_versions = {
      "Java 8"  = [module.windows_servers.instance_details.imperial_cruiser_app.id]
      "Java 11" = [module.linux_servers.instance_details.y_wing_app.id]
      "Java 17" = [
        module.windows_servers.instance_details.at_at_walker_app.id,
        module.linux_servers.instance_details.b_wing_app.id
      ]
    }
    
    security_software = {
      "BlastShield" = {
        version = "5.4.2"
        instances = [module.windows_servers.instance_details.at_at_walker_app.id]
      }
      "ForceField" = {
        version = "3.2.1"
        instances = [module.linux_servers.instance_details.b_wing_app.id]
      }
      "RebelGuard" = {
        version = "2.1.8"
        instances = [module.linux_servers.instance_details.y_wing_app.id]
      }
    }
  }
}

# Cost Optimization Insights
output "cost_optimization_insights" {
  description = "Data for cost optimization analysis and recommendations"
  value = {
    instance_generations = {
      current_generation = {
        t3_instances = length([for k, v in merge(
          module.windows_servers.instance_details,
          module.linux_servers.instance_details
        ) : k if strcontains(v.instance_type, "t3")])
        
        m5_instances = length([for k, v in merge(
          module.windows_servers.instance_details,
          module.linux_servers.instance_details
        ) : k if strcontains(v.instance_type, "m5")])
        
        r5_instances = length([for k, v in module.databases.instance_details : k if strcontains(v.instance_type, "r5")])
      }
      
      upgrade_candidates = {
        windows_2016_servers = [
          for k, v in module.windows_servers.instance_details : {
            instance_id = v.id
            current_os = v.os_version
            instance_type = v.instance_type
            recommended_upgrade = "Windows Server 2022"
            priority = "High"
          } if v.os_version == "Windows Server 2016"
        ]
        
        older_instance_types = [
          for k, v in merge(
            module.windows_servers.instance_details,
            module.linux_servers.instance_details
          ) : {
            instance_id = v.id
            current_type = v.instance_type
            recommended_type = replace(v.instance_type, "t2", "t3")
            savings_potential = "20-30%"
          } if strcontains(v.instance_type, "t2")
        ]
      }
    }
    
    resource_utilization = {
      total_instances = length(flatten([
        values(module.windows_servers.all_instance_ids),
        values(module.linux_servers.all_instance_ids),
        values(module.databases.all_instance_ids),
        [module.mid_server_linux.instance_id],
        [module.mid_server_windows.instance_id],
        [module.monitoring.instance_id]
      ]))
      
      by_type = {
        windows = length(module.windows_servers.all_instance_ids)
        linux = length(module.linux_servers.all_instance_ids)
        database = length(module.databases.all_instance_ids)
      }
      
      by_instance_family = {
        t3_family = length([for id in flatten([
          values(module.windows_servers.all_instance_ids),
          values(module.linux_servers.all_instance_ids)
        ]) : id if strcontains(id, "t3")])
        
        m5_family = length([for id in flatten([
          values(module.windows_servers.all_instance_ids),
          values(module.linux_servers.all_instance_ids)
        ]) : id if strcontains(id, "m5")])
        
        r5_family = length([for id in values(module.databases.all_instance_ids) : id if strcontains(id, "r5")])
      }
    }
    
    potential_savings = {
      reserved_instances = "30-75% with 1-3 year commitments"
      spot_instances = "Up to 90% for non-critical workloads"
      instance_rightsizing = "15-40% by matching instance size to workload"
      os_modernization = "10-25% with newer OS versions"
    }
  }
}

# CMDB and CSDM Configuration
output "cmdb_configuration" {
  description = "CMDB structure for CSDM implementation"
  value = {
    business_applications = [
      {
        name = "Death Star Control System"
        ci_class = "cmdb_ci_business_app"
        servers = [
          module.windows_servers.instance_details.star_destroyer_sql.id,
          module.windows_servers.instance_details.at_at_walker_app.id,
          module.windows_servers.instance_details.tie_fighter_web.id
        ]
        criticality = "Mission Critical"
        owner = "darth-vader@starwars.local"
      },
      {
        name = "Rebel Alliance Communications"
        ci_class = "cmdb_ci_business_app"
        servers = [
          module.linux_servers.instance_details.rebel_cruiser_app.id,
          module.linux_servers.instance_details.x_wing_web.id,
          module.databases.instance_details.rebel_base_postgres.id
        ]
        criticality = "High"
        owner = "leia-organa@starwars.local"
      }
    ]
    
    service_mappings = {
      technical_services = [
        {
          name = "Imperial Database Service"
          type = "Technical Service"
          components = module.databases.sql_server_ids
        },
        {
          name = "Rebel Database Service"
          type = "Technical Service"
          components = concat(
            module.databases.postgresql_ids,
            module.databases.mysql_ids
          )
        },
        {
          name = "Web Hosting Service"
          type = "Technical Service"
          components = concat(
            module.windows_servers.web_server_ids,
            module.linux_servers.web_server_ids
          )
        }
      ]
      
      business_services = [
        {
          name = "Death Star Operations"
          type = "Business Service"
          supported_by = ["Imperial Database Service", "Web Hosting Service"]
          owner = "grand-moff-tarkin@starwars.local"
        },
        {
          name = "Rebel Intelligence"
          type = "Business Service"
          supported_by = ["Rebel Database Service", "Web Hosting Service"]
          owner = "mon-mothma@starwars.local"
        }
      ]
    }
  }
}

# Dashboard and Reporting URLs
output "dashboard_urls" {
  description = "URLs for various dashboards and interfaces"
  value = {
    load_balancers = module.load_balancers.alb_dns_names
    monitoring = {
      grafana = "http://${module.monitoring.private_ip}:3000"
      prometheus = "http://${module.monitoring.private_ip}:9090"
    }
  }
  sensitive = false
}

# Security and Compliance Summary
output "security_compliance_summary" {
  description = "Security and compliance status summary"
  value = {
    security_groups_deployed = {
      windows_sg = module.security_groups.windows_security_group_id
      linux_sg = module.security_groups.linux_security_group_id
      database_sg = module.security_groups.database_security_group_id
      mid_server_sg = module.security_groups.mid_server_security_group_id
      monitoring_sg = module.security_groups.monitoring_security_group_id
      alb_sg = module.security_groups.alb_security_group_id
    }
    
    encryption_status = {
      all_volumes_encrypted = true
      encryption_type = "AES-256"
      kms_managed = true
    }
    
    security_software_coverage = {
      protected_instances = length([
        module.windows_servers.instance_details.at_at_walker_app.id,
        module.linux_servers.instance_details.b_wing_app.id,
        module.linux_servers.instance_details.y_wing_app.id
      ])
      
      total_instances = length(flatten([
        values(module.windows_servers.all_instance_ids),
        values(module.linux_servers.all_instance_ids)
      ]))
      
      coverage_percentage = (3.0 / length(flatten([
        values(module.windows_servers.all_instance_ids),
        values(module.linux_servers.all_instance_ids)
      ]))) * 100
    }
    
    patch_management = {
      windows_wsus_server = module.windows_servers.instance_details.imperial_shuttle_mgt.id
      linux_repo_server = null
      automated_patching = false
    }
  }
}

# ServiceNow Integration Points
output "servicenow_integration" {
  description = "Integration points for ServiceNow"
  value = {
    discovery = {
      mid_servers = {
        linux_mid = module.mid_server_linux.instance_details.hostname
        windows_mid = module.mid_server_windows.instance_details.hostname
      }
      discovery_source = "Star Wars Hackathon Environment"
      schedules = [
        {
          name = "Windows Infrastructure Discovery"
          mid_server = "c-3po-windows-mid"
          targets = module.windows_servers.all_instance_ids
          frequency = "Daily"
        },
        {
          name = "Linux Infrastructure Discovery"
          mid_server = "r2-d2-mid"
          targets = module.linux_servers.all_instance_ids
          frequency = "Daily"
        },
        {
          name = "Database Discovery"
          mid_servers = "Both"
          targets = module.databases.all_instance_ids
          frequency = "Twice Daily"
        }
      ]
    }
    
    aws_connector = {
      region = var.aws_region
      vpc_id = module.vpc.vpc_id
      account_id = data.aws_caller_identity.current.account_id
    }
    
    event_management = {
      monitoring_server = module.monitoring.private_ip
      snmp_enabled_devices = length(flatten([
        values(module.windows_servers.all_instance_ids),
        values(module.linux_servers.all_instance_ids),
        values(module.databases.all_instance_ids)
      ]))
    }
    
    orchestration = {
      ansible_compatible = true
      terraform_managed = true
      configuration_items = "All instances tagged with Project=Star-Wars-Hackathon"
    }
  }
}

# Quick Start Commands
output "quick_start_commands" {
  description = "Commands to get started with the environment"
  value = {
    ssh_to_linux_mid = "ssh -i ${var.key_name}.pem ec2-user@${module.mid_server_linux.public_ip}"
    
    rdp_to_windows_mid = "mstsc /v:${module.mid_server_windows.public_ip}"
    
    rdp_to_windows = [
      for k, v in module.windows_servers.instance_details : 
      "Connect to ${k} at ${v.private_ip} using RDP"
    ]
    
    ssh_to_linux = [
      for k, v in module.linux_servers.instance_details :
      "ssh -i ${var.key_name}.pem rebel-discovery-user@${v.private_ip}"
    ]
    
    verify_domains = "nslookup starwars.local ${module.domain_controllers.primary_dc_private_ip}"
    
    servicenow_setup = [
      "1. Install Linux MID Server on ${module.mid_server_linux.public_ip} for Unix/Linux discovery",
      "2. Install Windows MID Server on ${module.mid_server_windows.public_ip} for Windows discovery",
      "3. Configure Discovery Credentials (see servicenow_configuration output)",
      "4. Set up Discovery Schedules for subnets using appropriate MID servers",
      "5. Configure AWS Service Management Connector",
      "6. Run Discovery and verify CMDB population"
    ]
  }
}

# Data source for AWS account ID
data "aws_caller_identity" "current" {}