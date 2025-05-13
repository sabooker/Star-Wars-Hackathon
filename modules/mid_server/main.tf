# modules/mid_server/main.tf - R2-D2 MID Server

# Get the latest Amazon Linux 2 AMI
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

# MID Server Instance - R2-D2
resource "aws_instance" "r2_d2_mid" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_id
  key_name      = var.key_name

  vpc_security_group_ids    = [var.security_group_id]
  associate_public_ip_address = true
  iam_instance_profile      = aws_iam_instance_profile.mid_server_profile.name

  user_data = templatefile("${path.module}/userdata/mid_server_setup.sh", {
    instance_name       = "r2-d2-mid"
    servicenow_instance = var.servicenow_instance
    environment_name    = var.environment_name
  })

  tags = merge(var.common_tags, {
    Name               = "r2-d2-mid"
    OS                 = "Amazon Linux 2"
    Role               = "ServiceNow MID Server"
    Application        = "ServiceNow Discovery"
    CriticalityLevel   = "High"
    PubliclyAccessible = "true"
  })

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
    encrypted   = true
  }
}

# IAM Role for MID Server
resource "aws_iam_role" "mid_server_role" {
  name = "${var.environment_name}-mid-server-role"

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

# IAM Policy for MID Server
resource "aws_iam_policy" "mid_server_policy" {
  name        = "${var.environment_name}-mid-server-policy"
  description = "Policy for ServiceNow MID Server discovery operations"

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
          "lambda:Get*",
          "ecs:Describe*",
          "ecs:List*",
          "eks:Describe*",
          "eks:List*"
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
resource "aws_iam_role_policy_attachment" "mid_server_policy" {
  role       = aws_iam_role.mid_server_role.name
  policy_arn = aws_iam_policy.mid_server_policy.arn
}

resource "aws_iam_role_policy_attachment" "mid_server_ssm" {
  role       = aws_iam_role.mid_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "mid_server_cloudwatch" {
  role       = aws_iam_role.mid_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance Profile
resource "aws_iam_instance_profile" "mid_server_profile" {
  name = "${var.environment_name}-mid-server-profile"
  role = aws_iam_role.mid_server_role.name
  tags = var.common_tags
}

# Elastic IP for stable public access
resource "aws_eip" "mid_server_eip" {
  instance = aws_instance.r2_d2_mid.id
  domain   = "vpc"

  tags = merge(var.common_tags, {
    Name = "r2-d2-mid-eip"
  })
}

# Route53 DNS record (optional)
resource "aws_route53_record" "mid_server_dns" {
  count   = var.create_dns_record ? 1 : 0
  zone_id = var.route53_zone_id
  name    = "mid-server.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.mid_server_eip.public_ip]
}

# CloudWatch Log Group for MID Server
resource "aws_cloudwatch_log_group" "mid_server_logs" {
  name              = "/aws/ec2/mid-server/${var.environment_name}"
  retention_in_days = 30

  tags = merge(var.common_tags, {
    Name = "r2-d2-mid-logs"
  })
}

# Outputs
output "instance_id" {
  description = "MID Server instance ID"
  value       = aws_instance.r2_d2_mid.id
}

output "public_ip" {
  description = "MID Server public IP"
  value       = aws_eip.mid_server_eip.public_ip
}

output "private_ip" {
  description = "MID Server private IP"
  value       = aws_instance.r2_d2_mid.private_ip
}

output "instance_details" {
  description = "Detailed information about MID Server"
  value = {
    id         = aws_instance.r2_d2_mid.id
    public_ip  = aws_eip.mid_server_eip.public_ip
    private_ip = aws_instance.r2_d2_mid.private_ip
    hostname   = "r2-d2-mid"
    os         = "Amazon Linux 2"
    role       = "ServiceNow MID Server"
    ssh_key    = var.key_name
    iam_role   = aws_iam_role.mid_server_role.arn
  }
}

output "connection_info" {
  description = "Connection information for MID Server"
  value = {
    ssh_command = "ssh -i ${var.key_name}.pem ec2-user@${aws_eip.mid_server_eip.public_ip}"
    mid_server_url = "https://${var.servicenow_instance}/mid_server_landing.do"
  }
}

# Variables
variable "public_subnet_id" {
  description = "Public subnet ID for MID Server"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for MID Server"
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
  description = "EC2 instance type for MID Server"
  type        = string
  default     = "t3.large"
}

variable "servicenow_instance" {
  description = "ServiceNow instance URL"
  type        = string
}

variable "create_dns_record" {
  description = "Whether to create Route53 DNS record"
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route53 zone ID for DNS record"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for DNS record"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}