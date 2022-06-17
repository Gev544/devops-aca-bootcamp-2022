#!/bin/bash

echo "start..."

# Create vpc with cidr block 10.0.0.0//16
function createVpc() { 
    echo "Creating Vpc..."
    AWS_VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --query 'Vpc.{VpcId:VpcId}' \
    --output text)
}

# Create a public subnet
function createSubnet() { 
    echo "Creating subnet..."
    AWS_SUBNET_PUBLIC_ID=$(aws ec2 create-subnet \
    --vpc-id $AWS_VPC_ID --cidr-block 10.0.1.0/24 \
    --availability-zone us-east-1f --query 'Subnet.{SubnetId:SubnetId}' \
    --output text)
}

# Create an Internet Gateway
function createInternetGateway() { 
    echo "Creating Internet Gateway..."
    AWS_INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway \
    --query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
    --output text)
}

# Attach Internet gateway to your VPC
function attachGiveaway() { 
    echo "Attach Internet Gateway to VPC..."
    aws ec2 attach-internet-gateway \
    --vpc-id $AWS_VPC_ID \
    --internet-gateway-id $AWS_INTERNET_GATEWAY_ID
}

# Create a route table
function createRouteTable() { 
    echo "Creating Internet Route Table..."
    AWS_CUSTOM_ROUTE_TABLE_ID=$(aws ec2 create-route-table \
    --vpc-id $AWS_VPC_ID \
    --query 'RouteTable.{RouteTableId:RouteTableId}' \
    --output text )
}

# Create route to Internet Gateway
function createRouteGtw() { 
    echo "Create route to Internet Gateway..."
    aws ec2 create-route \
    --route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $AWS_INTERNET_GATEWAY_ID
}


# Associate the public subnet with route table
function associateSubnet() { 
    echo "Associate the public subnet with route table..."
    AWS_ROUTE_TABLE_ASSOID=$(aws ec2 associate-route-table  \
    --subnet-id $AWS_SUBNET_PUBLIC_ID \
    --route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
    --output text)
}

# Associate the public subnet with route table
function createSecurityGroup() { 
    echo "create Security Group..."
    AWS_SECURITY_GROUP=$(aws ec2 create-security-group \
    --tag-specification 'ResourceType=security-group,Tags=[{Key=Name,Value='securityGroup'}]' \
    --group-name SSH-HTTP-Access \
    --description "Security group" \
    --vpc-id $AWS_VPC_ID \
    --query GroupId \
    --output text)
}

# Open the SSH port(22)
function openSSH() { 
echo "Open the SSH port(22)..."
    aws ec2 authorize-security-group-ingress \
    --group-id $AWS_SECURITY_GROUP \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0
}

#Generate Key Pair
function generateKeyPair() { 
    echo "generate Key Pair..."
    AWS_KEY_PAIR=$(aws ec2 create-key-pair \
    --key-name EC2Key \
    --query "KeyMaterial" \
    --output text > EC2Key.pem && \
    chmod 400 EC2Key.pem)
}

#create ec2 instance
function createAwsEc2Instance() { 
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
}

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

echo "EC2 instance is created..."