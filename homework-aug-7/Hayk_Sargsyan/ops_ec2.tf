# Create AWS EC2 instance
resource "aws_instance" "my-1stec2" {
  ami                    = "ami-052efd3df9dad4825"
  instance_type          = "t2.micro"
  count                  = 1
  vpc_security_group_ids = [aws_security_group.my_1stsg.id]
  subnet_id              = aws_subnet.public-us-east-1a.id
  key_name               = aws_key_pair.banali.id
  #user_data              = file("/home/sargsyan/Desktop/ACAum/kiraki2-31/userdata.txt")
  tags = {
    Name = "ops-ec2"
  }
}

# Create Key Pair
resource "aws_key_pair" "banali" {
  key_name   = "banali-key"
  public_key = file("./banali.pub")
}
