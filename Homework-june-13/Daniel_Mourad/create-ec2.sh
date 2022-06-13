#!/bin/bash

set -e

ResourceIds="available_resource_ids.txt"

# creates vpc with 172.22.0.0/16 cidr block and sends vpc id to ResourceIds file
function createVPC () {
	aws ec2 create-vpc \
		--cidr-block 172.22.0.0/16 \
		--query Vpc.VpcId \
		--output text > $ResourceIds
	vpcId=$(cat $ResourceIds | head -1)
}

# creates subnet with 172.22.22.0/24 cidr block and sends subnet id to ResourceIds file
function createSubnet () {
	aws ec2 create-subnet \
		--vpc-id $vpcId \
		--cidr-block 172.22.22.0/24 \
		--query Subnet.SubnetId \
		--output text >> $ResourceIds
	subnetId=$(cat $ResourceIds | head -2 | tail +2)
}

# creates internet gateway and sends the id to ResourceIds file
function createInternetGateway () {
	aws ec2 create-internet-gateway \
		--query InternetGateway.InternetGatewayId \
		--output text >> $ResourceIds
	internetGatewayId=$(cat $ResourceIds | head -3 | tail +3)
}

# attaches internet gateway to the vpc
function attachInternetGatewayToVpc () {
	aws ec2 attach-internet-gateway \
		--vpc-id $vpcId \
		--internet-gateway-id $internetGatewayId \
		--output text > /dev/null
}

# creates route table and sends the id to ResourceIds file
function createRouteTable () {
	aws ec2 create-route-table \
		--vpc-id $vpcId \
		--query RouteTable.RouteTableId \
		--output text >> $ResourceIds
	routeTableId=$(cat $ResourceIds | head -4 | tail +4)
}

# creates route to anywhere
function createRoute () {
	aws ec2 create-route \
		--route-table-id $routeTableId \
		--destination-cidr-block 0.0.0.0/0 \
		--gateway-id $internetGatewayId \
		--output text > /dev/null
}

# associates route table to subnet
function associateRouteTable () {
	aws ec2 associate-route-table \
		--subnet-id $subnetId \
		--route-table-id $routeTableId \
		--output text > /dev/null
}

# creates security group for SSH and HTTP
function createSecurityGroup () {
	aws ec2 create-security-group \
		--group-name SSH-HTTP-Access \
		--description "Security group for SSH and HTTP access" \
		--vpc-id $vpcId \
		--query GroupId \
		--output text >> $ResourceIds
	securityGroupId=$(cat $ResourceIds | head -5 | tail +5)
}

# allows ssh and http inbound from anywhere
function authorizeSecurityGroup () {
	aws ec2 authorize-security-group-ingress \
		--group-id $securityGroupId \
		--protocol tcp \
		--port 22 \
		--cidr 0.0.0.0/0 \
		--output text > /dev/null
	aws ec2 authorize-security-group-ingress \
		--group-id $securityGroupId \
		--protocol tcp \
		--port 80 \
		--cidr 0.0.0.0/0 \
		--output text > /dev/null
}

# creates ubuntu 20.04 lts instance
function createInstance () {
	aws ec2 run-instances \
		--image-id ami-02584c1c9d05efa69 \
		--count 1 \
		--instance-type t2.micro \
		--key-name "Jenkins Docker Pi" \
		--security-group-ids $securityGroupId \
		--subnet-id $subnetId \
		--associate-public-ip-address | grep InstanceId | cut -d '"' -f 4 >> $ResourceIds
	instanceId=$(cat $ResourceIds | head -6 | tail +6) 
	aws ec2 describe-instances \
        --instance-id $instanceId | grep "PublicIpAddress" | cut -d '"' -f 4 >> $ResourceIds
	instancePublicIp=$(cat $ResourceIds | head -7 | tail +7)
}

# prints ids of the resources
function showResourceIds () {
	echo "VPC ID -> $vpcId"
	echo "Subnet ID -> $subnetId"
	echo "Internet Gateway ID -> $internetGatewayId"
	echo "Route Table ID -> $routeTableId"
	echo "Security Group ID -> $securityGroupId"
	echo "Instance ID -> $instanceId"
	echo "Public IPv4 Address -> $instancePublicIp" 
}

if [[ $1 = "--create" ]]
then
	createVPC && \
	createSubnet && \
	createInternetGateway && attachInternetGatewayToVpc && \
	createRouteTable && createRoute && associateRouteTable && \
	createSecurityGroup && authorizeSecurityGroup && \
	createInstance && \
	showResourceIds
elif [[ $1 = "--purge" ]]
then
	vpcId=$(cat $ResourceIds | head -1)
	subnetId=$(cat $ResourceIds | head -2 | tail +2)
	internetGatewayId=$(cat $ResourceIds | head -3 | tail +3)
	routeTableId=$(cat $ResourceIds | head -4 | tail +4)
	securityGroupId=$(cat $ResourceIds | head -5 | tail +5)
	instanceId=$(cat $ResourceIds | head -6 | tail +6) 
	aws ec2 terminate-instances --instance-ids $instanceId --output text > /dev/null
	sleep 60
	aws ec2 delete-security-group --group-id $securityGroupId
	aws ec2 delete-subnet --subnet-id $subnetId
	aws ec2 delete-route-table --route-table-id $routeTableId
	aws ec2 detach-internet-gateway --internet-gateway-id $internetGatewayId --vpc-id $vpcId
	aws ec2 delete-internet-gateway --internet-gateway-id $internetGatewayId
	aws ec2 delete-vpc --vpc-id $vpcId
	rm $ResourceIds
else
	echo "You can use --create flag to create ec2 instance"
	echo "Or --purge flag to delete the ec2 and created vpc"
fi
