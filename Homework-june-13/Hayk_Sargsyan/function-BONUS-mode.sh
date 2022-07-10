#!/bin/bash

set -e

#Delete keys if we want to run script 2nd time
delete-keys () {
	aws ec2 delete-key-pair \
       --key-name fun-aws-homework-key
	echo "aws-key is deleted"
	if [[ -f fun-aws-homework-key.pem ]]
	then
	rm -f fun-aws-homework-key.pem
	echo "Local key .pem is deleted"
	fi
}

#Create a VPC with a 10.0.0.0/16 CIDR block

vpc () {
	vpcID=$(aws ec2 create-vpc \
       --cidr-block 10.0.0.0/16 \
       --query Vpc.VpcId --output text)
	if [[ -z $vpcID ]]
	then
		echo "Cant create VPC"
			exit 1
	else
		echo "new VPC ID is : $vpcID"
	fi
	}

#Create a first subnet with a 10.0.1.0/24 CIDR block

subnet1 () {
	subnet1_ID=$(aws ec2 create-subnet \
	--vpc-id $vpcID \
	--cidr-block 10.0.1.0/24 \
	--query Subnet.SubnetId --output text)
	if [[ -z $subnet1_ID ]]
        then
                echo "Cant create Subnet1"
		aws ec2 delete-vpc \
			--vpc-id $vpcID
                        exit 1
        else
		echo "new Subnet ID is : $subnet1_ID"
        fi
	}

#Create a second subnet with a 10.0.2.0/24 CIDR block

subnet2 () {
	subnet2_ID=$(aws ec2 create-subnet \
	--vpc-id $vpcID \
	--cidr-block 10.0.2.0/24 \
	--query Subnet.SubnetId --output text)
	if [[ -z $subnet2_ID ]]
        then
                echo  "Cant create Subnet2"
                aws ec2 delete-vpc \
                        --vpc-id $vpcID
                        exit 1
        else
                echo "new Subnet ID is : $subnet2_ID"
        fi
	}

#Create an internet gateway

gateway () {
	igwID=$(aws ec2 create-internet-gateway \
	--query InternetGateway.InternetGatewayId --output text)
	if [[ -z $igwID ]]
	then
		echo "Cant create Internet Gateway"
		aws ec2 delete-subnet \
			--subnet-id $subnet1_ID
		aws ec2 delete-subnet \
                        --subnet-id $subnet2_ID
		aws ec2 delete-vpc \
			--vpc-id $vpcID	
			exit 1
	else
		echo "Internet Gateway ID is : $igwID"
	fi
	}

#Attach the internet gateway to  VPC 

attach-gateway () {
	aws ec2 attach-internet-gateway \
	--vpc-id $vpcID \
	--internet-gateway-id $igwID
	if [[ $? = 0 ]]
	then 
		echo "Attach the internet gateway to VPC"
	else 
		echo "Cant attach IGW to VPC"
		aws ec2 delete-internet-gateway \
                        --internet-gateway-id $igwID
                aws ec2 delete-subnet \
                        --subnet-id $subnet1_ID
                aws ec2 delete-subnet \
                        --subnet-id $subnet2_ID
                aws ec2 delete-vpc \
                        --vpc-id $vpcID
			exit 1
	fi
	}

#Create a custom route table for  VPC 

route-table () {
	rtID=$(aws ec2 create-route-table \
	--vpc-id $vpcID \
	--query RouteTable.RouteTableId --output text)
	if [[ -z $rtID ]]
	then
		echo "Cant create Route Table"
		aws ec2 detach-internet-gateway \
			--internet-gateway-id $igwID \
			--vpc-id $vpcID
		aws ec2 delete-internet-gateway \
                        --internet-gateway-id $igwID
		aws ec2 delete-subnet \
                        --subnet-id $subnet1_ID
                aws ec2 delete-subnet \
                        --subnet-id $subnet2_ID
                aws ec2 delete-vpc \
                        --vpc-id $vpcID
			exit 1
		else
			echo "Route Table ID is : $rtID"
	fi
	}

