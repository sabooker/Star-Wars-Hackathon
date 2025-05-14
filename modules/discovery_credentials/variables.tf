variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name for resource naming"
  type        = string
  default     = "hackathon"
}

variable "environment_name" {
  description = "Environment name for tagging"
  type = string
}