
resource "aws_vpc" "galaxy_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "galaxy-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "outer_rim_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.galaxy_vpc.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "outer-rim-subnet-${count.index + 1}"
  }
}

# Private Subnets
resource "aws_subnet" "core_worlds_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.galaxy_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "core-worlds-subnet-${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "hyperspace_igw" {
  vpc_id = aws_vpc.galaxy_vpc.id
  
  tags = {
    Name = "hyperspace-igw"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "lightspeed_eip" {
  domain = "vpc"
  
  tags = {
    Name = "lightspeed-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "lightspeed_nat" {
  allocation_id = aws_eip.lightspeed_eip.id
  subnet_id     = aws_subnet.outer_rim_subnets[0].id
  
  tags = {
    Name = "lightspeed-nat"
  }
  
  depends_on = [aws_internet_gateway.hyperspace_igw]
}

# Public Route Table
resource "aws_route_table" "kessel_run_route" {
  vpc_id = aws_vpc.galaxy_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hyperspace_igw.id
  }
  
  tags = {
    Name = "kessel-run-route"
  }
}

# Private Route Table
resource "aws_route_table" "hyperspace_lane_route" {
  vpc_id = aws_vpc.galaxy_vpc.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lightspeed_nat.id
  }
  
  tags = {
    Name = "hyperspace-lane-route"
  }
}

# Associate Public Route Table with Public Subnets
resource "aws_route_table_association" "public_rt_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.outer_rim_subnets[count.index].id
  route_table_id = aws_route_table.kessel_run_route.id
}

# Associate Private Route Table with Private Subnets
resource "aws_route_table_association" "private_rt_association" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.core_worlds_subnets[count.index].id
  route_table_id = aws_route_table.hyperspace_lane_route.id
}
