#!/bin/bash

set -e

key_name=fun-aws-homework-key
inst_tag_name=inst_from_func-2
dnsName=hayk-sargsyan.acadevopscourse.xyz
tgName=my-1stTG
lbName=my-1stLB


#Delete keys if we want to run script 2nd time
delete-keys () {
	aws ec2 delete-key-pair \
       --key-name $key_name 
	if [[ -f fun-aws-homework-key.pem ]]
	then
	rm -f $key_name.pem
	echo "aws-key is deleted"
	echo "Local key .pem is deleted"
	fi
}

#creating a userdata.txt file for ec2 instance

create-userdata () {
		echo -e '#!/bin/bash\nsudo apt update -y\nsudo apt install nginx -y' > userdata.txt
		echo "sudo apt install s3fs -y" >> userdata.txt
		echo "sudo apt install openjdk-11-jre -y" >> userdata.txt
		echo "userdata.txt file for ec2 are created"
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
	--availability-zone us-east-1a \
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
	--availability-zone us-east-1b \
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
	rtassoc1ID=$(aws ec2 associate-route-table  \
	--subnet-id $subnet1_ID \
	--route-table-id $rtID \
	--query "AssociationId" --output text)
	rtassoc2ID=$(aws ec2 associate-route-table  \
        --subnet-id $subnet2_ID \
        --route-table-id $rtID \
        --query "AssociationId" --output text)
	if [[ -z $rtassoc1ID ]] && [[ -z $rtassoc2ID ]]
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
		echo "Public Subnet 1 and 2 is associated with custom route table"
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
		aws ec2 disassociate-route-table \
			--association-id $rtassoc1ID 
		aws ec2 disassociate-route-table \
                        --association-id $rtassoc2ID
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
                        --association-id $rtassoc1ID
		aws ec2 disassociate-route-table \
                        --association-id $rtassoc2ID
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
	aws ec2 authorize-security-group-ingress \
        --group-id $sgID \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0 > /dev/null
        echo "Port 443 is open"

	}

#Launch 1 t2.micro instance into your public subnet, using the security group and key pair

launch-instance () {
	instance1ID=$(aws ec2 run-instances \
	--image-id ami-09d56f8956ab235b3 \
	--count 1 \
	--instance-type t2.micro \
	--key-name $key_name \
	--associate-public-ip-address \
	--security-group-ids $sgID \
	--subnet-id $subnet1_ID \
	--user-data file://userdata.txt \
	--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$inst_tag_name}]"\
	--query 'Instances[*].InstanceId' --output text)
	if [[ -z $instance1ID ]]
	then
		echo "Instance is NOT created !!!"
		aws ec2 delete-security-group \
			--group-id $sgID
		delete-keys
                aws ec2 disassociate-route-table \
                        --association-id $rtassoc1ID
		aws ec2 disassociate-route-table \
                        --association-id $rtassoc2ID
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
                 echo "Instance ID is : $instance1ID"
         fi

	instance2ID=$(aws ec2 run-instances \
        --image-id ami-09d56f8956ab235b3 \
        --count 1 \
        --instance-type t2.micro \
        --key-name $key_name \
        --associate-public-ip-address \
        --security-group-ids $sgID \
        --subnet-id $subnet2_ID \
		--user-data file://userdata.txt \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$inst_tag_name}]"\
        --query 'Instances[*].InstanceId' --output text)
        if [[ -z $instance2ID ]]
        then
                echo "Instance is NOT created !!!"
                aws ec2 delete-security-group \
                        --group-id $sgID
                delete-keys
                aws ec2 disassociate-route-table \
                        --association-id $rtassoc1ID
		aws ec2 disassociate-route-table \
                        --association-id $rtassoc2ID
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
		echo "Instance ID is : $instance2ID"
	fi
	}

#Checking Instance Status and Public IP address

check-status () {
	aws ec2 wait instance-running \
        --instance-ids $instance1ID $instance2ID
	aws ec2 describe-instances \
	--query "Reservations[*].Instances[*].State.Name" \
	--instance-ids $instance1ID $instance2ID \
	--output text
	ipAdr=$(aws ec2 describe-instances \
	--instance-ids $instance1ID $instance2ID \
	--query "Reservations[*].Instances[*].PublicIpAddress" \
	--output text)
	echo $ipAdr
	}

#copy ssh key to knoun_hosts

add_ssh_key_to_known_hosts () {
	aws ec2 wait instance-status-ok \
    	--instance-ids $instance1ID $instance2ID
	ssh-keyscan $ipAdr >> ~/.ssh/known_hosts
	echo "SSH key added to Known_Hosts!!"
	}

#create elastic load balancer target group

craeteTG () {
	tgArn=$(aws elbv2 create-target-group \
	--name $tgName \
	--protocol HTTP \
	--port 80 \
	--target-type instance \
	--vpc-id $vpcID |  grep "TargetGroupArn" | cut -d '"' -f 4 | head -1)
	
aws elbv2 register-targets \
		--target-group-arn $tgArn \
		--targets \
		Id=$instance1ID \
		Id=$instance2ID
if [[ ! -z $tgArn ]]
then
	echo "Load balancer Target Group is Created and Registered!"
else echo "Target Group is NOT created"
./create-aws-ec2.sh delete
fi
}