#Create a route in the route table that points all traffic (0.0.0.0/0) to the internet gateway

points-route-table () {
	aws ec2 create-route \
	--route-table-id $rtID \
	--destination-cidr-block 0.0.0.0/0 \
	--gateway-id $igwID
	if [[ $? = 0 ]] 
        then 
        	echo "Create a route in the route table with 0.0.0.0/0"
        else 
                echo "Cant create route in the route table"
		aws ec2 delete-route-table \
			--route-table-id $rtID
		aws ec2 detach-internet-gateway \
                        --internet-gateway-id $igwID \
                        --vpc-id $vpcID
                aws ec2 delete-internet-gateway \
                        --internet-gateway-id $igwID
                aws ec2 delete-subnet \
                        --subnet-id $subnet1_ID
                aws ec2 delete-subnet \
                        --subnet-id $subnet2_ID
                aws ec2 delete-vpc \
                        --vpc-id $vpcID
			exit 1
        fi
	}

#Associate a subnet with the custom route table, we make our subnet public

associate-subnet () {
	rtassocID=$(aws ec2 associate-route-table  \
	--subnet-id $subnet1_ID \
	--route-table-id $rtID \
	--query "AssociationId" --output text)
	if [[ -z $rtassocID ]] 
        then 
                echo "Public Subnet is NOT associated with custom route table"
                aws ec2 delete-route-table \
                        --route-table-id $rtID
                aws ec2 detach-internet-gateway \
                        --internet-gateway-id $igwID \
                        --vpc-id $vpcID
                aws ec2 delete-internet-gateway \
                        --internet-gateway-id $igwID
                aws ec2 delete-subnet \
                        --subnet-id $subnet1_ID
                aws ec2 delete-subnet \
                        --subnet-id $subnet2_ID
                aws ec2 delete-vpc \
                        --vpc-id $vpcID
                        exit 1
	else 
		echo "Public Subnet is associated with custom route table"
        fi
	}

#Create a key pair, pipe your private key directly into a file with the .pem extension and change file permisions

create-keys () {
	aws ec2 create-key-pair \
	--key-name fun-aws-homework-key \
	--query "KeyMaterial" --output text > fun-aws-homework-key.pem
	chmod 400 fun-aws-homework-key.pem
	if [[ ! -f  fun-aws-homework-key.pem ]]
	then
		echo "Key not created !"
		aws ec2 disassociate-route-table \
			--association-id $rtassocID
		aws ec2 delete-route-table \
                        --route-table-id $rtID
                aws ec2 detach-internet-gateway \
                        --internet-gateway-id $igwID \
                        --vpc-id $vpcID
                aws ec2 delete-internet-gateway \
                        --internet-gateway-id $igwID
                aws ec2 delete-subnet \
                        --subnet-id $subnet1_ID
                aws ec2 delete-subnet \
                        --subnet-id $subnet2_ID
                aws ec2 delete-vpc \
                        --vpc-id $vpcID
                        exit 1
	else
	echo "Key Pair created"
	echo "key permissions are changed to 400"
	fi
	}

#Create a security group in  VPC

security-group () {
	sgID=$(aws ec2 create-security-group \
	--group-name my-homework-SG \
	--description "SG for homework SSH access" \
	--vpc-id $vpcID \
	--query "GroupId" --output text)
	if [[ -z $sgID ]]
	then
		echo "Cant create Security Group"
		delete-keys
		aws ec2 disassociate-route-table \
                        --association-id $rtassocID
                aws ec2 delete-route-table \
                        --route-table-id $rtID
                aws ec2 detach-internet-gateway \
                        --internet-gateway-id $igwID \
                        --vpc-id $vpcID
                aws ec2 delete-internet-gateway \
                        --internet-gateway-id $igwID
                aws ec2 delete-subnet \
                        --subnet-id $subnet1_ID
                aws ec2 delete-subnet \
                        --subnet-id $subnet2_ID
                aws ec2 delete-vpc \
                        --vpc-id $vpcID
                        exit 1
	else
		echo "Security Group ID is : $sgID"
	fi
	}

#Add a rule that allows SSH and HTTP access from anywhere

