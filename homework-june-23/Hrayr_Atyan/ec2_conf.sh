#!/bin/bash

mainInstance=$1

VPC_ID=$(aws ec2 describe-instances \
		--instance-ids $mainInstance \
		--query Reservations[0].Instances[0].NetworkInterfaces[0].VpcId \
		--output text)
SG_ID=$(aws ec2 describe-instances \
		--instance-ids $mainInstance \
		--query Reservations[0].Instances[0].NetworkInterfaces[0].Groups[0].GroupId \
		--output text)
Subnet_ID=$(aws ec2 describe-instances \
		--instance-ids $mainInstance \
		--query Reservations[0].Instances[0].NetworkInterfaces[0].SubnetId \
		--output text)



#Creating Subnet 
Second_Subnet_ID=$(aws ec2 create-subnet \
				--vpc-id $VPC_ID \
				--cidr-block 10.10.20.0/24 \
				--availability-zone us-east-1a \
				--query Subnet.SubnetId \
				--output text ) && \
				echo "Created second subnet"

if [ ! $? -eq 0 ]
then
	echo "Can't create SUBNET"
	exit 2
fi


#Creating EC2 Instance with Ubuntu OS and Public Address
Instance_ID=$(aws ec2 run-instances \
			--image-id ami-09d56f8956ab235b3 \
		 	--count 1 \
			--instance-type t2.micro \
			--key-name MyKeyPair \
			--security-group-ids $SG_ID \
			--subnet-id $Second_Subnet_ID \
			--associate-public-ip-address --output text \
       		| grep INSTANCES | grep -o "\bi-0\w*")

if [ ! $? -eq 0 ]
then
	echo "Can't run the instance"
	echo "Deleting subnet..."
	aws ec2 delete-subnet --subnet-id $Subnet_ID
	exit 2
fi

aws ec2 wait instance-status-ok \
	--instance-ids $Instance_ID
echo 'Second instance is running'


#Getting its Public IP addres
Public_IP=$(aws ec2 describe-instances \
			--instance-ids $Instance_ID \
			--query Reservations[*].Instances[*].PublicIpAddress \
			--output text)



echo $VPC_ID > ids
echo $Subnet_ID >> ids
echo $Second_Subnet_ID >> ids
echo $SG_ID >> ids
echo $mainInstance >> ids
echo $Instance_ID >> ids
echo $Public_IP >> ids
