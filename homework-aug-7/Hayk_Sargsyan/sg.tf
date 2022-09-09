# Create Security Group
resource "aws_security_group" "my_1stsg" {
  name   = "my_ec2_sg"
  vpc_id = aws_vpc.virtual_anhatakan_amp.id

  dynamic "ingress" {
    for_each = ["80", "443", "9090", "3000", "8000", "8080", "22", "30001"]

    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "mi-SG"
  }

}

resource "aws_security_group_rule" "app_port" {
  type              = "ingress"
  from_port         = 30001
  to_port           = 30001
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_eks_cluster.im-cluster.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group" "db_sec_group" {
  name   = "my_db_sg"
  vpc_id = aws_vpc.virtual_anhatakan_amp.id

  ingress {
    from_port   = "5432"
    to_port     = "5432"
    protocol    = "tcp"
    # security_groups = aws_security_group.db_sec_group.id
    # cidr_blocks = [aws_subnet.private-us-east-1e.id, aws_subnet.private-us-east-1f.id] # uzum e 2rd subnet@
    cidr_blocks = [aws_vpc.virtual_anhatakan_amp.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}