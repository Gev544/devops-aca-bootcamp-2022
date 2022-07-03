#!/bin/bash

#Create a VPC and subnets

##Create a VPC with a 10.0.0.0/16 CIDR block

VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)

##create a subnet with a 10.0.1.0/24 CIDR block

aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24

##Create a second subnet in VPC with a 10.0.0.0/24 CIDR block

aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.0.0/24

#Make subnet public

##Create an internet gateway

Gateway=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)


##attach the internet gateway to VPC

aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $Gateway

##Create a custom route table

Route=$(aws ec2 create-route-table --vpc-id $VPC_ID --query RouteTable.RouteTableId --output text)

##Create default gateway

aws ec2 create-route --route-table-id $Route --destination-cidr-block 0.0.0.0/0 --gateway-id $Gateway

##list subnets

Subnet=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].{ID:SubnetId,CIDR:CidrBlock}")

##associate subnet with the custom route table

aws ec2 associate-route-table  --subnet-id $Subnet --route-table-id $Route

#Launch an instance

##Create a key pair

aws ec2 create-key-pair --key-name MyKeyPair --query "KeyMaterial" --output text > MyKeyPair.pem

chmod 400 MyKeyPair.pem

##create a security group

SecurityGroup=$(aws ec2 create-security-group --group-name SSHAccess --description "Security group for SSH access" --vpc-id $VPC_ID)

##allow SSH access from anywhere

aws ec2 authorize-security-group-ingress --group-id $SecurityGroup --protocol tcp --port 22 --cidr 0.0.0.0/0

##Add default AMI address

AMI_ID="ami-00000000"

##Launch an instance

aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type t2.micro --key-name MyKeyPair --security-group-ids $SecurityGroup --subnet-id $Subnet

