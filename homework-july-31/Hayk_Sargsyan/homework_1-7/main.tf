# Create AWS EC2 instance
resource "aws_instance" "my-1stec2" {
  ami                    = "ami-052efd3df9dad4825"
  instance_type          = "t2.micro"
  count                  = 1
  vpc_security_group_ids = [aws_security_group.my_1stsg.id]
  subnet_id              = aws_subnet.my_1stsubnet.id
  key_name               = aws_key_pair.banali.id
  iam_instance_profile   = aws_iam_instance_profile.my-1stprofile.name
  user_data              = file("/home/sargsyan/Desktop/ACAum/kiraki2-31/userdata.txt")
  tags = {
    Name = "Barev_World"
  }
}
output "theID" {
    value = aws_instance.my-1stec2[*].id
    }
output "instance_public_ip" {
     value = aws_instance.my-1stec2[*].public_ip
}


# Create Key Pair
resource "aws_key_pair" "banali" {
  key_name   = "banali-key"
  public_key = file("/home/sargsyan/Desktop/ACAum/kiraki2-31/banali.pub")
}

# Creating VPC and Subnets
resource "aws_vpc" "my_1stvpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "tf_vpc"
  }
}

resource "aws_subnet" "my_1stsubnet" {
  vpc_id                  = aws_vpc.my_1stvpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf_subnet"
  }
}

# Create Security Group
resource "aws_security_group" "my_1stsg" {
  name   = "my_ec2_sg"
  vpc_id = aws_vpc.my_1stvpc.id

  dynamic "ingress" {
    for_each = ["80", "443", "22"]
  
  content {
    from_port   = ingress.value
    to_port     = ingress.value
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  }

    egress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}
tags = {
    Name = "mi-SG"
}

}

# Create Internet Gateway
resource "aws_internet_gateway" "my-1stIgw" {
  vpc_id = aws_vpc.my_1stvpc.id

  tags = {
    Name = "my-IGW"
  }
}

# Create Route Table
resource "aws_route_table" "my_1stRT" {
  vpc_id = aws_vpc.my_1stvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-1stIgw.id
  }

    tags = {
    Name = "my_IGW"
  }
}

# Associate Subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my_1stsubnet.id
  route_table_id = aws_route_table.my_1stRT.id
}


terraform {
  backend "s3" {
    bucket = "ankap-bucket-2"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
  }