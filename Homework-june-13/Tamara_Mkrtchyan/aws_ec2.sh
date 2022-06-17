#!/bin/bash

# colored bash:)
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Reset='\033[0m'           # Text Reset

command=$1
name=$2

# this function is being called after every command to check for a return value
# if the return value is not success then it deletes previously created all resources
check_for_error () {
	return_value=$(echo $?)
	if [[ $return_value != 0 ]]; then
		echo -e "${Yellow}An error occured while $1, should delete everything now${Reset}"
		delete_all "error"
		exit 1
	fi
}

# fiunction to delete all created resources
delete_all () {
	if [[ $1 != "error" ]]; then
		vpcId=$(grep "vpc-" $name-ids)
		subnetId=$(grep "subnet-" $name-ids)
		igwId=$(grep "igw-" $name-ids)
		rtbId=$(grep "rtb-" $name-ids)
		sgId=$(grep "sg-" $name-ids)
		instanceId=$(grep "i-" $name-ids)
	fi

	if [[ ! -z $instanceId ]]; then
		echo -e "${Yellow}Terminating EC2 instance...\nThis might take some time...${Reset}"
		aws ec2 terminate-instances --instance-ids $instanceId --output text > /dev/null && \
		aws ec2 wait instance-terminated --instance-ids $instanceId && \
		echo -e "${Red}EC2 instance is terminated${Reset}"
	fi

	if [[ ! -z $name-keypair ]]; then
		aws ec2 delete-key-pair --key-name $name-keypair && \
		rm -f $name-keypair.pem
		echo -e "${Red}SSH Key Pair is deleted${Reset}"
	fi

	if [[ ! -z $sgid ]]; then
		aws ec2 delete-security-group --group-id $sgId && \
		echo -e "${Red}Security Group is deleted${Reset}"
	fi

	if [[ ! -z $subnetId ]]; then
		aws ec2 delete-subnet --subnet-id $subnetId && \
		echo -e "${Red}Subnet is deleted${Reset}"
	fi

	if [[ ! -z $rtbId ]]; then
		aws ec2 delete-route-table --route-table-id $rtbId && \
		echo -e "${Red}Route Table is deleted${Reset}"
	fi

	if [[ ! -z $igwId ]]; then
		aws ec2 detach-internet-gateway --internet-gateway-id $igwId --vpc-id $vpcId && \
		aws ec2 delete-internet-gateway --internet-gateway-id $igwId && \
		echo -e "${Red}Internet Gateway is deleted${Reset}"
	fi

	if [[ ! -z $vpcId ]]; then
		aws ec2 delete-vpc --vpc-id $vpcId && \
		echo -e "${Red}VPC is deleted${Reset}"
	fi

	rm -f $name-ids && \
	echo -e "${Red}Temporary files are deleted${Reset}"
	echo -e "${Green}----------------------------------${Reset}"
	echo -e "${Green}THANK YOU FOR USING OUR SERVICES:)${Reset}"
	echo -e "${Green}----------------------------------${Reset}"
}

