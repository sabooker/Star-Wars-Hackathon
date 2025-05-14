output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.galaxy_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.outer_rim_subnets[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.core_worlds_subnets[*].id
}

output "vpc_cidr" {
  value = aws_vpc.galaxy_vpc.cidr_block
}