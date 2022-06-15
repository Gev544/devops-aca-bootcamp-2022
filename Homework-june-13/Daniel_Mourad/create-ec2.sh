#!/bin/bash

set -e

ResourceIds="available_resource_ids.txt"
vpcId=
subnetId=
internetGatewayId=
routeTableId=
securityGroupId=
sshKeyName="ec2-key"
sshKey="ec2-key.pem"
instanceId=
instancePublicIp=

# creates vpc with 172.22.0.0/16 cidr block and sends vpc id to ResourceIds file
function createVPC () {
	echo "Creating VPC with 172.22.0.0/16 CIDR Block..."
	aws ec2 create-vpc \
		--cidr-block 172.22.0.0/16 \
		--query Vpc.VpcId \
		--output text > $ResourceIds && \
	echo "VPC is created"
	vpcId=$(cat $ResourceIds | head -1)
}

# creates subnet with 172.22.22.0/24 cidr block and sends subnet id to ResourceIds file
function createSubnet () {
	echo "Creating Subnet with 172.22.22.0/24 CIDR Block..."
	aws ec2 create-subnet \
		--vpc-id $vpcId \
		--cidr-block 172.22.22.0/24 \
		--query Subnet.SubnetId \
		--output text >> $ResourceIds && \
	echo "Subnet is created"
	subnetId=$(cat $ResourceIds | head -2 | tail +2)
}

# creates internet gateway and sends the id to ResourceIds file
function createInternetGateway () {
	echo "Creating Internet Gateway..."
	aws ec2 create-internet-gateway \
		--query InternetGateway.InternetGatewayId \
		--output text >> $ResourceIds && \
	echo "Internet Gateway created"
	internetGatewayId=$(cat $ResourceIds | head -3 | tail +3)
}

# attaches internet gateway to the vpc
function attachInternetGatewayToVpc () {
	echo "Attaching Internet Gateway to VPC..."
	aws ec2 attach-internet-gateway \
		--vpc-id $vpcId \
		--internet-gateway-id $internetGatewayId \
		--output text > /dev/null && \
	echo "Internet Gateway is successfully attached to VPC"
}

# creates route table and sends the id to ResourceIds file
function createRouteTable () {
	echo "Creating Route Table..."
	aws ec2 create-route-table \
		--vpc-id $vpcId \
		--query RouteTable.RouteTableId \
		--output text >> $ResourceIds && \
	echo "Route Table is created"
	routeTableId=$(cat $ResourceIds | head -4 | tail +4)
}

# creates route to anywhere
function createRoute () {
	echo "Creating Route to 0.0.0.0/0..."
	aws ec2 create-route \
		--route-table-id $routeTableId \
		--destination-cidr-block 0.0.0.0/0 \
		--gateway-id $internetGatewayId \
		--output text > /dev/null && \
	echo "Route is created"
}

# associates route table with subnet
function associateRouteTable () {
	echo "Associating Route Table with Subnet"
	aws ec2 associate-route-table \
		--subnet-id $subnetId \
		--route-table-id $routeTableId \
		--output text > /dev/null && \
	echo "Route Table is associated"
}

# creates security group for SSH and HTTP
function createSecurityGroup () {
	echo "Creating Security Group for SSH and HTTP access..."
	aws ec2 create-security-group \
		--group-name SSH-HTTP-Access \
		--description "Security group for SSH and HTTP access" \
		--vpc-id $vpcId \
		--query GroupId \
		--output text >> $ResourceIds && \
	echo "Security Group is created"
	securityGroupId=$(cat $ResourceIds | head -5 | tail +5)
}

# allows ssh and http inbound from anywhere
function authorizeSecurityGroup () {
	echo "Authorizing SSH and HTTP access from anywhere..."
	aws ec2 authorize-security-group-ingress \
		--group-id $securityGroupId \
		--protocol tcp \
		--port 22 \
		--cidr 0.0.0.0/0 \
		--output text > /dev/null && \
	echo "SSH access is authorized"
	aws ec2 authorize-security-group-ingress \
		--group-id $securityGroupId \
		--protocol tcp \
		--port 80 \
		--cidr 0.0.0.0/0 \
		--output text > /dev/null && \
	echo "HTTP access is authorized"
}

function generateKeyPair () {
	echo "Generating SSH Key Pair..."
	aws ec2 create-key-pair \
		--key-name $sshKeyName \
		--query "KeyMaterial" \
		--output text > $sshKey && \
	chmod 400 $sshKey && \
	echo "SSH Key Pair is generated"
}

# creates ubuntu 20.04 lts instance
function createInstance () {
	echo "Creating EC2 t2.micro instance..."
	aws ec2 run-instances \
		--image-id ami-02584c1c9d05efa69 \
		--count 1 \
		--instance-type t2.micro \
		--key-name $sshKeyName \
		--security-group-ids $securityGroupId \
		--subnet-id $subnetId \
		--associate-public-ip-address | grep InstanceId | cut -d '"' -f 4 >> $ResourceIds && \
	echo "Instance is successfully created"
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
	generateKeyPair && \
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
	echo "Terminating the EC2 Instance"
	aws ec2 terminate-instances --instance-ids $instanceId --output text > /dev/null
	echo "Waiting for the termination of EC2..."
	sleep 40
	echo "Deleting the SSH Key Pair ..."
	aws ec2 delete-key-pair --key-name $sshKeyName && rm -f $sshKey
	echo "Deleting the Security Group $securityGroupId ..."
	aws ec2 delete-security-group --group-id $securityGroupId
	echo "Deleting the Subnet $subnetId ..."
	aws ec2 delete-subnet --subnet-id $subnetId
	echo "Deleting the Route Table $routeTableId ..."
	aws ec2 delete-route-table --route-table-id $routeTableId
	echo "Detaching the Internet Gateway $internetGatewayId from the VPC $vpcId ..."
	aws ec2 detach-internet-gateway --internet-gateway-id $internetGatewayId --vpc-id $vpcId
	echo "Deleting the Internet Gateway $internetGatewayId ..."
	aws ec2 delete-internet-gateway --internet-gateway-id $internetGatewayId
	echo "Deleting the VPC $vpcId ..."
	aws ec2 delete-vpc --vpc-id $vpcId
	rm $ResourceIds
elif [[ $1 = "--show-resources" ]]
then
	if [[ -f "$ResourceIds" ]]
	then
		vpcId=$(cat $ResourceIds | head -1)
		subnetId=$(cat $ResourceIds | head -2 | tail +2)
		internetGatewayId=$(cat $ResourceIds | head -3 | tail +3)
		routeTableId=$(cat $ResourceIds | head -4 | tail +4)
		securityGroupId=$(cat $ResourceIds | head -5 | tail +5)
		instanceId=$(cat $ResourceIds | head -6 | tail +6)
		instancePublicIp=$(cat $ResourceIds | head -7 | tail +7)
		showResourceIds
	else
		echo "You do not have any resources"
	fi
elif [[ $1 = "--help" ]]
then
	echo "--create ->  creates VPC, Subnet, Internet Gateway, Route Table, Security Group and EC2 Instance"
	echo "--purge -> deletes all the created resources"
	echo "--show-resources -> shows all the available resources"
else
	echo "You need to specify an option to continue"
	echo "See --help for more information about options"
fi
