
#getting ids

Instance_ID=$5
SG_ID=$4
IGW_ID=$3
Subnet_ID=$2
VPC_ID=$1


#delete Instance 
if [ ! -z $Instance_ID ]
then
	aws ec2 terminate-instances --instance-ids $Instance_Id
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
