#!/bin/bash

# This script will create the VPC, Subnet, Internet Gateway, Route Table, Security Group and EC2 Instance

# Name of the project which will user run script with
projectName=$2
region="eu-central-1"

# VPC related variables
vpcName="${projectName}-vpc"
vpcCidrBlock="172.22.0.0/16"

# Subnet A related variables
subnetAName="${projectName}-subnet-a"
subnetACidrBlock="172.22.21.0/24"
subnetAAvailabilityZone="${region}a"

# Subnet B related variables
subnetBName="${projectName}-subnet-b"
subnetBCidrBlock="172.22.22.0/24"
subnetBAvailabilityZone="${region}b"

# Internet Gateway related variables
internetGatewayName="${projectName}-internet-gateway"

# Route Table related variables
routeTableName="${projectName}-route-table"

# Security Group related variables
securityGroupName="${projectName}-security-group"

# SSH Key Pair related variables
sshKeyName="${projectName}-ec2-key"

# Instance related variables
instanceName="${projectName}-instance"
instanceImageId="ami-02584c1c9d05efa69"
instanceType="t2.micro"
instanceCount="2"

# Target Group related variables
targetGroupName="${projectName}-target-group"

# Load Balancer related variables
loadBalancerName="${projectName}-load-balancer"
certificateArn=$(cat certificatearn.txt)

# Resources file name
resources="${projectName}-resources.txt"



# Creates VPC with specified name and CIDR block and assigns the ID to $vpcId
function createVpc () {
	echo "Creating VPC ($vpcName) with ($vpcCidrBlock) CIDR block..."
	vpcId=$(aws ec2 create-vpc \
		--tag-specification 'ResourceType=vpc,Tags=[{Key=Name,Value='$vpcName'}]' \
		--cidr-block $vpcCidrBlock \
		--query Vpc.VpcId \
		--output text | tee -a $resources)
}

# Deletes VPC
function deleteVpc () {
    vpcId=$(grep "vpc-" $resources)
    echo "Deleting VPC ($vpcName)..."
	aws ec2 delete-vpc --vpc-id $vpcId
}


# Creates Subnets with specified names and CIDR blocks and assigns the IDs to variables
function createSubnets () {
	echo "Creating Subnet ($subnetAName) in ($subnetAAvailabilityZone) with ($subnetACidrBlock) CIDR block..."
	subnetAId=$(aws ec2 create-subnet \
		--tag-specification 'ResourceType=subnet,Tags=[{Key=Name,Value='$subnetAName'}]' \
		--vpc-id $vpcId \
		--cidr-block $subnetACidrBlock \
		--availability-zone $subnetAAvailabilityZone \
		--query Subnet.SubnetId \
		--output text | tee -a $resources) && \
	echo "Creating Subnet ($subnetBName) in ($subnetBAvailabilityZone) with ($subnetBCidrBlock) CIDR block..." && \
	subnetBId=$(aws ec2 create-subnet \
		--tag-specification 'ResourceType=subnet,Tags=[{Key=Name,Value='$subnetBName'}]' \
		--vpc-id $vpcId \
		--cidr-block $subnetBCidrBlock \
		--availability-zone $subnetBAvailabilityZone \
		--query Subnet.SubnetId \
		--output text | tee -a $resources)
}

# Deletes Subnet
function deleteSubnets () {
    subnetAId=$(grep "subnet-" $resources | head -1)
	subnetBId=$(grep "subnet-" $resources | tail -1)
    echo "Deleting Subnets ($subnetAName) and ($subnetBName)..."
	aws ec2 delete-subnet --subnet-id $subnetAId
	aws ec2 delete-subnet --subnet-id $subnetBId
}


# Creates Internet Gateway with specified name and assigns the ID to $InternetGatewayId
function createInternetGateway () {
	echo "Creating Internet Gateway ($internetGatewayName)..."
	internetGatewayId=$(aws ec2 create-internet-gateway \
		--tag-specification 'ResourceType=internet-gateway,Tags=[{Key=Name,Value='$internetGatewayName'}]' \
		--query InternetGateway.InternetGatewayId \
		--output text | tee -a $resources)
}

