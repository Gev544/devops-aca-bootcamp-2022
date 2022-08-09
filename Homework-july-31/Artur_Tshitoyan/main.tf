provider "aws" {
    region = var.aws_region
}

terraform {
backend "s3" {
    bucket = "myvpc-s3-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

variable aws_region {}
variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable rtb_cidr_block {}
variable my_ip {}
variable instance_type {}
variable public_key_location {}

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id            = aws_vpc.myapp-vpc.id 
    cidr_block        = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags   = {
        Name: "${var.env_prefix}-igw"
    }
}

resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id
    route {
        cidr_block = var.rtb_cidr_block
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name: "${var.env_prefix}-rtb"
    }
}

resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id      = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}

resource "aws_security_group" "myapp-sg" {
    name   = "myapp-sg"
    vpc_id = aws_vpc.myapp-vpc.id
    
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.my_ip]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
    tags = {
        Name: "${var.env_prefix}-sg"
    }
}

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

output "image_id" {
    value = data.aws_ami.ubuntu.id
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "server_key"
  public_key = file(var.public_key_location)
}

resource "aws_iam_policy" "smm_policy" {
  name        = "smm_policy"
  path        = "/"
  description = "Policy to provide smm permission to EC2"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData",
                "ds:CreateComputer",
                "ds:DescribeDirectories",
                "ec2:DescribeInstanceStatus",
                "logs:*",
                "ssm:*",
                "ec2messages:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "arn:aws:iam::*:role/aws-service-role/ssm.amazonaws.com/AWSServiceRoleForAmazonSSM*",
            "Condition": {
                "StringLike": {
                    "iam:AWSServiceName": "ssm.amazonaws.com"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:DeleteServiceLinkedRole",
                "iam:GetServiceLinkedRoleDeletionStatus"
            ],
            "Resource": "arn:aws:iam::*:role/aws-service-role/ssm.amazonaws.com/AWSServiceRoleForAmazonSSM*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        }
    ]
  })
  }
  
resource "aws_iam_role" "ssm_role" {
  name               = "ssm_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "ssm-role"
  }
}

resource "aws_iam_policy_attachment" "test-attach" {
  name       = "ssm_attachment"
  roles      = [aws_iam_role.ssm_role.name]
  policy_arn = aws_iam_policy.smm_policy.arn
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ssm_profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "myapp-server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.myapp-sg.id]
  availability_zone           = var.avail_zone
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name
    
  tags = {
    Name = "${var.env_prefix}-Ubuntu-20.04-server"
    }
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.myapp-server.public_ip
}

resource "aws_s3_bucket" "b" {
  bucket = "myvpc-s3"

  tags = {
    Name = "${var.env_prefix}-My_bucket"
    }
}

resource "aws_s3_bucket_acl" "b" {
  bucket = aws_s3_bucket.b.id
  acl    = "private"
}

