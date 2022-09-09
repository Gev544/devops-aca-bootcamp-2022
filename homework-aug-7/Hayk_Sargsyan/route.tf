resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.virtual_anhatakan_amp.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.im_igw.id
  }

  tags = {
    Name = "public_rt"
  }
  # depends_on = [
  #   aws_internet_gateway.im_igw
  # ]
}

resource "aws_route_table_association" "public-us-east-1a" {
  subnet_id      = aws_subnet.public-us-east-1a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public-us-east-1b" {
  subnet_id      = aws_subnet.public-us-east-1b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public-us-east-1c" {
  subnet_id      = aws_subnet.public-us-east-1c.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public-us-east-1d" {
  subnet_id      = aws_subnet.public-us-east-1d.id
  route_table_id = aws_route_table.public_rt.id
}