#!/bin/bash

set -e

iam_user=Xuser
key_name=aws-slave-key
inst_tag_name=jenkins_slave
bucket_name=aca$(date +%s)

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
                delete_vpc
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
                delete_subnet1 && delete_vpc
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
                delete_subnet2 && delete_subnet1 && delete_vpc
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
		delete_igw && delete_subnet2 && delete_subnet1 && delete_vpc
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
                detach_igw && delete_igw && delete_subnet2 && delete_subnet1 && delete_vpc        
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
                delete_rt && detach_igw && delete_igw && delete_subnet2 && delete_subnet1 && delete_vpc  
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
		delete_rt && detach_igw && delete_igw && delete_subnet2 && delete_subnet1 && delete_vpc
                        exit 1
        else
                echo "Public Subnet is associated with custom route table"
        fi
        }

#Create a key pair, pipe your private key directly into a file with the .pem extension and change file permisions

create-keys () {
        aws ec2 create-key-pair \
        --key-name $key_name \
        --query "KeyMaterial" --output text > $key_name.pem
        chmod 400 $key_name.pem
        if [[ ! -f  $key_name.pem ]]
        then
                echo "Key not created !"
        	disassociate_rt && delete_rt && detach_igw && delete_igw && delete_subnet2 \
		&& delete_subnet1 && delete_vpc
			exit 1
        else
        echo "Key Pair created"
        echo "key permissions are changed to 400"
        fi
        }

#Create a security group in  VPC

security-group () {
        sgID=$(aws ec2 create-security-group \
        --group-name my-jenkins-slave-SG \
        --description "SG for homework SSH access" \
        --vpc-id $vpcID \
        --query "GroupId" --output text)
        if [[ -z $sgID ]]
        then
                echo "Cant create Security Group"
                delete-keys && disassociate_rt && delete_rt && detach_igw && delete_igw \
		&& delete_subnet2  && delete_subnet1 && delete_vpc
                        exit 1
        else
                echo "Security Group ID is : $sgID"
        fi
        }

#Add a rule that allows SSH, HTTP and HTTPS access from anywhere

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
        aws ec2 authorize-security-group-ingress \
        --group-id $sgID \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0 > /dev/null
        echo "Port 443 is open"
        }

#Launch 1 t2.micro instance into your public subnet, using the security group and key pair

launch-instance () {
        instanceID=$(aws ec2 run-instances \
        --image-id ami-09d56f8956ab235b3 \
        --count 1 \
        --instance-type t2.micro \
        --key-name $key_name \
        --associate-public-ip-address \
        --security-group-ids $sgID \
        --subnet-id $subnet1_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$inst_tag_name}]"\
        --query 'Instances[*].InstanceId' --output text)
        if [[ -z $instanceID ]]
        then
                echo "Instance is NOT created !!!"
        	delete_sg && delete-keys && disassociate_rt && delete_rt && detach_igw \
		&& delete_igw && delete_subnet2  && delete_subnet1 && delete_vpc
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
        --query "Reservations[*].Instances[*].State.Name" \
        --instance-ids $instanceID \
        --output text
        ipAdr=$(aws ec2 describe-instances \
        --instance-ids $instanceID \
        --query "Reservations[*].Instances[*].PublicIpAddress" \
        --output text)
        echo $ipAdr
        }

#copy ssh key to knoun_hosts

add_ssh_key_to_known_hosts () {
        aws ec2 wait instance-status-ok \
        --instance-ids $instanceID
        ssh-keyscan $ipAdr >> ~/.ssh/known_hosts
        echo "SSH key added to Known_Hosts!!"
        ssh -i $key_name.pem ubuntu@$ipAdr "sudo apt-get install openjdk-11-jre -y" > /dev/null
	echo "Java is installed"
	}

#copy IDs to text file

copy_ids () {
	echo -e "$vpcID\n$subnet1_ID\n$subnet2_ID\n$igwID\n$rtID\n$rtassocID\n$sgID\n$instanceID\nip $ipAdr" > slave-IDs.txt
	}

#create s3 bucket

create-s3 () {
        bucketID=$(aws s3api create-bucket \
                --bucket $bucket_name)
                #--acl public-read \
                #--output text)
                echo "bucket_name_is $bucket_name" >> slave-IDs.txt
                }

#creating index.html and other files and move them to the created s3 bucket

