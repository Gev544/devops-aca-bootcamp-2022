#!/bin/bash

echo "start..."

# Create vpc with cidr block 10.0.0.0//16
function createVpc() { 
    set -e

    AWS_VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --query 'Vpc.{VpcId:VpcId}' \
    --output text)

    if [[ $? -ne 0 ]]; then
		cleanUp
        echo 'asdasz'
	else 
        echo "Creating Vpc..."
	fi
}

# Create a public subnet
function createSubnet() { 
   set -e
  
   echo "Creating subnet..."
    AWS_SUBNET_PUBLIC_ID=$(aws ec2 create-subnet \
    --vpc-id $AWS_VPC_ID --cidr-block 10.0.1.0/24 \
    --availability-zone us-east-1f --query 'Subnet.{SubnetId:SubnetId}' \
    --output text)

    if [[ $? -ne 0 ]]; then
		cleanUp
	else 
        echo "Creating subnet..."
	fi
}

# Create an Internet Gateway
function createInternetGateway() { 
    set -e

    AWS_INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway \
    --query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
    --output text)

    if [[ $? -ne 0 ]]; then
		cleanUp
	else 
        echo "Creating Internet Gateway..."
	fi
}

# Attach Internet gateway to your VPC
function attachGiveaway() { 
    set -e

    echo "Attach Internet Gateway to VPC..."
    aws ec2 attach-internet-gateway \
    --vpc-id $AWS_VPC_ID \
    --internet-gateway-id $AWS_INTERNET_GATEWAY_ID
}

# Create a route table
function createRouteTable() { 
    set -e

    AWS_CUSTOM_ROUTE_TABLE_ID=$(aws ec2 create-route-table \
    --vpc-id $AWS_VPC_ID \
    --query 'RouteTable.{RouteTableId:RouteTableId}' \
    --output text )

    if [[ $? -ne 0 ]]; then
		cleanUp
	else 
        echo "Creating Internet Route Table..."
	fi
}

# Create route to Internet Gateway
function createRouteGtw() { 
    set -e

    aws ec2 create-route \
    --route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $AWS_INTERNET_GATEWAY_ID
   
    if [[ $? -ne 0 ]]; then
		cleanUp
	else 
      echo "Create route to Internet Gateway..."
	fi
}


# Associate the public subnet with route table
function associateSubnet() { 
    set -e

    echo "Associate the public subnet with route table..."
    AWS_ROUTE_TABLE_ASSOID=$(aws ec2 associate-route-table  \
    --subnet-id $AWS_SUBNET_PUBLIC_ID \
    --route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
    --output text)

    if [[ $? -ne 0 ]]; then
		cleanUp
	else 
      echo "Create route to Internet Gateway..."
	fi
}

# Associate the public subnet with route table
function createSecurityGroup() { 
    set -e

    echo "create Security Group..."
    AWS_SECURITY_GROUP=$(aws ec2 create-security-group \
    --tag-specification 'ResourceType=security-group,Tags=[{Key=Name,Value='securityGroup'}]' \
    --group-name SSH-HTTP-Access \
    --description "Security group" \
    --vpc-id $AWS_VPC_ID \
    --query GroupId \
    --output text)

    if [[ $? -ne 0 ]]; then
		cleanUp
	else 
      echo "Create route to Internet Gateway..."
	fi
}

# Open the SSH port(22)
function openSSH() { 
    set -e

    aws ec2 authorize-security-group-ingress \
    --group-id $AWS_SECURITY_GROUP \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

    if [[ $? -ne 0 ]]; then
		cleanUp
	else 
      echo "Open the SSH port(22)..."
	fi
}

#Generate Key Pair
function generateKeyPair() { 
    set -e

    AWS_KEY_PAIR=$(aws ec2 create-key-pair \
    --key-name EC2Key \
    --query "KeyMaterial" \
    --output text > EC2Key.pem && \
    chmod 400 EC2Key.pem)

    if [[ $? -ne 0 ]]; then
		cleanUp
	else 
        echo "generate Key Pair..."
	fi
}

#create ec2 instance
function createAwsEc2Instance() { 
    set -e

    echo "create instance..."
    AWS_INSTANCE=$(aws ec2 run-instances \
        --tag-specification 'ResourceType=instance,Tags=[{Key=Name,Value='ec2'}]' \
        --image-id ami-08d4ac5b634553e16 \
        --count 1 \
        --instance-type t2.micro \
        --key-name EC2Key \
        --security-group-ids $AWS_SECURITY_GROUP \
        --subnet-id $AWS_SUBNET_PUBLIC_ID \
        --associate-public-ip-address >/dev/null )
    
        if [[ $? -ne 0 ]]; then
            cleanUp
        else 
            echo "create instance..."
        fi
        
}


function start () {
    createVpc
    createSubnet
    createInternetGateway
    createInternetGateway
    attachGiveaway
    createRouteTable
    createRouteGtw
    associateSubnet
    createSecurityGroup
    openSSH
    generateKeyPair
    createAwsEc2Instance
}

start

function cleanUp () {
    ## Delete custom security group
    aws ec2 delete-security-group \
    --group-id $AWS_SECURITY_GROUP
    
    ## Delete internet gateway
    aws ec2 detach-internet-gateway \
    --internet-gateway-id $AWS_INTERNET_GATEWAY_ID \
    --vpc-id $AWS_VPC_ID &&
    aws ec2 delete-internet-gateway \
    --internet-gateway-id $AWS_INTERNET_GATEWAY_ID
    
    ## Delete the custom route table
    aws ec2 disassociate-route-table \
    --association-id $AWS_ROUTE_TABLE_ASSOID &&
    aws ec2 delete-route-table \
    --route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID
    
    ## Delete the public subnet
    aws ec2 delete-subnet \
    --subnet-id $AWS_SUBNET_PUBLIC_ID
    
    ## Delete the vpc
    aws ec2 delete-vpc \
}

echo "EC2 instance is created..."
