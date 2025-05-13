variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name for resource naming"
  type        = string
  default     = "hackathon"
}
