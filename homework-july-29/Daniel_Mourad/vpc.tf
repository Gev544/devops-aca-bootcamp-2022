# declaring vpc
resource "aws_vpc" "tf-homework-vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tf-homework-vpc"
  }
}

# declaring subnet
resource "aws_subnet" "tf-homework-subnet" {
  vpc_id                  = aws_vpc.tf-homework-vpc.id
  cidr_block              = var.subnet_cidr_block
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-homework-subnet"
  }
}

# declaring internet gateway
resource "aws_internet_gateway" "tf-homework-internet-gateway" {
  vpc_id = aws_vpc.tf-homework-vpc.id

  tags = {
    Name = "tf-homework-internet-gateway"
  }
}

# declaring route table
resource "aws_route_table" "tf-homework-route-table" {
  vpc_id = aws_vpc.tf-homework-vpc.id

  tags = {
    Name = "tf-homework-route-table"
  }
}

# creating route to anywhere
resource "aws_route" "tf-homework-route" {
  route_table_id         = aws_route_table.tf-homework-route-table.id
  gateway_id             = aws_internet_gateway.tf-homework-internet-gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

# associating route table with vpc
resource "aws_main_route_table_association" "tf-homework-route-table-association" {
  vpc_id         = aws_vpc.tf-homework-vpc.id
  route_table_id = aws_route_table.tf-homework-route-table.id
}

# associating route table with subnet
resource "aws_route_table_association" "tf-homework-subnet-association" {
  subnet_id      = aws_subnet.tf-homework-subnet.id
  route_table_id = aws_route_table.tf-homework-route-table.id
}