#delete elastic load balancer target group

deleteTG () {
	tgArn=$(cat fun-IDs.txt | grep "targetgrouparn" | cut -d " " -f 2)
	aws elbv2 delete-target-group --target-group-arn $tgArn
	echo "Target Group $tgName is Deleted"
}

#create load balancer and 2 lisener

createLB () {
	certArn=$(aws acm list-certificates --query CertificateSummaryList[*].CertificateArn --output text)
	lbArn=$(aws elbv2 create-load-balancer \
		--name $lbName \
		--subnets $subnet1_ID $subnet2_ID \
		--security-groups $sgID |
 		grep "LoadBalancerArn" | cut -d '"' -f 4 ) 
	aws elbv2 create-listener \
		--load-balancer-arn $lbArn \
		--protocol HTTPS \
		--port 443  \
		--certificates CertificateArn=$certArn \
		--default-actions Type=forward,TargetGroupArn=$tgArn > /dev/null
	aws elbv2 create-listener \
		--load-balancer-arn $lbArn \
		--protocol HTTP --port 80  \
		--default-actions '[{"Type": "redirect", "RedirectConfig": {"Protocol": "HTTPS", "Port": "443", "Host": "#{host}", "Query": "#{query}", "Path": "/#{path}", "StatusCode": "HTTP_301"}}]' > /dev/null
	if [[ ! -z $lbArn ]]
	then
		lbDNS=$(aws elbv2 describe-load-balancers --load-balancer-arns $lbArn | grep "DNSName" | cut -d '"' -f 4)
		echo -e "Load Balancer DNS is $lbDNS"
	else echo "Load Balancer is NOT created" 
	deleteLB && deleteTG
	./create-aws-ec2.sh delete
	fi
}

# Deletes Load Balancer
deleteLB () {
	aws elbv2 delete-load-balancer --load-balancer-arn $(cat fun-IDs.txt | grep lbArn | cut -d " " -f 2)
	echo "Application Load Balancer $lbName is Deleted"
}


#Creating json file to update dns zone

createJSON () {
lbZoneID=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns $lbArn \
    --query LoadBalancers[0].CanonicalHostedZoneId \
    --output text)
echo    '{
                "Comment": "Domain for our web page",
                "Changes": [ {
                             "Action": "UPSERT",
                            "ResourceRecordSet": {
                                "Name": "'$dnsName'",
                                "Type": "A",
                                "AliasTarget":{
                                    "HostedZoneId": "'$lbZoneID'",
                                    "DNSName": "dualstack.'$lbDNS'",
                                    "EvaluateTargetHealth": false
                                }
                            }
                }]
}' > route53Conf.json
}

#creating or updating the A record

createArec () {
hostZoneID=$(aws route53 list-hosted-zones-by-name  \
            --dns-name $dnsName \
			--query HostedZones[*].Id \
            --output text | cut -d "/" -f 3)
aws route53 change-resource-record-sets \
    --hosted-zone-id $hostZoneID \
    --change-batch file://route53Conf.json 1>/dev/null && \
    echo "DNS Record is set"
rm -f route53Conf.json
}

# Run the Script

	if [[ $1 = "create" ]]
	then
   		create-userdata && delete-keys && vpc && subnet1 && subnet2 && gateway && attach-gateway && \
		route-table && points-route-table && associate-subnet && create-keys && security-group && authorize-sg &&\
		launch-instance && check-status && add_ssh_key_to_known_hosts && craeteTG && createLB && createJSON &&\
		createArec
		echo -e "$vpcID\n$subnet1_ID\n$subnet2_ID\n$igwID\n$rtID\n$rtassoc1ID $rtassoc2ID\n$sgID\n$instance1ID $instance2ID\nip $ipAdr" > fun-IDs.txt
		echo -e "targetgrouparn $tgArn\ncertificateArn_is $certArn\nlbArn $lbArn" >> fun-IDs.txt
		
	elif [[ $1 = "delete" ]]
	then
		deleteLB && sleep 15 && deleteTG
		aws ec2 terminate-instances \
			--instance-ids $(cat fun-IDs.txt | grep i-) > /dev/null
		echo "Terminating INSTANCE !"
		aws ec2 wait instance-terminated \
			--instance-ids $(cat fun-IDs.txt | grep i-)
		aws ec2 delete-security-group \
			--group-id $(cat fun-IDs.txt | grep sg-)
                delete-keys
                aws ec2 disassociate-route-table \
			--association-id $(cat fun-IDs.txt | grep rtbassoc-| cut -d " " -f 1)
		aws ec2 disassociate-route-table \
                        --association-id $(cat fun-IDs.txt | grep rtbassoc- | cut -d " " -f 2)
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
		rm -f userdata.txt
		rm -f fun-IDs.txt
	else echo -e "Invalid Argument \n create / delete "
	fi


