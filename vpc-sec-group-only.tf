# VPC Module - The Galaxy
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# Security Groups - Imperial and Rebel Forces
module "security_groups" {
  source           = "./modules/security_groups"
  vpc_cidr         = var.vpc_cidr
  vpc_id           = module.vpc.vpc_id
  environment_name = var.environment_name
}