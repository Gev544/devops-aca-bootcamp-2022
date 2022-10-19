#!/bin/bash

#taking input from user and creating .txt files for resources
echo "Enter the name for your resources: "
read resource_name

if [[ -z $resource_name ]]; then
  echo "Please input the name for your resources"
else
  if [[ -f ./resources_ids/$resource_name.txt ]]; then
    echo "Enter another name"
  else
    if [ ! -d ./resources_ids ]; then
      mkdir ./resources_ids
    fi

    if [ ! -d ./resources_ids ]; then
      mkdir ./user-key
    fi

    if [ ! -d ./resources_ids ]; then
      mkdir ./key-pairs
    fi

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
user_name="${resource_name}-User"


#create user
function createUser() {
  set -e
  user_id=$(aws iam create-user \
    --user-name $user_name \
    --permissions-boundary arn:aws:iam::aws:policy/AdministratorAccess \
    --query User.UserId \
    --output text)

  if [[ $? != 0 ]]; then
    echo "can not create user"
  else
    echo "User created."
  fi
}

#put permissions for user
function putPermission() {
  set -e
  aws iam put-user-permissions-boundary \
    --permissions-boundary arn:aws:iam::aws:policy/AdministratorAccess \
    --user-name $user_name

  if [[ $? != 0 ]]; then
    echo "can not put permission"
    deleteUser
  else
    echo "permission created"
  fi
}

#attach policy
function attachPolicy() {
  set -e
  aws iam attach-user-policy \
          --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
          --user-name $user_name
  if [[ $? != 0 ]]; then
    echo "can not attach policy"
    deleteUser
  else
    echo "Policy attached."
  fi

}

#create access key for user
function createAccessKey() {
  set -e
  access_key=$(aws iam create-access-key \
    --user-name $user_name \
    --query AccessKey.AccessKeyId \
    --output text)

  if [[ $? != 0 ]]; then
    echo "can not create access key"
    deleteUser
  else
    echo "access key created."
    echo $access_key > ./user-key/${resource_name}'-user.txt'
  fi

}

#create secret access key for user
function createSecretAccessKey() {
  set -e
  secret_access_key=$(aws iam create-access-key \
    --user-name $user_name \
    --query AccessKey.SecretAccessKey \
    --output text)

  if [[ $? != 0 ]]; then
    echo "can not create secret access key"
    deleteUser
  else
    echo "Secret access key created."
    echo $secret_access_key >> ./user-key/${resource_name}'-user.txt'
  fi
}

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
  --output text > /dev/null

  aws ec2 authorize-security-group-ingress \
  --group-id $security_group_id \
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
    echo "waiting to run instance"
    aws ec2 wait instance-status-ok \
    --instance-ids $instance_id
    echo "Instance is running."
    echo $instance_id >> ./resources_ids/$resource_name.txt
  fi
}