# Attaches Internet Gateway to VPC
function attachInternetGatewayToVpc () {
	echo "Attaching Internet Gateway ($internetGatewayName) to VPC ($vpcName)..."
	aws ec2 attach-internet-gateway \
		--vpc-id $vpcId \
		--internet-gateway-id $internetGatewayId \
		--output text > /dev/null
}

# Detach Internet Gateway from VPC
function detachInternetGatewayFromVpc () {
    internetGatewayId=$(grep "igw-" $resources)
    vpcId=$(grep "vpc-" $resources)
    echo "Detaching Internet Gateway ($internetGatewayName) from VPC ($vpcName)..."
	aws ec2 detach-internet-gateway \
        --internet-gateway-id $internetGatewayId \
        --vpc-id $vpcId
}

# Deletes Internet Gateway
function deleteInternetGateway () {
    internetGatewayId=$(grep "igw-" $resources)
	echo "Deleting Internet Gateway ($internetGatewayName)..."
	aws ec2 delete-internet-gateway --internet-gateway-id $internetGatewayId
}


# Creates Route Table with specified name and VPC and assigns the ID to $routeTableId
function createRouteTable () {
	echo "Creating Route Table ($routeTableName) in VPC ($vpcName)..."
	routeTableId=$(aws ec2 create-route-table \
		--tag-specification 'ResourceType=route-table,Tags=[{Key=Name,Value='$routeTableName'}]' \
		--vpc-id $vpcId \
		--query RouteTable.RouteTableId \
		--output text | tee -a $resources)
}

# Creates Route from Internet Gateway to anywhere
function createRoute () {
	echo "Creating Route from ($internetGatewayName) to (0.0.0.0/0)..."
	aws ec2 create-route \
		--route-table-id $routeTableId \
		--destination-cidr-block 0.0.0.0/0 \
		--gateway-id $internetGatewayId \
		--output text > /dev/null
}

# Associates Route Table with Subnets
function associateRouteTable () {
	echo "Associating Route Table ($routeTableName) with Subnet ($subnetAName)..."
	aws ec2 associate-route-table \
		--subnet-id $subnetAId \
		--route-table-id $routeTableId \
		--output text > /dev/null && \
	echo "Associating Route Table ($routeTableName) with Subnet ($subnetBName)..." && \
	aws ec2 associate-route-table \
		--subnet-id $subnetBId \
		--route-table-id $routeTableId \
		--output text > /dev/null
}

# Deletes Route Table
function deleteRouteTable () {
    routeTableId=$(grep "rtb-" $resources)
    echo "Deleting Route Table ($routeTableName)..."
	aws ec2 delete-route-table --route-table-id $routeTableId
}


# Creates Security Group with specified name in VPC and assigns the ID to $securityGroupId
function createSecurityGroup () {
	echo "Creating Security Group ($securityGroupName) in VPC ($vpcName)..."
	securityGroupId=$(aws ec2 create-security-group \
		--tag-specification 'ResourceType=security-group,Tags=[{Key=Name,Value='$securityGroupName'}]' \
    	--group-name SSH-HTTP-HTTPS-Access \
		--description "Security group for SSH, HTTP and HTTPS access" \
    	--vpc-id $vpcId \
		--query GroupId \
		--output text | tee -a $resources)
}

# Allows SSH, HTTP and HTTPS access from anywhere
function authorizeSecurityGroup () {
	echo "Authorizing SSH (22/tcp) access from anywhere..."
	aws ec2 authorize-security-group-ingress \
		--group-id $securityGroupId \
		--protocol tcp \
		--port 22 \
		--cidr 0.0.0.0/0 \
		--output text > /dev/null && \
    echo "Authorizing HTTP (80/tcp) access from anywhere..." && \
	aws ec2 authorize-security-group-ingress \
		--group-id $securityGroupId \
		--protocol tcp \
		--port 80 \
		--cidr 0.0.0.0/0 \
		--output text > /dev/null && \
    echo "Authorizing HTTPS (443/tcp) access from anywhere..." && \
	aws ec2 authorize-security-group-ingress \
		--group-id $securityGroupId \
		--protocol tcp \
		--port 443 \
		--cidr 0.0.0.0/0 \
		--output text > /dev/null
}