create-index-others () {
                echo "Barev World JAN !" > index.html
                echo -e "[Unit]\nDescription=Refresh html\n\n[Service]\nExecStart=/home/ubuntu/refresh-index.sh\n\n[Install]\nWantedBy=multi-user.target " > z-refresh.service
                aws s3 mv index.html s3://$bucket_name
                aws s3 mv z-refresh.service s3://$bucket_name
                aws s3 cp refresh-index.sh s3://$bucket_name
                fileUrl=https://s3.amazonaws.com/$bucket_name/index.html
                serviceUrl=https://s3.amazonaws.com/$bucket_name/z-refresh.service
                refreshIndex=https://s3.amazonaws.com/$bucket_name/refresh-index.sh
                echo "index.html, z-refresh and refresh-index are created and uploaded in s3 bucket"
                }

#make file public

make-public () {
                aws s3api put-object-acl \
                --bucket $bucket_name \
                --key index.html \
                --acl public-read
                aws s3api put-object-acl \
                --bucket $bucket_name \
                --key z-refresh.service \
                --acl public-read
                aws s3api put-object-acl \
                --bucket $bucket_name \
                --key refresh-index.sh \
                --acl public-read
                echo "Files are Public"
}

#creating aws  IAM user

create_iam_user () {
        userID=$(aws iam create-user \
                --user-name  $iam_user \
                --permissions-boundary arn:aws:iam::aws:policy/AmazonS3FullAccess \
                --query 'User.UserId' \
                --output text)
                echo $userID > Xuser.credentials.txt
                echo "$iam_user IAM user is created"
        }

#attaching s3 full access to created user

attach_policy () {
        aws iam attach-user-policy \
                --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
                --user-name $iam_user
        echo "user policy AmazonS3FullAccess is attached"
        }

#creating  keys for IAM user and file with credentials for ec2 instance to merge s3 bucket

create_iam_keys () {
        credentials=$(aws iam create-access-key \
                --user-name $iam_user \
                --query 'AccessKey.[AccessKeyId,SecretAccessKey]' \
                --output text)
        accessKeyID=$(echo ${credentials} | cut -d " " -f 1)
        secretAccessKey=$(echo ${credentials} |tr -s " " | cut -d " " -f 2)
        echo -e "$accessKeyID\n$secretAccessKey" >> Xuser.credentials.txt
        echo -e "$accessKeyID:$secretAccessKey" > .passwd-s3fs
        sudo chmod 600 .passwd-s3fs
        echo "access keys are created and created .passwrd-s3fs file with credential"
        }

#checking bucket and files 