authorize-sg () {
	aws ec2 authorize-security-group-ingress \
	--group-id $sgID \
	--protocol tcp \
	--port 22 \
	--cidr 0.0.0.0/0 > /dev/null
	echo "Port 22 is open"
	aws ec2 authorize-security-group-ingress \
	--group-id $sgID \
	--protocol tcp \
	--port 80 \
	--cidr 0.0.0.0/0 > /dev/null
	echo "Port 80 is open"
	}

#Launch 1 t2.micro instance into your public subnet, using the security group and key pair

launch-instance () {
	instanceID=$(aws ec2 run-instances \
	--image-id ami-09d56f8956ab235b3 \
	--count 1 \
	--instance-type t2.micro \
	--key-name fun-aws-homework-key \
	--associate-public-ip-address \
	--security-group-ids $sgID \
	--subnet-id $subnet1_ID \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=inst-from-fun}]'\
	--query 'Instances[*].InstanceId' --output text)
	if [[ -z $instanceID ]]
	then
		echo "Instance is NOT created !!!"
		aws ec2 delete-security-group \
			--group-id $sgID
		delete-keys
                aws ec2 disassociate-route-table \
                        --association-id $rtassocID
                aws ec2 delete-route-table \
                        --route-table-id $rtID
                aws ec2 detach-internet-gateway \
                        --internet-gateway-id $igwID \
                        --vpc-id $vpcID
                aws ec2 delete-internet-gateway \
                        --internet-gateway-id $igwID
                aws ec2 delete-subnet \
                        --subnet-id $subnet1_ID
                aws ec2 delete-subnet \
                        --subnet-id $subnet2_ID
                aws ec2 delete-vpc \
                        --vpc-id $vpcID
                        exit 1
        else
		echo "Instance ID is : $instanceID"
	fi
	}

#Checking Instance Status and Public IP address

check-status () {
	aws ec2 wait instance-running \
        --instance-ids $instanceID 
	aws ec2 describe-instances \
	--instance-id $instanceID \
	--query "Reservations[*].Instances[*].{State:State.Name,Address:PublicIpAddress}"
	}

# Run the Script

	if [[ $1 = "create" ]]
	then
   		delete-keys && vpc && subnet1 && subnet2 && gateway && attach-gateway && route-table &&\
		points-route-table && associate-subnet && create-keys && security-group && authorize-sg &&\
		launch-instance && check-status 
		echo -e "$vpcID\n$subnet1_ID\n$subnet2_ID\n$igwID\n$rtID\n$rtassocID\n$sgID\n$instanceID" > fun-IDs.txt
	elif [[ $1 = "delete" ]]
	then
		aws ec2 terminate-instances \
			--instance-ids $(cat fun-IDs.txt | grep i-) 
		echo "Terminating INSTANCE !"
		aws ec2 wait instance-terminated \
			--instance-ids $(cat fun-IDs.txt | grep i-)
		aws ec2 delete-security-group \
			--group-id $(cat fun-IDs.txt | grep sg-)
                delete-keys
                aws ec2 disassociate-route-table \
			--association-id $(cat fun-IDs.txt | grep rtbassoc-)
		aws ec2 delete-route-table \
			--route-table-id $(cat fun-IDs.txt | grep rtb-)
                aws ec2 detach-internet-gateway \
			--internet-gateway-id $(cat fun-IDs.txt | grep igw-) \
			--vpc-id $(cat fun-IDs.txt | grep vpc-)
                aws ec2 delete-internet-gateway \
			--internet-gateway-id $(cat fun-IDs.txt | grep igw-)
                aws ec2 delete-subnet \
			--subnet-id $(cat fun-IDs.txt | grep subnet- | head -1)
                aws ec2 delete-subnet \
			--subnet-id $(cat fun-IDs.txt | grep subnet- | tail -1)
                aws ec2 delete-vpc \
			--vpc-id $(cat fun-IDs.txt | grep vpc-)
		echo "Everythig is deleted"
		rm -f fun-IDs.txt
	else echo -e "Invalid Argument \n create / delete "
	fi
