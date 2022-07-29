# getting ubuntu 20.04 ami
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# declaring ec2 instance
resource "aws_instance" "tf-homework-instance" {
  ami                    = data.aws_ami.ubuntu.id
  key_name               = aws_key_pair.tf-homework-key-pair.id
  subnet_id              = aws_subnet.tf-homework-subnet.id
  instance_type          = var.ec2_instance_type
  vpc_security_group_ids = [aws_security_group.tf-homework-security-group.id]

  root_block_device {
    delete_on_termination = true
    volume_type           = "standard"
  }

  tags = {
    Name = "tf-homework-instance"
  }
}

# outputing instance public ip
output "instance_ip_address" {
  value = aws_instance.tf-homework-instance.public_ip
}