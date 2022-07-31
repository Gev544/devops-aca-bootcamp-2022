
resource "aws_key_pair" "credentional" {
  key_name   = "key_for_terraform"
  public_key = file("./key_for_terraform.pub")

tags = {
    Name = "key"
  }
}
