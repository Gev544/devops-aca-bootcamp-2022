# declaring ssh public key
resource "aws_key_pair" "tf-homework-key-pair" {
  key_name   = "tf-homework-key-pair"
  public_key = file("${var.ssh_public_key_path}")

  tags = {
    Name = "tf-homework-key-pair"
  }
}

# declaring security group
resource "aws_security_group" "tf-homework-security-group" {
  vpc_id      = aws_vpc.tf-homework-vpc.id
  name        = "tf-homework-security-group"
  description = "Allow inbound 22/tcp, 80/tcp and 81/tcp"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 81
    to_port     = 81
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-homework-security-group"
  }
}