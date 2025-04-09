# VPC Configuration
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "Main VPC"
  }
}

# Subnets across multiple AZs
resource "aws_subnet" "main_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.subnet_cidr_1
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true
  
  tags = {
    Name = "Main Subnet 1"
  }
}

resource "aws_subnet" "main_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.subnet_cidr_2
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = true
  
  tags = {
    Name = "Main Subnet 2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
  
  tags = {
    Name = "Main IGW"
  }
}

# Route Table
resource "aws_route_table" "rtable" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  
  tags = {
    Name = "Main Route Table"
  }
}

# Route Table Associations
resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.main_subnet_1.id
  route_table_id = aws_route_table.rtable.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.main_subnet_2.id
  route_table_id = aws_route_table.rtable.id
}