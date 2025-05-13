terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region        = var.aws_region
  profile       = var.aws_account_profile
  default_tags {
    tags = {
      Project     = "Star-Wars-Hackathon"
      Environment = "Development"
      Purpose     = "ServiceNow Discovery POC"
    }
  }
}