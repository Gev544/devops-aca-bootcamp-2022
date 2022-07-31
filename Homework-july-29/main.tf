#create vpc
resource "aws_vpc" "hw_aca_vpc" {
  cidr_block = "${var.cidr-block-vpc}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name= "hw_aca_vpc"
  }
}

#create public subnet
resource "aws_subnet" "hw_aca_subnet" {
  vpc_id     = aws_vpc.hw_aca_vpc.id
  cidr_block = "${var.cidr-block-pb-subnet}"

  tags = {
    Name = "hw_aca_pb_subnet"
  }
}

#create gateway
resource "aws_internet_gateway" "hw_aca_gw" {
  vpc_id = aws_vpc.hw_aca_vpc.id

  tags = {
    Name = "hw_aca_gw"
  }
}

#create route table
resource "aws_route_table" "hw_aca_route_table" {
  vpc_id = aws_vpc.hw_aca_vpc.id

  route {
    cidr_block = "${var.cidr-block-route_tb}"
    gateway_id = aws_internet_gateway.hw_aca_gw.id
  }

  tags = {
    Name = "hw_aca_route_table"
  }
}

#route table association with public subnet
resource "aws_route_table_association" "hw_aca_association" {
  subnet_id      = aws_subnet.hw_aca_subnet.id
  route_table_id = aws_route_table.hw_aca_route_table.id
} 

#create security group
resource "aws_security_group" "hw_aca_security_group" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.hw_aca_vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.cidr-block-route_tb]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [var.cidr-block-route_tb]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.cidr-block-route_tb]
  }

  tags = {
    Name = "hw_aca_security_group"
  }
}

# create ssh key
resource "tls_private_key" "hw_create_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "hw_aca_key" {
  key_name   = "hw_aca_key"
  public_key = tls_private_key.hw_create_key.public_key_openssh
  
 tags = {
    Name = "hw_aca_key"
  }

 # create a "terraform-key.pem" to your computer!!
  provisioner "local-exec" {
    command = "echo '${tls_private_key.hw_create_key.private_key_pem}' > ./terraform-key.pem"
  }
}

#create ec2 instance
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  key_name = aws_key_pair.hw_aca_key.id
  subnet_id = aws_subnet.hw_aca_subnet.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.hw_aca_security_group.id]

  tags = {
    Name = "hw_aca_terraform"
  }
}