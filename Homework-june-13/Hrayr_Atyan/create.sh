#!/bin/bash 

#Creating VPC 
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.10.0.0/16 --query Vpc.VpcId --output text)

if [ ! $? -eq 0 ]
then
	echo "Can't create VPC"
	exit
fi

#Creating Subnet 
Subnet_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.10.0.0/24 --query Subnet.SubnetId --output text)

if [ ! $? -eq 0 ]
then
	echo "Can't create SUBNET"
	./cleanup.sh $VPC_ID
	exit
fi

#Creating Internet Gateway for VPC
IGW_ID=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)

if [ ! $? -eq 0 ]
then
	echo "Can't create Internet Gateway"
	./cleanup.sh $VPC_ID $Subnet_ID
	exit
fi

#Attach it to VPC
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID

#Getting its route table id
RTB_ID=$(aws ec2 describe-route-tables --output text| grep ROUTETABLES | grep $VPC_ID | grep -o "rtb-\w*")

#Creating route to gateway
aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID 1>/dev/null

#Creating Security Group
SG_ID=$(aws ec2 create-security-group --vpc-id $VPC_ID --group-name my-secgroup --description 'not special Secgroup' --query GroupId --output text)

if [ ! $? -eq 0 ]
then
	echo "Can't create SUBNET"
	./cleanup.sh $VPC_ID $Subnet_ID $IGW_ID
	exit
fi

#Writing rules for SG
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0

#Creating key pair

#checking if exists key with that name and delete it

aws ec2 describe-key-pairs --key-names MyKeyPair 1>/dev/null
if [ $? -eq 0 ]
then
	aws ec2 delete-key-pair --key-name MyKeyPair
fi
aws ec2 create-key-pair --key-name MyKeyPair --query "KeyMaterial" --output text > MyKeyPair.pem
chmod 400 MyKeyPair.pem


#Creating EC2 Instance with Ubuntu OS and Public Address
Instance_ID=$(aws ec2 run-instances --image-id ami-09d56f8956ab235b3 --count 1 --instance-type t2.micro --key-name MyKeyPair \
	--security-group-ids $SG_ID --subnet-id $Subnet_ID --associate-public-ip-address --output text \
       	| grep INSTANCES | grep -o "\bi-0\w*")

if [ ! $? -eq 0 ]
then
	echo "Can't run the instance"
	./cleanup.sh $VPC_ID $Subnet_ID $IGW_ID $SG_ID
	exit
fi

#Getting its Public IP addres
Public_IP=$(aws ec2 describe-instances --instance-ids $Instance_Id --query Reservations[*].Instances[*].PublicIpAddress --output text)

echo SUCCES!

echo $VPC_ID > ids
echo $Subnet_ID >> ids
echo $RTB_ID >> ids 
echo $IGW_ID >> ids
echo $SG_ID >> ids
echo $Instance_ID >> ids 
echo $Public_IP >> ids 

