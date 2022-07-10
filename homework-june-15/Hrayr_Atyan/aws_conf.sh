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
	./clean_up.sh $VPC_ID
	exit
fi

#Creating Internet Gateway for VPC
IGW_ID=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)

if [ ! $? -eq 0 ]
then
	echo "Can't create Internet Gateway"
	./clean_up.sh $VPC_ID $Subnet_ID
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
	./clean_up.sh $VPC_ID $Subnet_ID $IGW_ID
	exit
fi

#Writing rules for SG
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0

#Creating key pair

#checking if exists key with that name and delete it

aws ec2 describe-key-pairs --key-names MyKeyPair 1>/dev/null 2>/dev/null
if [ $? -eq 0 ]
then
	aws ec2 delete-key-pair --key-name MyKeyPair
fi
aws ec2 create-key-pair --key-name MyKeyPair --query "KeyMaterial" --output text > MyKeyPair.pem && \
chmod 400 MyKeyPair.pem


#Creating EC2 Instance with Ubuntu OS and Public Address
Instance_ID=$(aws ec2 run-instances --image-id ami-09d56f8956ab235b3 --count 1 --instance-type t2.micro --key-name MyKeyPair \
	--security-group-ids $SG_ID --subnet-id $Subnet_ID --associate-public-ip-address --output text \
       	| grep INSTANCES | grep -o "\bi-0\w*")

if [ ! $? -eq 0 ]
then
	echo "Can't run the instance"
	./clean_up.sh $VPC_ID $Subnet_ID $IGW_ID $SG_ID
	exit
fi

aws ec2 wait instance-status-ok \
	--instance-ids $Instance_ID

#Creating Bucket
Bucket_name=bucket.aca
aws s3 mb s3://$Bucket_name

if [ ! $? -eq 0 ]
then
	echo "Can't create bucket"
	echo "Deleting resources created before"
	./clean_up.sh $VPC_ID $Subnet_ID $IGW_ID $SG_ID $Instance_ID
	exit 2
fi


#Getting its Public IP addres
Public_IP=$(aws ec2 describe-instances --instance-ids $Instance_ID --query Reservations[*].Instances[*].PublicIpAddress --output text)


#Creating iam user for instance with S3Bucket access
IAM_user=s3user
aws iam create-user --user-name $IAM_user 1>/dev/null && \
aws iam attach-user-policy --user-name $IAM_user --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess && \
aws iam create-access-key --user-name $IAM_user > iam_credentials

if [ ! $? -eq 0 ]
then
	echo "Can't IAM user"
	echo "Deleting resources created before"
	./clean_up.sh $VPC_ID $Subnet_ID $IGW_ID $SG_ID $Instance_ID $Bucket_name
	exit 2
fi
Access_Key_ID=$(cat iam_credentials | grep AccessKeyId | awk '{print $2 }' | tr -d ",\"")
Secret_Access_Key=$(cat iam_credentials | grep SecretAccessKey | awk '{print $2 }' | tr -d ",\"")


echo SUCCES!!!
echo You can connect to it with IP Address:$Public_IP
 

echo $VPC_ID > ids
echo $Subnet_ID >> ids
echo $IGW_ID >> ids
echo $SG_ID >> ids
echo $Instance_ID >> ids 
echo $Bucket_name >> ids
echo $IAM_user >> ids
echo $Public_IP >> ids 
echo $Access_Key_ID:$Secret_Access_Key > web/.passwd-s3fs