# Deletes Security Group
function deleteSecurityGroup () {
    securityGroupId=$(grep "sg-" $resources)
	echo "Deleting Security Group ($securityGroupName)..."
	aws ec2 delete-security-group --group-id $securityGroupId
}


# Generates SSH Key Pair with the specified name and makes it only readable by user
function generateKeyPair () {
	echo "Generating SSH Keys ($sshKeyName)..."
	aws ec2 create-key-pair \
		--key-name $sshKeyName \
		--query "KeyMaterial" \
		--output text > $sshKeyName.pem && \
	chmod 400 $sshKeyName.pem
}

# Deletes SSH Keys
function deleteKeyPair () {
    echo "Deleting SSH Keys ($sshKeyName)..."
	aws ec2 delete-key-pair --key-name $sshKeyName
    rm -f ${sshKeyName}.pem
}


# Creates EC2 Instance using variables as arguments and assigns the ID to $instanceId and IP to $instancePublicIp
function createInstances () {
	echo "Launching ($instanceType) EC2 Instances ($instanceName)..."
	instanceId=$(aws ec2 run-instances \
		--tag-specification 'ResourceType=instance,Tags=[{Key=Name,Value='$instanceName'}]' \
		--image-id $instanceImageId \
		--count $instanceCount \
		--instance-type $instanceType \
		--key-name $sshKeyName \
		--security-group-ids $securityGroupId \
		--subnet-id $subnetAId \
		--associate-public-ip-address | grep "InstanceId" | cut -d '"' -f 4 | tee -a $resources) && \
    echo "Waiting until status is OK..." && \
	aws ec2 wait instance-status-ok --instance-ids $instanceId && \
	instancePublicIp=$(aws ec2 describe-instances \
        --instance-id $instanceId | grep "PublicIpAddress" | cut -d '"' -f 4)
    echo "ip-${instancePublicIp}" >> $resources
}

# Deletes EC2 Instance and waits until it is terminated
function terminateInstances () {
    instanceId=$(grep "i-" $resources)
    echo "Terminating EC2 instances ($instanceName)..."
	aws ec2 terminate-instances --instance-ids $instanceId --output text > /dev/null
	echo "Waiting for the termination of EC2 instance ($instanceName)..."
	aws ec2 wait instance-terminated --instance-ids $instanceId
}


# Creates Target Group and registers Instances
function createTargetGroup () {
	echo "Creating Target Group ($targetGroupName) and registering targets..."
	targetGroupArn=$(aws elbv2 create-target-group \
		--name $targetGroupName \
		--protocol HTTP \
		--port 80 \
		--target-type instance \
		--vpc-id $vpcId |
 		grep "TargetGroupArn" | cut -d '"' -f 4 | tee -a $resources) && \
	aws elbv2 register-targets \
		--target-group-arn $targetGroupArn \
		--targets \
		Id=$(grep "i-" aca-homework-resources.txt | head -1),Port=80 \
		Id=$(grep "i-" aca-homework-resources.txt | tail -1),Port=80
}

# Deletes Target Group
function deleteTargetGroup () {
	targetGroupArn=$(grep "targetgroup" $resources)
	echo "Deleting Target Group ($targetGroupName)..."
	aws elbv2 delete-target-group --target-group-arn $targetGroupArn
}


# Creates Load Balancer
function createLoadBalancer () {
	echo "Creating Application Load Balancer ($loadBalancerName)..."
	loadBalancerArn=$(aws elbv2 create-load-balancer \
		--name $loadBalancerName \
		--subnets $subnetAId $subnetBId \
		--security-groups $securityGroupId |
 		grep "LoadBalancerArn" | cut -d '"' -f 4 | tee -a $resources) && \
	aws elbv2 create-listener \
		--load-balancer-arn $loadBalancerArn \
		--protocol HTTPS --port 443  \
		--certificates CertificateArn=$certificateArn \
		--default-actions Type=forward,TargetGroupArn=${targetGroupArn} > /dev/null && \
	aws elbv2 create-listener \
		--load-balancer-arn $loadBalancerArn \
		--protocol HTTP --port 80  \
		--default-actions '[{"Type": "redirect", "RedirectConfig": {"Protocol": "HTTPS", "Port": "443", "Host": "#{host}", "Query": "#{query}", "Path": "/#{path}", "StatusCode": "HTTP_301"}}]' > /dev/null
}

