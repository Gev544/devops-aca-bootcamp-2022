resource "aws_internet_gateway" "im_igw" {
  vpc_id = aws_vpc.virtual_anhatakan_amp.id

  tags = {
    Name = "im_igw"
  }
}

