resource "aws_db_subnet_group" "rds-group" {
  name       = "rds-group"
  subnet_ids = [aws_subnet.private-us-east-1e.id, aws_subnet.private-us-east-1f.id]
}

resource "aws_db_instance" "db_inst" {
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "12"
  instance_class         = "db.t3.micro"
  db_name                = "djangoproject"
  username               = var.rds_username
  password               = var.rds_password
  db_subnet_group_name   = aws_db_subnet_group.rds-group.name
  vpc_security_group_ids = [aws_security_group.db_sec_group.id]
  skip_final_snapshot    = true
}