#!/bin/bash

set -e

# name of the project which will user run script with
projectName=$2

# VPC related variables
vpcName="$projectName-vpc"
vpcCIDRBlock="172.22.0.0/16"

# Subnet related variables
subnetName="$projectName-subnet"
subnetCIDRBlock="172.22.22.0/24"

# Internet Gateway related variables
internetGatewayName="$projectName-internet-gateway"

# Route Table related variables
routeTableName="$projectName-route-table"

# Security Group related variables
securityGroupName="$projectName-security-group"

# Instance related variables
instanceName="$projectName-instance"
instanceImageId="ami-02584c1c9d05efa69"
instanceType="t2.micro"
instanceCount="1"

# SSH Key Pair related variables
sshKeyName="$projectName-ec2-key"

# Resources file name
resourceIds="$projectName-resources.txt"


# creates vpc using $vpcName as the name and $vpcCIDRBlock as the cidr block and assigns the vpc id to $vpcId
function createVPC () {
	echo "Creating VPC ($vpcName) with ($vpcCIDRBlock) CIDR Block..."
	vpcId=$(aws ec2 create-vpc \
		--tag-specification 'ResourceType=vpc,Tags=[{Key=Name,Value='$vpcName'}]' \
		--cidr-block $vpcCIDRBlock \
		--query Vpc.VpcId \
		--output text) && \
	echo "Done."
}


# creates subnet using $subnetName as the name and $subnetCIDRBlock as the cidr block and assigns the subnet id to $subnetId
function createSubnet () {
	echo "Creating Subnet ($subnetName) with ($subnetCIDRBlock) CIDR Block..."
	subnetId=$(aws ec2 create-subnet \
		--tag-specification 'ResourceType=subnet,Tags=[{Key=Name,Value='$subnetName'}]' \
		--vpc-id $vpcId \
		--cidr-block $subnetCIDRBlock \
		--query Subnet.SubnetId \
		--output text) && \
	echo "Done."
}


# creates internet gateway using $internetGatewayName as the name and assigns the internet gateway id to $internetGatewayId
function createInternetGateway () {
	echo "Creating Internet Gateway ($internetGatewayName)..."
	internetGatewayId=$(aws ec2 create-internet-gateway \
		--tag-specification 'ResourceType=internet-gateway,Tags=[{Key=Name,Value='$internetGatewayName'}]' \
		--query InternetGateway.InternetGatewayId \
		--output text) && \
	echo "Done."
}


# attaches internet gateway to the vpc
function attachInternetGatewayToVpc () {
	echo "Attaching Internet Gateway ($internetGatewayName) to VPC ($vpcName)..."
	aws ec2 attach-internet-gateway \
		--vpc-id $vpcId \
		--internet-gateway-id $internetGatewayId \
		--output text > /dev/null && \
	echo "Done."
}


# creates route table using $routeTableName as the name in $vpcId vpc and assigns the route table id to $routeTableId
function createRouteTable () {
	echo "Creating Route Table ($routeTableName) in VPC ($vpcName)..."
	routeTableId=$(aws ec2 create-route-table \
		--tag-specification 'ResourceType=route-table,Tags=[{Key=Name,Value='$routeTableName'}]' \
		--vpc-id $vpcId \
		--query RouteTable.RouteTableId \
		--output text) && \
	echo "Done."
}


# creates route from $internetGatewayName to anywhere in $routeTableName
function createRoute () {
	echo "Creating Route from ($internetGatewayName) to (0.0.0.0/0)..."
	aws ec2 create-route \
		--route-table-id $routeTableId \
		--destination-cidr-block 0.0.0.0/0 \
		--gateway-id $internetGatewayId \
		--output text > /dev/null && \
	echo "Done."
}


# associates route table with subnet
function associateRouteTable () {
	echo "Associating Route Table ($routeTableName) with Subnet ($subnetName)..."
	aws ec2 associate-route-table \
		--subnet-id $subnetId \
		--route-table-id $routeTableId \
		--output text > /dev/null && \
	echo "Done."
}


# creates security group using $securityGroupName as the name in vpc $vpcId vpc
# and assigns the security group id to $securityGroupId
function createSecurityGroup () {
	echo "Creating Security Group ($securityGroupName) for SSH and HTTP access..."
	securityGroupId=$(aws ec2 create-security-group \
		--tag-specification 'ResourceType=security-group,Tags=[{Key=Name,Value='$securityGroupName'}]' \
    	--group-name SSH-HTTP-Access \
		--description "Security group for SSH and HTTP access" \
    	--vpc-id $vpcId \
		--query GroupId \
		--output text) && \
	echo "Done."
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
	echo "SSH access on port 22/tcp is authorized."
	aws ec2 authorize-security-group-ingress \
		--group-id $securityGroupId \
		--protocol tcp \
		--port 80 \
		--cidr 0.0.0.0/0 \
		--output text > /dev/null && \
	echo "HTTP access on port 80/tcp is authorized."
}


# generates ssh key pair
function generateKeyPair () {
	echo "Generating SSH Key Pair ($sshKeyName)..."
	aws ec2 create-key-pair \
		--key-name $sshKeyName \
		--query "KeyMaterial" \
		--output text > $sshKeyName.pem && \
	chmod 400 $sshKeyName.pem && \
	echo "Done."
}


