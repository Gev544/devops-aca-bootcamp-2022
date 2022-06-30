#!/bin/bash

#taking input from user and creating .txt file for resource ids
echo "Enter the name for your resources: "
read resource_name

if [[ -z $resource_name ]]; then
  echo "Please input the name for your resources"
else
  if [[ -f ./resources_id/$resource_name.txt ]]; then
    echo "Enter another name"
  else
    touch ./resources_ids/$resource_name.txt
  fi
fi

source ./delete.sh

#generating resource names
vpc_name="${resource_name}-Vpc"
subnet_name="${resource_name}-Subnet"
igw_name="${resource_name}-Internet-Gateway"
route_table_name="${resource_name}-Route-Table"
sec_group_name="${resource_name}-Security-Group"
ssh_key_name="key-${resource_name}"
instance_name="${resource_name}-Instance"


#create VPC
function createVpc() {
  set -e
  vpc_id=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specification 'ResourceType=vpc,Tags=[{Key=Name,Value='$vpc_name'}]'\
    --query Vpc.VpcId \
    --output text)

  if [[ $? != 0 ]]; then
		echo "can not create vpc"
	else
		echo "VPC created."
    echo $vpc_id >> ./resources_ids/$resource_name.txt
	fi
}

#create subnet
function createSubnet() {
  set -e
  subnet_id=$(aws ec2 create-subnet \
  --vpc-id $vpc_id \
  --cidr-block 10.0.1.0/24 \
  --tag-specification 'ResourceType=subnet,Tags=[{Key=Name,Value='$subnet_name'}]' \
  --query Subnet.SubnetId \
  --output text)

  if [[ $? != 0 ]]; then
		deleteVpc
	else
		echo "Subnet created."
    echo $subnet_id >> ./resources_ids/$resource_name.txt
	fi
}

#create internet gateway
function createInternetGateway() {
  set -e
  igw_id=$(aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value='$igw_name'}]' \
    --query InternetGateway.InternetGatewayId \
		--output text)

    if [[ $? != 0 ]]; then
      deleteSubnet
		  deleteVpc
	else
		echo "Internet Gateway created."
    echo $igw_id >> ./resources_ids/$resource_name.txt
	fi
}

#attach the igw to the vpc
function attachIgw() {
  set -e
  aws ec2 attach-internet-gateway \
  --vpc-id $vpc_id \
  --internet-gateway-id $igw_id \
  --output text > /dev/null

  if [[ $? != 0 ]]; then
    deleteSubnet
    deleteInternetGateway
    deleteVpc
  else
    echo "The Internet Gateway attached to the VPC."
  fi
}

#create route table
function createRouteTable() {
  set -e
  route_table_id=$(aws ec2 create-route-table \
  --vpc-id $vpc_id \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value='$route_table_name'}]' \
  --query RouteTable.RouteTableId \
  --output text)


  if [[ $? != 0 ]]; then
    deleteSubnet
    detachIgw
    deleteInternetGateway
    deleteVpc
  else
    echo "Route Table created."
    echo $route_table_id >> ./resources_ids/$resource_name.txt
  fi
}

#create route
function createRoute() {
  set -e
  aws ec2 create-route \
  --route-table-id $route_table_id \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $igw_id \
  --output text > /dev/null

  if [[ $? != 0 ]]; then
    deleteSubnet
    deleteRouteTable
    detachIgw
    deleteInternetGateway
    deleteVpc
  else
    echo "Route Created."
  fi
}

#associate route table
function associateRouteTable() {
  set -e
  aws ec2 associate-route-table \
  --route-table-id $route_table_id \
  --subnet-id $subnet_id \
  --output text > /dev/null

  if [[ $? != 0 ]]; then
    deleteSubnet
    deleteRouteTable
    detachIgw
    deleteInternetGateway
    deleteVpc
  else
    echo "Route table associated."
  fi
}

#create security group
function createSecurityGroup() {
  set -e
  security_group_id=$(aws ec2 create-security-group \
  --group-name MySecurityGroup \
  --description "My security group" \
  --vpc-id $vpc_id \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value='$sec_group_name'}]' \
  --query GroupId \
  --output text)

  if [[ $? != 0 ]]; then
    deleteSecurityGroup
    deleteSubnet
    deleteRouteTable
    detachIgw
    deleteInternetGateway
    deleteVpc
  else
    echo "Security group created."
    echo $security_group_id >> ./resources_ids/$resource_name.txt
  fi
}

#authorize security group
function authorizeSecurityGroup() {
  set -e
  aws ec2 authorize-security-group-ingress \
  --group-id $security_group_id \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --output text > /dev/null

  if [[ $? != 0 ]]; then
    deleteSecurityGroup
    deleteSubnet
    deleteRouteTable
    detachIgw
    deleteInternetGateway
    deleteVpc
  else
    echo "Security group authorized."
  fi
}

#create key-pair
function createKeyPair() {
  set -e
  aws ec2 create-key-pair \
  --key-name $ssh_key_name \
  --query "KeyMaterial" \
	--output text > ./key-pairs/$ssh_key_name.pem && chmod 400 ./key-pairs/$ssh_key_name.pem

  if [[ $? != 0 ]]; then
    deleteSecurityGroup
    deleteSubnet
    deleteRouteTable
    detachIgw
    deleteInternetGateway
    deleteVpc
  else
    echo "Key-pair created."
    echo $ssh_key_name >> ./resources_ids/$resource_name.txt
  fi
}

#create instance
function createInstance() {
  set -e
  instance_id=$(aws ec2 run-instances \
  --image-id ami-052efd3df9dad4825 \
  --instance-type t2.micro \
  --count 1 \
  --subnet-id $subnet_id \
  --security-group-ids $security_group_id \
  --associate-public-ip-address \
  --key-name $ssh_key_name \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$instance_name'}]' \
  --output text | grep INSTANCES | grep -o "\bi-0\w*")

  if [[ $? != 0 ]]; then
    deleteKeyPair
    deleteSecurityGroup
    deleteSubnet
    deleteRouteTable
    detachIgw
    deleteInternetGateway
    deleteVpc
  else
    echo "Instance created."
    echo $instance_id >> ./resources_ids/$resource_name.txt
  fi
}