# Deletes Load Balancer
function deleteLoadBalancer () {
	loadBalancerArn=$(grep "loadbalancer" $resources)
	echo "Deleting Application Load Balancer ($loadBalancerName)..."
	aws elbv2 delete-load-balancer --load-balancer-arn $loadBalancerArn
}


# Shows available resources of the project
function showResources () {
	echo " "
	echo "VPC ID -> $(grep "vpc-" $resources)"
	echo "Subnet A ID -> $(grep "subnet-" $resources | head -1)"
	echo "Subnet B ID -> $(grep "subnet-" $resources | tail -1)"
	echo "Internet Gateway ID -> $(grep "igw-" $resources)"
	echo "Route Table ID -> $(grep "rtb-" $resources)"
	echo "Security Group ID -> $(grep "sg-" $resources)"
	echo "Instance A ID -> $(grep "i-" $resources | head -1)"
	echo "Instance B ID -> $(grep "i-" $resources | tail -1)"
	echo "Instance A Public IPv4 Address -> $(grep "ip-" $resources | cut -d "-" -f 2)"
	echo "Instance B Public IPv4 Address -> $(grep -A 1 "ip-" $resources | tail -1)"
	echo "Target Group ARN -> $(grep "targetgroup" $resources)"
	echo "Load Balancer ARN -> $(grep "loadbalancer" $resources)"
	echo " "
}


# Cleans up if something goes wrong
function cleanUp () {
	echo "Something went wrong, cleaning up..."
	deleteLoadBalancer
	deleteTargetGroup
    terminateInstances
    deleteKeyPair
    deleteSecurityGroup
    deleteSubnets
    deleteRouteTable
    detachInternetGatewayFromVpc
    deleteInternetGateway
    deleteVpc
    rm -f $resources
	echo "Cleanup done."
	exit 1
}


if [[ $1 = "--create" ]] && [[ ! -z $projectName ]]; then
	if [[ ! -f "$resources" ]]; then
		createVpc && \
		createSubnets && \
		createInternetGateway && \
    	attachInternetGatewayToVpc && \
		createRouteTable && \
		createRoute && \
		associateRouteTable && \
		createSecurityGroup && \
		authorizeSecurityGroup && \
		generateKeyPair && \
    	createInstances && \
		createTargetGroup && \
		createLoadBalancer && \
		showResources
		if [[ $? != 0 ]]; then
			cleanUp
		else
			echo "Done."
		fi
	else
		echo " "
		echo "There is already project named $projectName, if you want to recreate first you need to delete it"
		echo "See --help for more information"
		echo " "
	fi
elif [[ $1 = "--delete" ]] && [[ ! -z $projectName ]]; then
	if [[ -f "$resources" ]]; then
		deleteLoadBalancer && \
		sleep 30 && \
		deleteTargetGroup && \
		terminateInstances && \
    	deleteKeyPair && \
    	deleteSecurityGroup && \
    	deleteSubnets && \
    	deleteRouteTable && \
    	detachInternetGatewayFromVpc && \
   		deleteInternetGateway && \
    	deleteVpc && \
    	rm -f $resources
		if [[ $? != 0 ]]; then
			cleanUp
		else
			echo "Done."
		fi
	else
		echo " "
		echo "There is no any project named $projectName to delete"
		echo "If you want to create one see --help for more information"
		echo " "
	fi
elif [[ $1 = "--show-resources" ]] && [[ ! -z $projectName ]]; then
	if [[ -f "$resources" ]]; then
		showResources
	else
		echo " "
		echo "There is no any resources named $projectName"
		echo "If you want to create them see --help for more information"
		echo " "
	fi
elif [[ $1 = "--help" ]]; then
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
else
	echo " "
	echo "You need to specify an option and project name to continue"
	echo "See --help for more information"
	echo " "
fi