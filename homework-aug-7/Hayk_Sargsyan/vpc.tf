resource "aws_vpc" "virtual_anhatakan_amp" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "im_amp"
  }
}