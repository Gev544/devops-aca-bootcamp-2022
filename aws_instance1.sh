#!/bin/bash

# 1 sign in amazon web server
# 2 from "security and credenshals" crate new access kay
# 3 install zip
# 4 install aws cli 
# 4.1 curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# 4.2  unzip awscliv2.zip
# 4.3  sudo ./aws/install
# 5 aws configure             #  "this is a comand"
# 5.1 #exemple
                 #AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
                 #AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
                 #Default region name [None]: us-west-2
                 #Default output format [None]: json


		 Crate_dir() {
			 mkdir Aws_Project
			 cd Aws_Project
			 echo "created repository by name Aws_Project"
			 x=`pwd`
			 echo "all files can be foundet :" $x
		 }

		aws_cli() {

	### install aws_cli and cofigure
	sudo apt update
	sudo apt install zip
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	unzip awscliv2.zip
	sudo ./aws/install
	aws configure
		}

		vpc() {

	### crate vpc and save on file vpc_id
	aws ec2 create-vpc --cidr-block 192.168.0.0/16 --query Vpc.VpcId --output text > vpc_id
	### crate subnet for vpc
	vpc_id1=`cat vpc_id`
		}

		subnet() {

	aws ec2 create-subnet --vpc-id $vpc_id1 --cidr-block 192.168.1.0/24 --query Subnet.SubnetId --output text > sub_id
	sub_id1=`cat sub_id`

	### crate second subnet
	#aws ec2 create-subnet --vpc-id $vpc_id1 --cidr-block 192.168.2.0/24 --output text > vpc_id2
		}

		getway() {

	### crate getway
	aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text > igw
igw1=`cat igw`
		}

		attach_getway() {

	### attach-internet-getway to vpc
	aws ec2 attach-internet-gateway --vpc-id $vpc_id1 --internet-gateway-id $igw1 
		}

		routing_table() {

	### crate routing table for vpc
	aws ec2 create-route-table --vpc-id $vpc_id1 --query RouteTable.RouteTableId --output text > rtb
rtb1=`cat rtb`
		}
		route() {

	### crate route for all trafic 0.0.0.0/0
	aws ec2 create-route --route-table-id $rtb1 --destination-cidr-block 0.0.0.0/0 --gateway-id $igw1
	##aws ec2 describe-route-tables --route-table-id rtb1
		}

		associetione() {

	### associate subnet to route table
	aws ec2 associate-route-table  --subnet-id $sub_id1 --route-table-id $rtb1 > associate1
         
	### show subnet associetione
	## aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-2f09a348" --query "Subnets[*].{ID:SubnetId,CIDR:CidrBlock}"
		}

		kay_pair() {

	### crate key pair
	aws ec2 create-key-pair --key-name MyKeyPair1 --query 'KeyMaterial' --output text > MyKeyPair1.pem

	### change permitione key pair
	chmod 400 MyKeyPair1.pem

	### cheek my keys on amazon
	#aws ec2 describe-key-pairs --key-name MyKeyPair

	### delete my key_pair
	#aws ec2 delete-key-pair --key-name MyKeyPair
		}

		security_group() {

	### crate security group
	aws ec2 create-security-group --group-name SSHAccess --description "Security group for SSH access" --vpc-id $vpc_id1 > security_group
	sec_group=`cat security_group`
		}

	 
		autorize_sec_grp() {

	### crate security group  
	aws ec2 authorize-security-group-ingress --group-id $sec_group --protocol tcp --port 22 --cidr 0.0.0.0/0 > allowed
	ssh1=`cat $x/"allowed" | head -n 1`
		}

		run_instance() {

	### install ec2
	###               ami-0c4f7023847b90238 (64-bit (x86)) ubuntu 20.04 free
	###               ami-09d56f8956ab235b3 (64-bit (x86)) ubuntu 22.04 free
	###               ami-0193dcf9aa4f5654e (64-bit (x86)  windows server 2019 free
	aws ec2 run-instances     --image-id ami-0c4f7023847b90238     --instance-type t2.micro     --subnet-id $sub_id1     --security-group-ids $sec_group     --associate-public-ip-address     --key-name MyKeyPair1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=test01}]' > Instans_configurationes

		}


	Implamantatione_Eror_Handling() {

	#crate directory and change dir		
	Crate_dir

	#install awc cli
	version=`aws --version 2>&1 | head -n 2 | tail -1 | cut -d "," -f 1`
	if [[ $version == "Command 'aws' not found" ]] 
	then
		awc_cli
	else 
		echo "aws cli exist"
	fi
	# crate vpc
	vpc
	if [[ ! -s $x/"vpc_id" ]]
	then
		echo "vpc was not created"
		exit
	else
		echo "vpc created"
	fi
	# crate subnet
	subnet
	if [[ ! -s $x/"sub_id" ]]
        then
                echo "subnet was not created"
                exit
        else
                echo "subnet created"
        fi
	# crate internet_getway
	getway
	if [[ ! -s $x/"igw" ]]
        then
                echo "internet_getway was not created"
                exit
        else
                echo "internet_getway created"
        fi
	# attach_getway
	attach_getway
	# crate route table for all trafic 0.0.0.0/0
	routing_table
	if [[ ! -s $x/"rtb" ]]
        then
                echo "route_table was not created"
                exit
        else
                echo "route_table created"
        fi
	# associate subnet to route table
	associetione
	if [[ ! -s $x/"associate1" ]]
        then
                echo "was not associated"
                exit
        else
                echo "associate"
        fi
	# create security_group
	security_group
	if [[ ! -s $x/"security_group" ]]
        then
                echo "security_group was not crieted"
                exit
        else
                echo "security_group crieted"
        fi
	# allow ssh conectione 
	autorize_sec_grp
	if [[ $ssh1 != True ]]
        then
                echo "ssh conectione not allowed"
                exit
        else
                echo "ssh conectione allowed"
        fi

	# create key_pair
	kay_pair
	if [[ ! -s $x/"MyKeyPair1.pem" ]]
        then
                echo "key_pair was not genereted"
                exit
        else
                echo "key_pair genereted"
        fi
	# create instance
	run_instance
	if [[ ! -s $x/"Instans_configurationes" ]]
        then
                echo "instance was not created"
                exit
        else
                cat "$x/Instans_configurationes"
        fi







}
Implamantatione_Eror_Handling



#get ip addres
#aws ec2 describe-instances \
#  --query "Reservations[*].Instances[*].PublicIpAddress" \
#  --output=text





