#!/bin/bash

set -e

#Delete keys if we want to run script 2nd time
aws ec2 delete-key-pair --key-name aws-homework-key

if [[ -f aws-homework-key.pem ]]
then
rm -f aws-homework-key.pem
fi

#Create a VPC with a 10.0.0.0/16 CIDR block

aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text > IDs.txt
vpcID=`cat IDs.txt | grep vpc-`
echo "new VPC ID is : $vpcID"

##Giving a DNS attribute
#aws ec2 modify-vpc-attribute --vpc-id $vpcID --enable-dns-support "{\"Value\":true}"

#Create a first subnet with a 10.0.1.0/24 CIDR block

aws ec2 create-subnet --vpc-id $vpcID --cidr-block 10.0.1.0/24 --query Subnet.SubnetId --output text >> IDs.txt
subnet1_ID=`cat IDs.txt | grep "subnet-" | head -1`
echo "new Subnet ID is : $subnet1_ID"

#Create a second subnet with a 10.0.2.0/24 CIDR block

aws ec2 create-subnet --vpc-id $vpcID --cidr-block 10.0.2.0/24 --query Subnet.SubnetId --output text >> IDs.txt
subnet2_ID=`cat IDs.txt | grep "subnet-" | tail -1`
echo "second Subnet ID is : $subnet2_ID"

#Create an internet gateway

aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text >> IDs.txt
igwID=`cat IDs.txt | grep "igw-"`
echo "Internet Gateway ID is : $igwID"

#Attach the internet gateway to  VPC 

aws ec2 attach-internet-gateway --vpc-id $vpcID --internet-gateway-id $igwID
echo "Attach the internet gateway to VPC"

#Create a custom route table for  VPC 

aws ec2 create-route-table --vpc-id $vpcID --query RouteTable.RouteTableId --output text >> IDs.txt
rtID=`cat IDs.txt | grep "rtb-"`
echo "Route Table ID is : $rtID"

#Create a route in the route table that points all traffic (0.0.0.0/0) to the internet gateway

aws ec2 create-route --route-table-id $rtID --destination-cidr-block 0.0.0.0/0 --gateway-id $igwID
echo "Create a route in the route table with 0.0.0.0/0"

#Associate a subnet with the custom route table, we make our subnet public

aws ec2 associate-route-table  --subnet-id $subnet1_ID --route-table-id $rtID --query "AssociationId" --output text >> IDs.txt

echo "Public Subnet is associated with custom route table"

#Create a key pair and pipe your private key directly into a file with the .pem extension

aws ec2 create-key-pair --key-name aws-homework-key --query "KeyMaterial" --output text > aws-homework-key.pem
echo "Key Pair created"

#Change file permisions

chmod 400 aws-homework-key.pem
echo "key permissions are changed to 400"

#Create a security group in  VPC

aws ec2 create-security-group --group-name my-homework-SG --description "SG for homework SSH access" --vpc-id $vpcID --query "GroupId" --output text >> IDs.txt
sgID=`cat IDs.txt | grep "sg-"`
echo "Security Group ID is : $sgID"

#Add a rule that allows SSH and HTTP access from anywhere

aws ec2 authorize-security-group-ingress --group-id $sgID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sgID --protocol tcp --port 80 --cidr 0.0.0.0/0

#Launch 1 t2.micro instance into your public subnet, using the security group and key pair

aws ec2 run-instances --image-id ami-09d56f8956ab235b3 --count 1 --instance-type t2.micro --key-name aws-homework-key --associate-public-ip-address --security-group-ids $sgID --subnet-id $subnet1_ID --query 'Instances[*].InstanceId'  --output text >> IDs.txt
instanceID=`cat IDs.txt | grep "i-"`
echo "Instance ID is : $instanceID"
aws ec2 wait instance-running --instance-ids $instanceID 

#Checking Instance Status and Public IP address

aws ec2 describe-instances --instance-id $instanceID --query "Reservations[*].Instances[*].{State:State.Name,Address:PublicIpAddress}"




