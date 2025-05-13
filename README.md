# Star Wars ServiceNow Discovery Hackathon

This repository contains the infrastructure as code (IaC) for deploying a comprehensive Star Wars-themed environment to demonstrate ServiceNow Discovery capabilities, CMDB benefits, CSDM implementation, and Software Asset Management Pro features.

## Overview

This project creates a realistic enterprise environment with:
- Multiple Windows Server versions (2016, 2019, 2022)
- Various Linux distributions (Amazon Linux 2, RHEL, Ubuntu)
- Different AWS instance types (m5.large, m5.xlarge, t3.large, etc.)
- Database servers (both Windows SQL Server and Linux PostgreSQL)
- Web servers, application servers, and middleware
- Domain controllers and Active Directory infrastructure
- MID Server for ServiceNow Discovery
- Realistic software installations for SAM Pro demonstrations

## Architecture

```
                    ┌─────────────────────────┐
                    │   ServiceNow Instance   │
                    │    (Your PDI/DEV)       │
                    └───────────┬─────────────┘
                                │
                    ┌───────────┴────────────┐
                    │    MID Server          │
                    │ (a-new-hope-midserver) │
                    └───────────┬────────────┘
                                │
        ┌───────────────────────┴───────────────────────┐
        │                VPC: Galaxy                    │
        │  ┌─────────────────┐    ┌─────────────────┐   │
        │  │ Public Subnets  │    │ Private Subnets │   │
        │  │ (Outer Rim)     │    │ (Core Worlds)   │   │
        │  └─────────────────┘    └─────────────────┘   │
        │                                               │
        │  Windows Servers:        Linux Servers:       │
        │  - Domain Controllers    - Web Servers        │
        │  - Database Servers     - App Servers         │
        │  - App Servers          - Database Servers    │
        └───────────────────────────────────────────────┘
```

## Features

- **Multi-tier Architecture**: Mimics real-world enterprise deployments
- **Diverse OS Landscape**: Various Windows and Linux versions
- **Database Diversity**: SQL Server and PostgreSQL instances
- **Software Variety**: Different Java versions, web servers, and applications
- **Security Compliance**: Simulated security software for SAM Pro demonstrations
- **Cost Optimization**: Mix of instance types for AWS optimization insights

## Prerequisites

- AWS Account with appropriate permissions
- Terraform CLI installed (>= 1.0)
- AWS CLI configured with credentials
- ServiceNow PDI with Discovery plugin activated
- Git for version control

## Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/Star-Wars-Hackathon.git
   cd Star-Wars-Hackathon
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the plan:
   ```bash
   terraform plan
   ```

4. Deploy the infrastructure:
   ```bash
   terraform apply
   ```

5. Configure ServiceNow Discovery using the MID Server public IP from outputs

## Repository Structure

```
Star-Wars-Hackathon/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
└── modules/
    ├── vpc/
    ├── security_groups/
    ├── ec2_instances/
    ├── domain_controller/
    ├── databases/
    └── discovery_credentials/
```

## Instance Inventory

### Windows Servers
- **Death Star** (Domain Controller) - Windows Server 2019
- **Star Destroyer** (SQL Server Database) - Windows Server 2022 + SQL Server
- **Imperial Cruiser** (App Server) - Windows Server 2016
- **TIE Fighter** (Web Server) - Windows Server 2019 + IIS
- **AT-AT Walker** (App Server) - Windows Server 2022

### Linux Servers
- **Millennium Falcon** (Database) - RHEL 8 + PostgreSQL
- **X-Wing Fighter** (Web Server) - Ubuntu 22.04 + Apache
- **Y-Wing Bomber** (App Server) - Amazon Linux 2 + Tomcat
- **Rebel Cruiser** (App Server) - Ubuntu 20.04 + Node.js
- **Mon Calamari** (Database) - RHEL 9 + MySQL

### Special Purpose
- **R2-D2** (MID Server) - Amazon Linux 2
- **C-3PO** (Monitoring Server) - Ubuntu 22.04

## ServiceNow Discovery Configuration

1. Install MID Server on R2-D2
2. Configure credentials for Windows domains and Linux SSH
3. Set up Discovery schedules for all subnets
4. Configure AWS Service Management Connector
5. Implement reconciliation rules for multi-source data

## Software Asset Management Pro Setup

The environment includes various software installations to demonstrate SAM Pro capabilities:
- Multiple Java versions (8, 11, 17)
- Different web servers (IIS, Apache, Nginx)
- Database software (SQL Server, PostgreSQL, MySQL)
- Simulated security software (BlastShield)
- Various application servers (Tomcat, Node.js)

## Cost Optimization Features

The environment uses diverse instance types to demonstrate:
- Right-sizing recommendations
- Instance family upgrade paths
- Cost optimization opportunities
- Performance vs. cost analysis

## Contributing

Please follow the contribution guidelines in CONTRIBUTING.md

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- ServiceNow Discovery team
- AWS Well-Architected Framework
- Star Wars universe for the naming inspiration

May the Discovery be with you!
