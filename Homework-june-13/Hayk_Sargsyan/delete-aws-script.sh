#!/bin/bash


instanceID=`cat IDs.txt | grep i-`
sgID=`cat IDs.txt |grep sg-`
rtID=`cat IDs.txt | grep rtb-`
rtassocID=`cat IDs.txt |grep rtbassoc-`
subnet1_ID=`cat IDs.txt | grep subnet- | head -1`
subnet2_ID=`cat IDs.txt | grep subnet- | tail -1`
igwID=`cat IDs.txt | grep igw-`
vpcID=`cat IDs.txt | grep vpc-`



#Terminating instance
aws ec2 terminate-instances \
	--instance-ids $instanceID
echo "Terminating INSTANCE !"
aws ec2 wait instance-terminated \
	--instance-ids $instanceID

#Deleting Security Group

aws ec2 delete-security-group \
	--group-id $sgID
echo "Deleting Security Group !"

#Disassociate a route table

aws ec2 disassociate-route-table \
	--association-id $rtassocID
echo "Disassociating a Route Table !"

#Deleting Route Table

aws ec2 delete-route-table \
	--route-table-id $rtID
echo "Deleting Route Table !"

#Deleting Subnets

aws ec2 delete-subnet \
	--subnet-id $subnet1_ID
aws ec2 delete-subnet \
	--subnet-id $subnet2_ID
echo "Deleting Subnets !"

#Detaching Internet Gateway

aws ec2 detach-internet-gateway \
	--internet-gateway-id $igwID \
	--vpc-id $vpcID
echo "Detaching Internet Gateway !"

#Deleting Internet Gateway

aws ec2 delete-internet-gateway \
	--internet-gateway-id $igwID
echo "Deleting Internet Gateway !"

#Deleting VPC

aws ec2 delete-vpc \
	--vpc-id $vpcID
echo "Deleting VPC !!!"

#Deleting Keys
aws ec2 delete-key-pair \
	--key-name aws-homework-key

if [[ -f aws-homework-key.pem ]]
then
rm -f aws-homework-key.pem IDs.txt
echo "Deleting Key Pairs"
fi

echo "--------EVERYTHING IS DELETED---------"
