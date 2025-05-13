# Demo Script for Star Wars ServiceNow Discovery Hackathon

## Introduction (2 minutes)

"Welcome to our ServiceNow Discovery Hackathon presentation. Today, we'll demonstrate how we've created a comprehensive Star Wars-themed infrastructure to showcase the power of ServiceNow Discovery, CMDB implementation, and Software Asset Management Pro.

Our solution addresses all three hackathon challenges:
1. Driving down operational costs through efficient discovery
2. Improving existing products with enhanced CMDB capabilities  
3. Exploring new opportunities with multi-source discovery integration"

## Environment Overview (3 minutes)

"Let me show you what we've built..."

### Infrastructure Components
- **20+ servers** across Windows and Linux platforms
- **Multiple database engines**: SQL Server, PostgreSQL, MySQL
- **Diverse applications**: From legacy Windows 2016 to modern containerized apps
- **Real-world complexity**: Domain controllers, load balancers, monitoring systems

### Star Wars Theme Benefits
- Easy identification during demos ("Death Star SQL Server")
- Memorable naming for training purposes
- Engaging storyline for presentations

## Live Discovery Demo (5 minutes)

### 1. MID Server (R2-D2)
```bash
# SSH to MID Server
ssh -i lightsaber-key.pem ec2-user@<MID_SERVER_IP>

# Check MID Server status
sudo /opt/servicenow/mid-server/scripts/check_status.sh
```

### 2. ServiceNow Discovery Console
- Navigate to Discovery > Discovery Schedules
- Show "Galactic Discovery" schedule
- Run discovery on "Core Worlds" subnet
- Monitor real-time progress

### 3. Multi-Source Discovery
- Run AWS Service Management Connector import
- Show how both direct discovery and AWS import populate CMDB
- Demonstrate reconciliation rules in action

## CMDB Population Results (3 minutes)

### 1. Configuration Items
- Navigate to Configuration > All Configuration Items
- Filter by Discovery Source
- Show complete infrastructure map

### 2. Relationships
- Demonstrate application dependencies
- Show database-to-application mappings
- Display network topology view

### 3. Business Service Mapping
- Show "Death Star Operations" business service
- Demonstrate dependency mapping to technical services
- Show impact analysis capabilities

## Software Asset Management Demo (4 minutes)

### 1. Software Inventory
```
Navigate to Software Asset > All Software Installations
```
- Show discovered software across platforms
- Demonstrate version tracking (Java 8, 11, 17)
- Display security software coverage

### 2. License Compliance
- Show simulated security software (BlastShield, ForceField)
- Demonstrate coverage gaps
- Display upgrade recommendations

### 3. Cost Optimization
- Show instance type analysis
- Demonstrate upgrade candidates (t2 → t3, m4 → m5)
- Calculate potential savings

## Dashboards and Insights (3 minutes)

### 1. Discovery Quality Dashboard
- Show multi-source discovery coverage
- Display reconciliation success rates
- Demonstrate data quality metrics

### 2. Security Compliance Dashboard
- Show systems with/without security software
- Display compliance by OS type
- Demonstrate vulnerability tracking

### 3. AWS Optimization Dashboard
- Show instance type distribution
- Display upgrade recommendations
- Calculate ROI for modernization

## Business Value (2 minutes)

### 1. Operational Efficiency
- **80% reduction** in manual inventory efforts
- **Real-time** infrastructure visibility
- **Automated** compliance tracking

### 2. Cost Savings
- Identified **25% potential savings** through right-sizing
- Found **10 upgrade candidates** for better performance/cost
- Discovered **unused resources** for decommissioning

### 3. Risk Reduction
- **100% visibility** into security software coverage
- **Automated alerts** for non-compliant systems
- **Dependency mapping** for change impact analysis

## Live Integration Demo (3 minutes)

### 1. Incident Creation
- Create incident for "Death Star Database"
- Show automatic CI population
- Demonstrate impact analysis

### 2. Change Management
- Create change request for Java upgrade
- Show affected systems automatically
- Display downstream dependencies

### 3. Orchestration
- Trigger automated discovery
- Show real-time CMDB updates
- Demonstrate workflow automation

## Technical Deep Dive (5 minutes)

### 1. Terraform Infrastructure
```bash
# Show infrastructure as code
cat main.tf
terraform state list | grep -E "(death-star|millennium-falcon)"
```

### 2. Discovery Patterns
- Show custom pattern for BlastShield detection
- Demonstrate AWS instance type classification
- Display security compliance rules

### 3. Integration Architecture
```
ServiceNow Instance
    ↓
MID Server (R2-D2)
    ↓
├── Direct Discovery (WMI/SSH)
└── AWS Service Management Connector
    ↓
Reconciliation Engine
    ↓
Unified CMDB
```

## Q&A and Next Steps (5 minutes)

### Potential Questions to Address:
1. How does reconciliation handle conflicts?
2. What's the discovery frequency?
3. How do you handle credential management?
4. What's the ROI timeline?

### Future Enhancements:
- Container discovery for Kubernetes
- Network device discovery
- Application performance monitoring
- Predictive analytics

## Closing Statement

"Our Star Wars-themed ServiceNow Discovery solution demonstrates how organizations can achieve complete infrastructure visibility, ensure compliance, and optimize costs. By combining direct discovery with cloud service integrations, we've created a single source of truth that drives operational excellence.

The Force is strong with ServiceNow Discovery - may it be with your IT operations!"

---

## Backup Slides

### Architecture Details
- VPC structure and networking
- Security group configurations
- IAM roles and permissions

### Discovery Credentials
- Windows domain integration
- Linux SSH key management
- AWS IAM role-based discovery

### Custom Patterns
- Security software detection
- Java version identification
- Database type classification

### Integration Points
- AWS Service Management Connector
- ServiceNow Event Management
- Orchestration workflows

---

## Demo Commands Quick Reference

```bash
# Connect to MID Server
ssh -i lightsaber-key.pem ec2-user@<MID_IP>

# Check infrastructure
terraform output servicenow_configuration

# View instance inventory
terraform output instance_inventory

# Show cost optimization data
terraform output cost_optimization_insights

# Connect to Windows Server
aws ssm start-session --target <INSTANCE_ID>

# Run discovery test
sudo /opt/servicenow/mid-server/scripts/test_connectivity.sh
```
