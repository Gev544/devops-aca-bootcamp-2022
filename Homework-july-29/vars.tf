variable "aws-region" {
	default = "us-east-1"
	description = "AWS region for resources"
	type = string
}

variable "vpc-cidr" {
	default = "10.0.0.0/16"
	description = "VPC CIDR BLOCK"
	type = string
}

variable "public-subnet" {
	default = "10.0.0.0/24"
	description = "public-subnet"
	type = string
}

variable "ssh-location" {
	default = "0.0.0.0/0"
	description = "SSH variable"
	type = string
}

variable "instance_type" {
	type        = string
	default     = "t2.micro"
}

variable key_name {
	default     = "homework-aca"
	type = string
}