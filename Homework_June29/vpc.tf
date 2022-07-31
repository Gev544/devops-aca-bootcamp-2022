
# Create Subnet
resource "aws_subnet" "subnet" {
  
  vpc_id          = aws_vpc.vpc.id
  cidr_block      = "10.0.1.0/24"

  tags = {
    Name = "my_subnet"
  }
}


# Create VPC
resource "aws_vpc" "vpc" {
  
  cidr_block      = "10.0.0.0/16"

  tags = {
    Name          = "my_vpc"
  }
}


# Create route table
resource "aws_route_table" "r_table" {
  
  vpc_id          = aws_vpc.vpc.id

  route {
    cidr_block    = "0.0.0.0/0"
    gateway_id    = aws_internet_gateway.gw.id
  }
  
  tags = {
    Name          = "rout_table"
  }
}

# Create route table association
resource "aws_main_route_table_association" "aws_rtb_assoc" {
  
  vpc_id          = aws_vpc.vpc.id
  route_table_id  = aws_route_table.r_table.id
  

  tags = {
    Name          = "rout_table_association"
  }
}




# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
 
  vpc_id          = aws_vpc.vpc.id

  tags = {
    Name          = "internet_gateway"
  }
}