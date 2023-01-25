variable "aws_region" {    
    default = "us-east-1"
}

variable "cidr-block-vpc" {
    default = "10.0.0.0/18"
}

variable "cidr-block-pb-subnet" {
    default = "10.0.0.0/18"
}     

variable "cidr-block-route_tb" {
    default = "0.0.0.0/0"
}  

variable "iam_username" {
    default = "hw_aca_july31"
} 