# creates ubuntu 20.04 lts instance
function createInstance () {
	echo "Launching EC2 instance with the name ($instanceName) and type ($instanceType)..."
	instanceId=$(aws ec2 run-instances \
		--tag-specification 'ResourceType=instance,Tags=[{Key=Name,Value='$instanceName'}]' \
		--image-id $instanceImageId \
		--count $instanceCount \
		--instance-type $instanceType \
		--key-name $sshKeyName \
		--security-group-ids $securityGroupId \
		--subnet-id $subnetId \
		--associate-public-ip-address | grep "InstanceId" | cut -d '"' -f 4) && \
	sleep 2 && \
	instancePublicIp=$(aws ec2 describe-instances \
		--instance-id $instanceId | \
		grep "PublicIpAddress" | \
		cut -d '"' -f 4) && \
	echo "Done."
}


# deletes entire project step-by-step
function deleteProject () {
	vpcId=$(grep "vpc-" $resourceIds) && \
	subnetId=$(grep "subnet-" $resourceIds) && \
	internetGatewayId=$(grep "igw-" $resourceIds) && \
	routeTableId=$(grep "rtb-" $resourceIds) && \
	securityGroupId=$(grep "sg-" $resourceIds) && \
	instanceId=$(grep "i-" $resourceIds) && \

	echo "Terminating the EC2 instance ($instanceName)..." && \
	aws ec2 terminate-instances --instance-ids $instanceId --output text > /dev/null && \
	echo "Waiting for the termination of EC2 instance ($instanceName)..." && \
	aws ec2 wait instance-terminated --instance-ids $instanceId && \
	echo "Done." && \

	echo "Deleting the SSH Key Pair ($sshKeyName)..." && \
	aws ec2 delete-key-pair --key-name $sshKeyName && \
	echo "Done." && \

	echo "Deleting the Security Group ($securityGroupName)..." && \
	aws ec2 delete-security-group --group-id $securityGroupId && \
	echo "Done." && \

	echo "Deleting the Subnet ($subnetName)..." && \
	aws ec2 delete-subnet --subnet-id $subnetId && \
	echo "Done." && \

	echo "Deleting the Route Table ($routeTableName)..." && \
	aws ec2 delete-route-table --route-table-id $routeTableId && \
	echo "Done." && \

	echo "Detaching the Internet Gateway ($internetGatewayName) from the VPC ($vpcName)..." && \
	aws ec2 detach-internet-gateway --internet-gateway-id $internetGatewayId --vpc-id $vpcId && \
	echo "Done." && \

	echo "Deleting the Internet Gateway ($internetGatewayName)..." && \
	aws ec2 delete-internet-gateway --internet-gateway-id $internetGatewayId && \
	echo "Done." && \

	echo "Deleting the VPC ($vpcName)..." && \
	aws ec2 delete-vpc --vpc-id $vpcId && \
	echo "Done." && \

	echo "Deleting ($sshKeyName.pem) and ($resourceIds)" && \
	rm -f $sshKeyName.pem && \
	rm -f $resourceIds && \
	echo "Done."
}


# prints ids of the resources
function showResourceIds () {
	echo " "
	echo "VPC ID -> $vpcId"
	echo "Subnet ID -> $subnetId"
	echo "Internet Gateway ID -> $internetGatewayId"
	echo "Route Table ID -> $routeTableId"
	echo "Security Group ID -> $securityGroupId"
	echo "Instance ID -> $instanceId"
	echo "Public IPv4 Address -> $instancePublicIp" 
	echo " "
	echo -e "$vpcId\n$subnetId\n$internetGatewayId\n$routeTableId\n$securityGroupId\n$instanceId\nip-$instancePublicIp" > $resourceIds
}


# just echos for --help
function showHelpMenu() {
	echo " "
	echo "This script allows to automatically create VPC, Subnet, Internet Gateway, Route Table, Security Group and EC2 Instance"
	echo "in Amazon Web Services as well as delete them and see the created resources."
	echo " "
	echo "You need to specify project name which will name the created resources"
	echo ""
	echo "Format will be [sciprt name] [option] [project name]"
	echo " "
	echo "	--create -> creates a project"
	echo " "
	echo "	--delete -> deletes the project"
	echo " "
	echo "	--show-resources -> shows the resources of specified project"
	echo " "
}


if [[ $1 = "--create" ]] && [[ ! -z $projectName ]]
then
	if [[ ! -f "$resourceIds" ]]
	then
		createVPC && \
		createSubnet && \
		createInternetGateway && attachInternetGatewayToVpc && \
		createRouteTable && createRoute && associateRouteTable && \
		createSecurityGroup && authorizeSecurityGroup && \
		generateKeyPair && \
		createInstance && \
		showResourceIds
	else
		echo " "
		echo "There is already project named $projectName, if you want to recreate first you need to delete it"
		echo "See --help for more information"
		echo " "
	fi
elif [[ $1 = "--delete" ]] && [[ ! -z $projectName ]]
then
	if [[ -f "$resourceIds" ]]
	then
		deleteProject
	else
		echo " "
		echo "There is no any project named $projectName to delete"
		echo "If you want to create one see --help for more information"
		echo " "
	fi
elif [[ $1 = "--show-resources" ]] && [[ ! -z $projectName ]]
then
	if [[ -f "$resourceIds" ]]
	then
		vpcId=$(grep "vpc-" $resourceIds)
		subnetId=$(grep "subnet-" $resourceIds)
		internetGatewayId=$(grep "igw-" $resourceIds)
		routeTableId=$(grep "rtb-" $resourceIds)
		securityGroupId=$(grep "sg-" $resourceIds)
		instanceId=$(grep "i-" $resourceIds)
		instancePublicIp=$(grep "ip-" $resourceIds | cut -d "-" -f 2)
		showResourceIds
	else
		echo " "
		echo "There is no any resources named $projectName"
		echo "If you want to create them see --help for more information"
		echo " "
	fi
elif [[ $1 = "--help" ]]
then
	showHelpMenu
else
	echo " "
	echo "You need to specify an option and project name to continue"
	echo "See --help for more information"
	echo " "
fi