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
   git clone https://github.com/royalsirrine/Star-Wars-Hackathon.git
   cd Star-Wars-Hackathon
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Copy and configure the variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

4. Review the planned infrastructure:
   ```bash
   terraform plan
   ```

5. Deploy the infrastructure:
   ```bash
   terraform apply
   ```

6. After deployment, use the outputs to:
   - Connect to the MID Server
   - Configure ServiceNow Discovery
   - Set up AWS Service Management Connector
   - Run Discovery to populate the CMDB

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
    ├── domain_controllers/
    ├── windows_servers/
    ├── linux_servers/
    ├── databases/
    ├── mid_server/
    ├── monitoring/
    ├── load_balancers/
    ├── cloudwatch/
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

1. Install MID Server on R2-D2:
   ```bash
   ssh -i lightsaber-key.pem ec2-user@<MID_SERVER_PUBLIC_IP>
   sudo /opt/servicenow/mid-server/scripts/download_mid_server.sh <MID_SERVER_URL>
   ```

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

## Hackathon Challenges

This infrastructure addresses the 2025 ServiceNow Hackathon challenges:

1. **Drive down operational costs**: 
   - Demonstrates efficient discovery and CMDB population
   - Shows cost optimization through instance analysis
   - Automates inventory management

2. **Improve existing products**:
   - Enhanced CMDB with complete infrastructure visibility
   - Integrated multi-source discovery
   - Comprehensive software asset tracking

3. **Explore new opportunities**:
   - CSDM implementation patterns
   - Advanced SAM Pro capabilities
   - Cross-platform discovery integration

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Troubleshooting

Common issues and solutions:

### MID Server Connection Issues
- Verify security groups allow outbound HTTPS (443)
- Check IAM role has necessary permissions
- Ensure ServiceNow instance URL is correct

### Discovery Failures
- Verify discovery credentials are correct
- Check security groups allow required ports
- Ensure domain controllers are accessible

### Cost Optimization
- Review instance types for over-provisioned resources
- Consider reserved instances for long-term use
- Use the cost optimization dashboard outputs

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- ServiceNow Discovery team
- AWS Well-Architected Framework
- Star Wars universe for the naming inspiration

## Support

For questions or issues:
- Open an issue on GitHub
- Contact: rebel-it@starwars.local (fictional)

May the Discovery be with you!

---

**Note**: This is a demonstration environment for the ServiceNow Hackathon. Ensure you destroy resources after the hackathon to avoid unnecessary AWS charges.

```bash
terraform destroy
```
