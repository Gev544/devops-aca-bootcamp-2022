#!/bin/bash 
#getting ids

IAM_user=$7
Bucket_name=$6
Instance_ID=$5
SG_ID=$4
IGW_ID=$3
Subnet_ID=$2
VPC_ID=$1


#delete Instance 
if [ ! -z $Instance_ID ]
then
	aws ec2 terminate-instances --instance-ids $Instance_ID 1>/dev/null

	#Checking if instance terminated
	aws ec2 wait instance-terminated --instance-ids $Instance_ID
fi


#delete Security Group 
if [ ! -z $SG_ID ]
then
	aws ec2 delete-security-group --group-id $SG_ID
fi

#delete Internet Gateway
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

#delete bucket
if [ ! -z $Bucket_name ]
then
	aws s3 rm s3://$Bucket_name --recursive
	aws s3 rb s3://$Bucket_name
fi

#delete IAM user
if [ ! -z $IAM_user ]
then
	Access_Key_ID=$(aws iam list-access-keys --user-name $IAM_user --output text --query 'AccessKeyMetadata[*].AccessKeyId')
	aws iam delete-access-key --user-name $IAM_user --access-key-id $Access_Key_ID
	aws iam detach-user-policy --user-name $IAM_user --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
	aws iam delete-user --user-name $IAM_user
fi

#deleting added files
rm -f ids
rm -f MyKeyPair.pem
rm -f iam_credentials