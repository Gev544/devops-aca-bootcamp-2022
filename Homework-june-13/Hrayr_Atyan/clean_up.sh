#!/bin/bash 
#getting ids

Instance_ID=$5
SG_ID=$4
IGW_ID=$3
Subnet_ID=$2
VPC_ID=$1


#delete Instance 
if [ ! -z $Instance_ID ]
then
	aws ec2 terminate-instances --instance-ids $Instance_ID

	#Checking if instance terminated
	status=$(aws ec2 describe-instances --instance-ids $InstanceID --output text \
       		--query Reservations[0].Instances[0].State.Code)
	while [ ! $status -eq 48 ]
	do
		sleep 4
		status=$(aws ec2 describe-instances --instance-ids $InstanceID --output text \
       		--query Reservations[0].Instances[0].State.Code)
	done
	sleep 2
fi


#delete Security Group 
if [ ! -z $SG_ID ]
then
	aws ec2 delete-security-group --group-id $SG_ID
fi

if [ ! -z $IGW_ID ]
then
	aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID 
	aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
fi

#delete subnets

if [ ! -z $Subnet_ID ]
then
	aws ec2 delete-subnet --subnet-id $Subnet_ID
fi

#delete VPC
if [ ! -z $VPC_ID ]
then
	aws ec2 delete-vpc --vpc-id $VPC_ID
fi
