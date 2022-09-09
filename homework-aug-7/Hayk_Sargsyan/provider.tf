provider "aws" {
  region = "us-east-1"
}

# locals {
#   cluster_name = "Im_cluster"
# }

terraform {
  backend "s3" {
    bucket = "tf-state-hamar"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
  }