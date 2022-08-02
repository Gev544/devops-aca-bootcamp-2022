variable "region" {
  description = "Region"
  default     = "eu-central-1"
}

variable "vpc_cidr_block" {
  description = "CIDR Block of the VPC"
  default     = "172.20.0.0/16"
}

variable "subnet_cidr_block" {
  description = "CIDR Block of the subnet"
  default     = "172.20.0.0/24"
}

variable "ssh_public_key_path" {
  description = "Path of the SSH Public Key"
  default     = "./ec2-key.pem.pub"
}

variable "ec2_instance_type" {
  description = "Type of the EC2 Instance"
  default     = "t2.micro"
}