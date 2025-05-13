variable "vpc_id" {
  type        = string
  description = "VPC ID for the ALBs"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs"
}

variable "security_group_id" {
  type        = string
  description = "Security group for the ALBs"
}

variable "environment_name" {
  type        = string
  description = "Environment name for naming resources"
}

variable "windows_targets" {
  type        = list(list(string))
  description = "Nested list of EC2 instance IDs for Windows targets"
}

variable "linux_targets" {
  type        = list(list(string))
  description = "Nested list of EC2 instance IDs for Linux targets"
}
