#!/bin/bash

#Create aws instance


#   1.Create vpc with cidr block 10.0.0.0//16
#   2.Create a public subnet
#   3.Create an Internet Gateway
#   4.Attach Internet gateway to your VPC
#   5.Create a route table
#   6.Create route to Internet Gateway
#   7.Associate the public subnet with route table
#   8.Open the SSH port(22)
#   9.Generate Key Pair
#   10.create ec2 instance
#   11.run all  functions
#   12.delete all functions

echo "start..."

# Create vpc with cidr block 10.0.0.0//16
function createVpc() { 
    set -e

   	 new_aws_id_vps=$(aws ec2 create-vpc \
   	 --cidr-block 10.0.0.0/16 \
   	 --query 'Vpc.{VpcId:VpcId}' \
    	 --output text)

    if [[ $? -ne 0 ]]; then
		cleanUp
        	echo "VPC is clened"
		else 
    	        echo "Creating Vpc..."
    fi
}

# Using the VPC ID to create a subnet with a 10.0.1.0/24 CIDR block
function createSubnet() { 
   set -e
  
   
   	 new_aws_subnet_pub_id=$(aws ec2 create-subnet \
   	 --vpc-id $new_aws_id_vps --cidr-block 10.0.1.0/24 \
   	 --availability-zone us-east-1f --query 'Subnet.{SubnetId:SubnetId}' \
   	 --output text)
    		echo "Subnet is created"
   	 if [[ $? -ne 0 ]]; then
			cleanUp
			echo "Subnet is created"
		else 
      	                echo "Creating subnet..."
		fi
}

# Create an Internet Gateway
function createInternetGateway() { 
    set -e

   	 new_aws_ec2_getway=$(aws ec2 create-internet-gateway \
         --query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
    	 --output text)

    if [[ $? -ne 0 ]]; then
			cleanUp
			echo "Getway deleted!"
		else 
        		echo "Creating Internet Gateway..."
	fi
}

# Attach Internet gateway to your VPC
function attachGiveaway() { 
    set -e

    
     	aws ec2 attach-internet-gateway \
    	--vpc-id $new_aws_id_vpc \
        --internet-gateway-id $new_aws_ec2_getway
        echo"getway attached!"
}

# Creating a custom route table for our VPC

function createRouteTable() { 
    set -e

   	 new_route_table=$(aws ec2 create-route-table \
   	 --vpc-id $new_aws_id_vpc \
   	 --query 'RouteTable.{RouteTableId:RouteTableId}' \
   	 --output text )

    if [[ $? -ne 0 ]]; then
		cleanUp
			echo "route table deleted! "
		else 
       			 echo "Creating Internet Route Table..."
	fi
}



# Creating a route in the route table that points all traffic (0.0.0.0/0) to the internet gateway and associating it
function createRouteGtw() { 
    set -e

    aws ec2 create-route \
    --route-table-id $new_aws_ec2_getway \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $new_aws_ec2_getway 
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
    new_aws_assoc_route_table=$(aws ec2 associate-route-table  \
    --subnet-id $new_aws_subnet_pub_id \
    --route-table-id $new_aws_assoc_route_table \
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
    new_aws_security_group=$(aws ec2 create-security-group \
    --tag-specification 'ResourceType=security-group,Tags=[{Key=Name,Value='securityGroup'}]' \
    --group-name SSH-HTTP-Access \
    --description "Security group" \
    --vpc-id $aws_id_vpc \
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
    --group-id $new_aws_security_group \
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

    new_key_pair=$(aws ec2 create-key-pair \
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
    new_aws_instance=$(aws ec2 run-instances \
        --tag-specification 'ResourceType=instance,Tags=[{Key=Name,Value='ec2'}]' \
        --image-id ami-08d4ac5b634553e16 \
        --count 1 \
        --instance-type t2.micro \
        --key-name EC2Key \
        --security-group-ids $AWS_SECURITY_GROUP \
        --subnet-id $aws_subnet_pub_id \
        --associate-public-ip-address >/dev/null )
    
        if [[ $? -ne 0 ]]; then
            cleanUp
        else 
            echo "create instance..."
        fi
        
}


function creating_intstance () {
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

creating_instance


##Delete custom security group
##Delete internet gateway
##DELETE THE custom route table
##Delete the public subnet
##Delete the vpc

function cleanUp () {
    
    aws ec2 delete-security-group \
    --group-id $new_aws_security_group
    
    aws ec2 detach-internet-gateway \
    --internet-gateway-id $new_aws_ec2_getway \
    --vpc-id $aws_id_vps &&
    aws ec2 delete-internet-gateway \
    --internet-gateway-id $new_aws_ec2_getway
    
    aws ec2 disassociate-route-table \
	    --association-id $new_aws_security_group &&
    aws ec2 delete-route-table \
    --route-table-id $new_aws_route_table
    
    aws ec2 delete-subnet \
    --subnet-id $aws_subnet_public_id
    
    aws ec2 delete-vpc \
}

