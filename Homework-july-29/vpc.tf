# Create VPC
resource "aws_vpc" "vpc" {
	cidr_block = "${var.vpc-cidr}"
	enable_dns_hostnames = true
	tags = {
		Name = "${var.key_name}-vpc"
	}
}

# Create Public Subnet 1
resource "aws_subnet" "public-subnet" {
	vpc_id = aws_vpc.vpc.id
	cidr_block = "${var.public-subnet}"
	availability_zone = "us-east-1a"
	map_public_ip_on_launch = true
	tags = {
		Name = "${var.key_name}-subnet"
	}
}

# Create Internet Gateway and Attach it to VPC
resource "aws_internet_gateway" "internet-gateway" {
	vpc_id = aws_vpc.vpc.id
	tags = {
		Name = "${var.key_name}-ig"
	}
}

# Create Route Table and Add Public Route
resource "aws_route_table" "public-route-table" {
	vpc_id = aws_vpc.vpc.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.internet-gateway.id
	}
	tags = {
		Name = "${var.key_name}-rt"
	}
}

# Associate Public Subnet to "Public Route Table"
resource "aws_route_table_association" "subnet-route-table-association" {
	subnet_id = aws_subnet.public-subnet.id
	route_table_id = aws_route_table.public-route-table.id
}