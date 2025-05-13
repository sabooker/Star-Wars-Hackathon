# modules/mid_server_windows/main.tf - C-3PO Windows MID Server

# Get Windows Server 2022 AMI
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

# Windows MID Server Instance - C-3PO
resource "aws_instance" "c_3po_windows_mid" {
  ami           = data.aws_ami.windows_2022.id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_id
  key_name      = var.key_name

  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.windows_mid_server_profile.name

  user_data = templatefile("${path.module}/userdata/windows_mid_server_setup.ps1", {
    instance_name        = "c-3po-windows-mid"
    servicenow_instance  = var.servicenow_instance
    environment_name     = var.environment_name
    domain_controller_ip = var.domain_controller_ip
  })

  tags = merge(var.common_tags, {
    Name               = "c-3po-windows-mid"
    OS                 = "Windows Server 2022"
    Role               = "ServiceNow Windows MID Server"
    Application        = "ServiceNow Discovery"
    CriticalityLevel   = "High"
    PubliclyAccessible = "true"
    PlatformTarget     = "Windows"
  })

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
    encrypted   = true
  }
}

# IAM Role for Windows MID Server
resource "aws_iam_role" "windows_mid_server_role" {
  name = "${var.environment_name}-windows-mid-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# IAM Policy for Windows MID Server
resource "aws_iam_policy" "windows_mid_server_policy" {
  name        = "${var.environment_name}-windows-mid-server-policy"
  description = "Policy for ServiceNow Windows MID Server discovery operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "elasticloadbalancing:Describe*",
          "autoscaling:Describe*",
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "rds:Describe*",
          "rds:List*",
          "iam:List*",
          "iam:Get*",
          "s3:List*",
          "s3:GetBucketLocation",
          "s3:GetBucketTagging",
          "sns:List*",
          "sqs:List*",
          "lambda:List*",
          "lambda:Get*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:*:*:secret:${var.environment_name}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:*:*:parameter/${var.environment_name}/*"
        ]
      }
    ]
  })

  tags = var.common_tags
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "windows_mid_server_policy" {
  role       = aws_iam_role.windows_mid_server_role.name
  policy_arn = aws_iam_policy.windows_mid_server_policy.arn
}

resource "aws_iam_role_policy_attachment" "windows_mid_server_ssm" {
  role       = aws_iam_role.windows_mid_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "windows_mid_server_cloudwatch" {
  role       = aws_iam_role.windows_mid_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance Profile
resource "aws_iam_instance_profile" "windows_mid_server_profile" {
  name = "${var.environment_name}-windows-mid-server-profile"
  role = aws_iam_role.windows_mid_server_role.name
  tags = var.common_tags
}

# Elastic IP for stable public access
resource "aws_eip" "windows_mid_server_eip" {
  instance = aws_instance.c_3po_windows_mid.id
  domain   = "vpc"

  tags = merge(var.common_tags, {
    Name = "c-3po-windows-mid-eip"
  })
}

# CloudWatch Log Group for Windows MID Server
resource "aws_cloudwatch_log_group" "windows_mid_server_logs" {
  name              = "/aws/ec2/windows-mid-server/${var.environment_name}"
  retention_in_days = 30

  tags = merge(var.common_tags, {
    Name = "c-3po-windows-mid-logs"
  })
}

# Outputs
output "instance_id" {
  description = "Windows MID Server instance ID"
  value       = aws_instance.c_3po_windows_mid.id
}

output "public_ip" {
  description = "Windows MID Server public IP"
  value       = aws_eip.windows_mid_server_eip.public_ip
}

output "private_ip" {
  description = "Windows MID Server private IP"
  value       = aws_instance.c_3po_windows_mid.private_ip
}

output "instance_details" {
  description = "Detailed information about Windows MID Server"
  value = {
    id             = aws_instance.c_3po_windows_mid.id
    public_ip      = aws_eip.windows_mid_server_eip.public_ip
    private_ip     = aws_instance.c_3po_windows_mid.private_ip
    hostname       = "c-3po-windows-mid"
    os             = "Windows Server 2022"
    role           = "ServiceNow Windows MID Server"
    rdp_connection = "mstsc /v:${aws_eip.windows_mid_server_eip.public_ip}"
    iam_role       = aws_iam_role.windows_mid_server_role.arn
  }
}

# Variables
variable "public_subnet_id" {
  description = "Public subnet ID for Windows MID Server"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for Windows MID Server"
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

variable "instance_type" {
  description = "EC2 instance type for Windows MID Server"
  type        = string
  default     = "t3.large"
}

variable "servicenow_instance" {
  description = "ServiceNow instance URL"
  type        = string
}

variable "domain_controller_ip" {
  description = "IP address of the domain controller"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}