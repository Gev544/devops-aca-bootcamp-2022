provider "aws" {
    region = "${var.aws_region}"
}

#move tfstate file to s3 bucket
terraform {
  backend "s3" {
    bucket = "my-bucket-aca-terraform"
    key    = "states"
    region = "us-east-1"
  }
}