check_bucket () {
        number_of_files=$(aws s3 ls s3://$bucket_name | wc -l)
        if [[ $number_of_files -ne 3 ]]
        then
                echo "something is wrong with bucket"
		aws s3 rb s3://$bucket_name --force 2> /dev/null
		terminate_ec2 && delete_sg && delete-keys && disassociate_rt && delete_rt \
                && detach_igw && delete_igw && delete_subnet2  && delete_subnet1 && delete_vpc
                 exit 1
        fi
        }

#checking user and attached policies

check_user_policies () {
        policy=$(aws iam list-attached-user-policies --user-name $iam_user | grep AmazonS3FullAccess | wc -l)
        if [[ $policy -ne 2 ]]
        then
                echo "user not created or policy not attached"
                detach_policy > /dev/null
                delete_user > /dev/null
                aws s3 rb s3://$bucket_name --force
		terminate_ec2 && delete_sg && delete-keys && disassociate_rt && delete_rt \
                && detach_igw && delete_igw && delete_subnet2  && delete_subnet1 && delete_vpc
		exit 1
        fi
        }

check_credentials () {
        if [[ -f .passwd-s3fs ]] && [[ -n .passwd-s3fs ]]
        then
                echo ".passwd-s3fs file exists and not empty"
        else    echo "something goes wrong with creating .passwd-s3fs file"
                delete_access_key
                detach_policy
                delete_user
                aws s3 rb s3://$bucket_name --force
                terminate_ec2 && delete_sg && delete-keys && disassociate_rt && delete_rt \
		&& detach_igw && delete_igw && delete_subnet2  && delete_subnet1 && delete_vpc
		exit 1
        fi
}

#secure copy iam user credentials file to ec2 instance

copy_cred () {
        scp -i ./*.pem .passwd-s3fs ubuntu@$(cat slave-IDs.txt | grep ip | cut -d " " -f 2):~/ && \
        rm -f .passwd-s3fs
        echo ".passwd-s3fs file copied to ec2 and removed from local "
        }

#delete access key for iam user

delete_access_key () {
        aws iam delete-access-key \
                --access-key-id  $(cat Xuser.credentials.txt | head -2 | tail -1) \
                --user-name $iam_user
	echo "access keys are deleted"
                }

#detaching policy from iam user

detach_policy () {
       	aws iam detach-user-policy \
		--user-name $iam_user \
		--policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
	echo "AmazonS3FullAccess policy is detached"
		}

#deleting iam user

delete_user () {
        aws iam delete-user --user-name $iam_user && rm -f Xuser.credentials.txt
	echo "IAM user is deleted"
	}

#deleting s3 bucket and objects

delete_s3_objects () {
	aws s3 rb s3://$(cat slave-IDs.txt | grep bucket | cut -d " " -f 2) --force
	echo "s3 bucket and objects are deleted"
		}

#delete security groupe

delete_sg () {
	aws ec2 delete-security-group --group-id $sgID
	}

#delete keys on local and aws

delete-keys () {
        aws ec2 delete-key-pair --key-name $key_name
        if [[ -f $key_name.pem ]]
        then
        rm -f $key_name.pem
        echo "aws-key is deleted"
        echo "Local key .pem is deleted"
        fi
	}

#disassociate route table

disassociate_rt () {
	aws ec2 disassociate-route-table --association-id $rtassocID
	}

#delete route table

delete_rt () {
	aws ec2 delete-route-table --route-table-id $rtID
	}

#detach internet gateway

detach_igw () {
	aws ec2 detach-internet-gateway --internet-gateway-id $igwID --vpc-id $vpcID
	}

#delete internet gateway

delete_igw () { 
	aws ec2 delete-internet-gateway --internet-gateway-id $igwID
	}

#delete subnets

delete_subnet1 () {
	aws ec2 delete-subnet --subnet-id $subnet1_ID
	}
delete_subnet2 () {
        aws ec2 delete-subnet --subnet-id $subnet2_ID
        }

#delete VPC

delete_vpc () {
	aws ec2 delete-vpc --vpc-id $vpcID
	}

#terminate ec2 instance

terminate_ec2 () {
		aws ec2 terminate-instances \
                        --instance-ids $instanceID
                echo "Terminating INSTANCE !"
                aws ec2 wait instance-terminated \
                        --instance-ids $instanceID
	}

# Run the Script

        if [[ $1 = "create" ]]
        then
                vpc && subnet1 && subnet2 && gateway && attach-gateway && route-table &&\
                points-route-table && associate-subnet && create-keys && security-group && authorize-sg &&\
                launch-instance && check-status && add_ssh_key_to_known_hosts && copy_ids && create-s3 &&\
		create-index-others && make-public && check_bucket && create_iam_user && attach_policy &&\
		check_user_policies && create_iam_keys && check_credentials && copy_cred

        elif [[ $1 = "delete" ]]
        then
                delete_access_key && detach_policy  && delete_user && delete_s3_objects
		aws ec2 terminate-instances \
                        --instance-ids $(cat slave-IDs.txt | grep i-)
                echo "Terminating INSTANCE !"
                aws ec2 wait instance-terminated \
                        --instance-ids $(cat slave-IDs.txt | grep i-)
                aws ec2 delete-security-group \
                        --group-id $(cat slave-IDs.txt | grep sg-)
		echo "deleted SG"
                delete-keys
                aws ec2 disassociate-route-table \
                        --association-id $(cat slave-IDs.txt | grep rtbassoc-)
		echo "route table disassociated"
                aws ec2 delete-route-table \
                        --route-table-id $(cat slave-IDs.txt | grep rtb-)
		echo "route table deleted"
                aws ec2 detach-internet-gateway \
                        --internet-gateway-id $(cat slave-IDs.txt | grep igw-) \
                        --vpc-id $(cat slave-IDs.txt | grep vpc-)
		echo "internet gateway is detached"
                aws ec2 delete-internet-gateway \
                        --internet-gateway-id $(cat slave-IDs.txt | grep igw-)
		echo "internet gateway is deleted"
                aws ec2 delete-subnet \
                        --subnet-id $(cat slave-IDs.txt | grep subnet- | head -1)
		echo "subnet1 is deleted"
                aws ec2 delete-subnet \
                        --subnet-id $(cat slave-IDs.txt | grep subnet- | tail -1)
		echo "subnet2 is deleted"
                aws ec2 delete-vpc \
                        --vpc-id $(cat slave-IDs.txt | grep vpc-)
		echo "vpc is deleted"
                echo "Everythig is deleted"
		rm -f slave-IDs.txt
		else echo -e "Invalid Argument \n create / delete "
        	fi                
