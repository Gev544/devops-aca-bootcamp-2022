#!/bin/bash

set -ea;
function Create-vpc () {
echo "Creating an instance, please wait...";

# Create vpc && name
VPC_ID=$(aws ec2 create-vpc \
--cidr-block 10.0.0.0/24 \
--query 'Vpc.{VpcId:VpcId}' \
--output text) &&
aws ec2 create-tags \
--resources $VPC_ID --tags Key=Name,Value=MySecondVpc;


# Create a public subnet && name
SUBNET_PUB_ID=$(aws ec2 create-subnet \
--vpc-id $VPC_ID --cidr-block 10.0.0.0/24 \
--availability-zone us-east-1c --query 'Subnet.{SubnetId:SubnetId}' \
--output text) &&
aws ec2 create-tags \
--resources $SUBNET_PUB_ID --tags Key=Name,Value=MySecondSub;

# Enable auto-assign public ip
aws ec2 modify-subnet-attribute \
--subnet-id $SUBNET_PUB_ID \
--map-public-ip-on-launch;

# Create internet gateway && name
INT_GATEWAY_ID=$(aws ec2 create-internet-gateway \
--query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
--output text) &&
aws ec2 create-tags \
--resources $INT_GATEWAY_ID --tags Key=Name,Value=MySecondGateway;

# Attach gateway to the VPC
aws ec2 attach-internet-gateway \
--vpc-id $VPC_ID \
--internet-gateway-id $INT_GATEWAY_ID;

# Create a route table && name
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
--vpc-id $VPC_ID \
--query 'RouteTable.{RouteTableId:RouteTableId}' \
--output text ) &&
aws ec2 create-tags \
--resources $ROUTE_TABLE_ID --tags Key=Name,Value=MySecondRoute;

# Create a route to the route table
aws ec2 create-route \
--route-table-id $ROUTE_TABLE_ID \
--destination-cidr-block 0.0.0.0/0 \
--gateway-id $INT_GATEWAY_ID;

# Associate the subnet with route table
AWS_ROUTE_TABLE_ASSOID=$(aws ec2 associate-route-table  \
--subnet-id $SUBNET_PUB_ID \
--route-table-id $ROUTE_TABLE_ID \
--output text);
AWS_ROUTE_TABLE_ASSOID=$(echo $AWS_ROUTE_TABLE_ASSOID | awk '{ print $1; }');

# Create security group
aws ec2 create-security-group \
--vpc-id $VPC_ID \
--group-name myvpc-security-group \
--description 'Wizzard-2';

# Get security group id
SEC_GROUP_ID=$(aws ec2 describe-security-groups \
--filters "Name=vpc-id,Values=$VPC_ID" \
--query 'SecurityGroups[?GroupName == `myvpc-security-group`].GroupId' \
--output text);

# Create security rules
aws ec2 authorize-security-group-ingress \
--group-id $SEC_GROUP_ID \
--ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]}]' &&
aws ec2 authorize-security-group-ingress \
--group-id $SEC_GROUP_ID \
--ip-permissions '[{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow HTTP"}]}]';

}

Create-vpc && echo "Instance created" || ./cleanup.sh;

