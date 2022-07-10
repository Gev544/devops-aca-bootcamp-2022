#!/bin/bash

#===default variables initialization===

#Resource tag PROJECT value
declare -r def_projecttag=june13

#AWS CLI profile name
declare -r def_awspn=awsclitest

#expire created resources after specified seconds
#   if set to 0, never expires
#   if set to -1, expires immediately
declare -r def_expireinseconds=3600

#CIDR of new VPC for new EC2 instance
declare -r def_vpccidr="10.10.0.0/16"

#CIDR of new subnet for new VPC
declare -r def_subnetcidr="10.10.10.0/24"

#EC2 image id
declare -r def_ec2imageid=ami-08d4ac5b634553e16

#EC2 instance type
declare -r def_ec2instancetype=t2.micro


#====
