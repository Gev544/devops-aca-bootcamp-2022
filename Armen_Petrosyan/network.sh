#!/bin/bash 

#create vpc for ec2
VpcId=$(aws ec2 create-vpc --cidr-block 10.0.0.0/24 --query Vpc.VpcId --output text)
#Using $? variable to check last running command output is ok or error
if [ $? -eq 0 ]

then

    echo "  --> Your vpc is succesfully created without errors and bugs"

fi

#create public subnet
Pub_SubId=$(aws ec2 create-subnet --vpc-id $VpcId --cidr-block 10.0.0.0/24 --query Subnet.SubnetId --output text)

if [ $? -eq 0 ]

then

    echo "  --> Your public subnet is succesfully created without errors and bugs"

else

    aws ec2 delete-vpc --vpc-id $VpcId

fi



#Create internet gateway
Ig_Id=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)

if [ $? -eq 0 ]

then

    echo "  --> Your internet gateway is succesfully created without errors and bugs"

else

    aws ec2 delete-subnet --subnet-id $Pub_SubId
    aws ec2 delete-vpc --vpc-id $VpcId
    
fi


#Attach IG to vpc
aws ec2 attach-internet-gateway --vpc-id $VpcId --internet-gateway-id $Ig_Id

#Route table id
Route_TabId=$(aws ec2 describe-route-tables --output text | grep ROUTETABLES | grep $VpcId | grep -o "rtb-\w*")


#Create route table
aws ec2 create-route --route-table-id $Route_TabId --destination-cidr-block 0.0.0.0/0 --gateway-id $Ig_Id

if [ $? -eq 0 ]

then

    echo "  --> Your route table is succesfully created without errors and bugs"

else

    aws ec2 detach-internet-gateway --internet-gateway-id $Ig_Id --vpc-id $VpcId 
	aws ec2 delete-internet-gateway --internet-gateway-id $Ig_Id
    aws ec2 delete-subnet --subnet-id $Pub_SubId
    aws ec2 delete-vpc --vpc-id $VpcId
fi


Sec_GrId=$(aws ec2 create-security-group --group-name aca-homework-sg --description HomeWorkSG --vpc-id $VpcId)

if [ $? -eq 0 ]

then

    echo "  --> Your security group is succesfully created without errors and bugs"

else
    
    aws ec2 detach-internet-gateway --internet-gateway-id $Ig_Id --vpc-id $VpcId 
	aws ec2 delete-internet-gateway --internet-gateway-id $Ig_Id
    aws ec2 delete-subnet --subnet-id $Pub_SubId
    aws ec2 delete-vpc --vpc-id $VpcId
fi


#Open some ports in Security Group
aws ec2 authorize-security-group-ingress --group-id $Sec_GrId --protocol tcp --port 22 --cidr 0.0.0.0/0

if [ $? -eq 0 ]

then

    echo "  --> Your security group is succesfully created without errors and bugs"

else

    aws ec2 detach-internet-gateway --internet-gateway-id $Ig_Id --vpc-id $VpcId 
	aws ec2 delete-internet-gateway --internet-gateway-id $Ig_Id
    aws ec2 delete-subnet --subnet-id $Pub_SubId
    aws ec2 delete-vpc --vpc-id $VpcId
fi

aws ec2 authorize-security-group-ingress --group-id $Sec_GrId --protocol tcp --port 80 --cidr 0.0.0.0/0

if [ $? -eq 0 ]

then

    echo "  --> Your security group is succesfully created without errors and bugs"

else

	aws ec2 detach-internet-gateway --internet-gateway-id $Ig_Id --vpc-id $VpcId 
	aws ec2 delete-internet-gateway --internet-gateway-id $Ig_Id
    aws ec2 delete-subnet --subnet-id $Pub_SubId
    aws ec2 delete-vpc --vpc-id $VpcId

fi

if [ $? -eq 0 ]

then

    ./ec2.sh

else

    exit -1
fi