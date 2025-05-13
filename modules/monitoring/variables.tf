variable "private_subnet_id" {
  type        = string
  description = "Private subnet ID to launch the monitoring instance"
}

variable "security_group_id" {
  type        = string
  description = "Security group ID for the monitoring instance"
}

variable "key_name" {
  type        = string
  description = "Key pair name to access the instance"
}

variable "environment_name" {
  type        = string
  description = "Environment name for tagging and instance naming"
}
