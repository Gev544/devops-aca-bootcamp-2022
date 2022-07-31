
# AWS region
provider "aws" {
    region                    = "us-east-1"
  
}

# AWS Instance
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name                      = "name"
    values                    = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name                      = "virtualization-type"
    values                    = ["hvm"]
  }

  
}

# AWS Instance create
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.SG.id]
  subnet_id                   =  aws_subnet.subnet.id 
  key_name                    = aws_key_pair.credentional.id
  associate_public_ip_address = true
    
    
    tags = {
      Name = "my_instance_terraform"
  }
}



# Create Security Group
resource "aws_security_group" "SG" {
  name                        = "SG_Group"
  vpc_id                      = aws_vpc.vpc.id

  ingress {
    from_port                 = 443
    to_port                   = 443
    protocol                  = "tcp"
    cidr_blocks               = ["0.0.0.0/0"]
    
  }
  ingress {
    from_port                 = 80
    to_port                   = 80
    protocol                  = "tcp"
    cidr_blocks               = ["0.0.0.0/0"]
    
  }

ingress {
    from_port                 = 22
    to_port                   = 22
    protocol                  = "tcp"
    cidr_blocks               = ["0.0.0.0/0"]
    
  }
  egress {
    from_port                 = 0
    to_port                   = 0
    protocol                  = "-1"
    cidr_blocks               = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "Security_Group"
  }
}