create_ec2 () {
# Creating a VPC with a 10.0.0.0/16 CIDR block
	vpcId=$(aws ec2 create-vpc \
				--tag-specification 'ResourceType=vpc,Tags=[{Key=Name,Value='$name-vpc'}]' \
				--cidr-block 10.0.0.0/16 \
				--query Vpc.VpcId \
				--output text) && \
				echo -e "${Green}VPC is created successfully !${Reset}"
	check_for_error "creating VPC"

# Using the VPC ID to create a subnet with a 10.0.1.0/24 CIDR block
	aws ec2 create-subnet \
				--tag-specification 'ResourceType=subnet,Tags=[{Key=Name,Value='$name-subnet'}]' \
				--vpc-id $vpcId \
				--cidr-block 10.0.0.0/24 \
				--output text >/dev/null && \
				echo -e "${Green}Subnet is created successfully !${Reset}"
	check_for_error "creating Subnet"

# Creating an internet gateway
	subnetId=$(aws ec2 describe-subnets \
				--filters "Name=vpc-id,Values=${vpcId}" \
				--query "Subnets[*].SubnetId" \
				--output text)

# Using the Internet Gateway ID to attach it to our VPC
	igwId=$(aws ec2 create-internet-gateway \
				--tag-specification 'ResourceType=internet-gateway,Tags=[{Key=Name,Value='$name-igw'}]' \
				--query InternetGateway.InternetGatewayId \
				--output text) && \
				echo -e "${Green}Internet Gateway is created successfully !${Reset}"
	check_for_error "creating Internet Gateway"

# Attaching Internet Gateway to the VPC
	aws ec2 attach-internet-gateway \
				--vpc-id $vpcId \
				--internet-gateway-id $igwId && \
				echo -e "${Green}Internet Gateway is attached successfully !${Reset}"
	check_for_error "attaching Internet Gateway to the VPC"

# Creating a custom route table for our VPC
	rtbId=$(aws ec2 crete-route-table \
				--tag-specification 'ResourceType=route-table,Tags=[{Key=Name,Value='$name-rtb'}]' \
				--vpc-id ${vpcId} \
				--query RouteTable.RouteTableId \
				--output text) && \
				echo -e "${Green}Route Table is created successfully !${Reset}"
	check_for_error "creating a custom route table for our VPC"

# Creating a route in the route table that points all traffic (0.0.0.0/0) to the internet gateway and associating it
	aws ec2 create-route \
				--route-table-id $rtbId \
				--destination-cidr-block 0.0.0.0/0 \
				--gateway-id $igwId >/dev/null && \
				echo -e "${Green}Route to 0.0.0.0/0 is created successfully !${Reset}"
	check_for_error "creating a route in the route table that points all traffic (0.0.0.0/0) to the internet gateway"

	aws ec2 associate-route-table \
			--subnet-id $subnetId \
			--route-table-id $rtbId \
			--output text > /dev/null && \
				echo -e "${Green}Route Table associated successfully!${Reset}"
	check_for_error "associating teh route table"

# Creating a Securoty Group and authorizing shh and http ports from all ips
	sgId=$(aws ec2 create-security-group \
			--tag-specification 'ResourceType=security-group,Tags=[{Key=Name,Value='$name-sg'}]' \
			--group-name ssh-http \
			--description "giving access for ssh and http" \
			--vpc-id $vpcId \
			--query GroupId \
			--output text) && \
			echo -e "${Green}Security Group is created successfully !${Reset}"
	check_for_error "creating a Securoty Group"

	aws ec2 authorize-security-group-ingress \
			--group-id $sgId \
			--protocol tcp \
			--port 22 \
			--cidr 0.0.0.0/0 >/dev/null && \
			echo -e "${Green}22 port for SSH is authorized successfully !${Reset}"
	check_for_error "authorizing a 22 port"
	aws ec2 authorize-security-group-ingress \
			--group-id $sgId \
			--protocol tcp \
			--port 80 \
			--cidr 0.0.0.0/0 >/dev/null && \
			echo -e "${Green}80 port for HTTP is authorized successfully !${Reset}"
	check_for_error "authorizing a 80 port"

# Creating Key Pair for ssh
	aws ec2 create-key-pair \
			--key-name $name-keypair \
			--query "KeyMaterial" \
			--output text > $name-keypair.pem && \
			chmod 400 $name-keypair.pem && \
			echo -e "${Green}SSH keypair is created successfully !${Reset}"
	check_for_error "creating Key Pair"

# Running an instance with Ubuntu Server 20.04 LTS (HVM), SSD Volume Type (64-bit (x86))
	aws ec2 run-instances \
			--tag-specification 'ResourceType=instance,Tags=[{Key=Name,Value='$name-ec2'}]' \
			--image-id ami-08d4ac5b634553e16 \
			--count 1 \
			--instance-type t2.micro \
			--key-name $name-keypair \
			--security-group-ids $sgId \
			--subnet-id $subnetId \
			--associate-public-ip-address >/dev/null && \
			echo -e "${Green}EC2 Instance is created successfully !${Reset}"
	check_for_error "running an instance"

# Getting the instance ID
	instanceId=$(aws ec2 describe-instances \
			--filters "Name=subnet-id,Values=${subnetId}" \
			--query 'Reservations[*].Instances[*].{Instance:InstanceId}' \
			--output text)

# Getting the public IP
	publicIp=$(aws ec2 describe-instances \
			--instance-id $instanceId | \
			grep "PublicIpAddress" | \
			cut -d '"' -f 4)  && \
			echo -e "${Yellow}Your Public IP is ${publicIp}${Reset}"

	echo -e "${Blue}---------------------------------------------------${Reset}"
	echo -e "${Blue}VPC ID: ${vpcId}${Reset}"
	echo -e "${Blue}Subnet ID: ${subnetId}${Reset}"
	echo -e "${Blue}Internet Gateway ID: ${igwId}${Reset}"
	echo -e "${Blue}Route Table ID: ${rtbId}${Reset}"
	echo -e "${Blue}Security Group ID: ${sgId}${Reset}"
	echo -e "${Blue}Instance ID: ${instanceId}${Reset}"
	echo -e "${Blue}Public IPv4 Address: ${publicIp}${Reset}"
	echo -e "${Blue}---------------------------------------------------${Reset}"
	echo -e "$vpcId\n$subnetId\n$igwId\n$rtbId\n$sgId\n$instanceId\nip-$publicIp" > $name-ids
}

# the program starts here
if [[ $command = "--create" ]] && [[ ! -z $name ]]; then
	if [[ -f "$name-ids" ]]; then
		echo -e "${Red}${name} already exists${Reset}"
	else
		create_ec2
	fi
elif [[ $command = "--delete" ]] && [[ ! -z $name ]]; then
	if [[ -f "$name-ids" ]]; then
		delete_all
	else
		echo -e "${Red}There is no $name to delete${Reset}"
	fi
else
	echo -e "${Red}Argument Error. Must be${Reset}"
	echo -e "./aws_ec2.sh --create <name>"
	echo -e "./aws_ec2.sh --delete <name>"
fi