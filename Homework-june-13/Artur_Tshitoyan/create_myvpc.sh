#!/bin/bash

vpcs_file="myvpc.txt"

write_vpc_to_file() {
echo $AWS_VPC >> $vpcs_file
}

trap write_vpc_to_file EXIT

## Create a VPC
AWS_VPC_ID=$(aws ec2 create-vpc \
--cidr-block 10.0.0.0/16 \
--query 'Vpc.{VpcId:VpcId}' \
--output text)
AWS_VPC="$AWS_VPC_ID"
if
  [[ ! -z $AWS_VPC_ID ]]
then
  echo "VPC successfuly created and have "$AWS_VPC_ID" ID" | tee ./myvpc.log
else
  exit
fi

## Enable DNS hostname for your VPC
aws ec2 modify-vpc-attribute \
--vpc-id $AWS_VPC_ID \
--enable-dns-hostnames "{\"Value\":true}"
echo "On "$AWS_VPC_ID" enabled DNS hostname" | tee -a ./myvpc.log

## Create a public subnet
AWS_SUBNET_PUBLIC_ID=$(aws ec2 create-subnet \
--vpc-id $AWS_VPC_ID \
--cidr-block 10.0.1.0/24 \
--availability-zone us-east-1a \
--query 'Subnet.{SubnetId:SubnetId}' \
--output text)
AWS_VPC="$AWS_VPC $AWS_SUBNET_PUBLIC_ID"
if
  [[ ! -z $AWS_SUBNET_PUBLIC_ID ]]
then
  echo "Public Subnet for "$AWS_VPC_ID" successfully created and have "$AWS_SUBNET_PUBLIC_ID "ID" | tee -a ./myvpc.log
else
  aws ec2 modify-vpc-attribute \
--vpc-id $AWS_VPC_ID \
--enable-dns-hostnames "{\"Value\":false}" && \
  aws ec2 delete-vpc \
--vpc-id $AWS_VPC_ID && \
  rm -f myvpc.txt myvpc.log
  echo "myvpc "$AWS_VPC_ID" deleted due to error with creating Public subnet" > ./error.log
  exit
fi

## Enable Auto-assign Public IP on Public Subnet
aws ec2 modify-subnet-attribute \
--subnet-id $AWS_SUBNET_PUBLIC_ID \
--map-public-ip-on-launch
echo "Auto-assign Public ip on Public Subnet "$AWS_SUBNET_PUBLIC_ID" is successful" | tee -a ./myvpc.log

## Create an Internet Gateway
AWS_INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway \
--query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
--output text)
AWS_VPC="$AWS_VPC $AWS_INTERNET_GATEWAY_ID"
if
  [[ ! -z $AWS_INTERNET_GATEWAY_ID ]]
then
  echo "Internet Gateway successfully created and have "$AWS_INTERNET_GATEWAY_ID "ID" | tee -a ./myvpc.log
else
aws ec2 delete-subnet \
--subnet-id $AWS_SUBNET_PUBLIC_ID && \	
aws ec2 modify-vpc-attribute \
--vpc-id $AWS_VPC_ID \
--enable-dns-hostnames "{\"Value\":false}" && \
aws ec2 delete-vpc \
--vpc-id $AWS_VPC_ID && \
rm -f myvpc.txt myvpc.log && \
echo "Public Subnet  "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID "are deleted due to error with creating Internet Gateway" > ./error.log
exit
fi

## Attach Internet gateway to your VPC
aws ec2 attach-internet-gateway \
--vpc-id $AWS_VPC_ID \
--internet-gateway-id $AWS_INTERNET_GATEWAY_ID
echo "Internet Gateway "$AWS_INTERNET_GATEWAY_ID" successfully attached to "$AWS_VPC_ID "VPC" | tee -a ./myvpc.log

## Add a ID to the default route table
AWS_DEFAULT_ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
--filters "Name=vpc-id,Values=$AWS_VPC_ID" \
--query 'RouteTables[?Associations[0].Main != flase].RouteTableId' \
--output text)
AWS_VPC="$AWS_VPC $AWS_DEFAULT_ROUTE_TABLE_ID"
echo "Default Route Table ID is "$AWS_DEFAULT_ROUTE_TABLE_ID | tee -a ./myvpc.log

## Create a route table
AWS_CUSTOM_ROUTE_TABLE_ID=$(aws ec2 create-route-table \
--vpc-id $AWS_VPC_ID \
--query 'RouteTable.{RouteTableId:RouteTableId}' \
--output text)
AWS_VPC="$AWS_VPC $AWS_CUSTOM_ROUTE_TABLE_ID"
if
  [[ ! -z $AWS_CUSTOM_ROUTE_TABLE_ID ]]
then
echo "Custom Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" successfully created" | tee -a ./myvpc.log
else
aws ec2 detach-internet-gateway \
--internet-gateway-id $AWS_INTERNET_GATEWAY_ID \
--vpc-id $AWS_VPC_ID && \
aws ec2 delete-internet-gateway \
--internet-gateway-id $AWS_INTERNET_GATEWAY_ID && \
aws ec2 delete-subnet \
--subnet-id $AWS_SUBNET_PUBLIC_ID && \  
aws ec2 modify-vpc-attribute \
--vpc-id $AWS_VPC_ID \
--enable-dns-hostnames "{\"Value\":false}" && \
aws ec2 delete-vpc \
--vpc-id $AWS_VPC_ID && \
rm -f myvpc.txt myvpc.log && \
echo "Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID "are deleted due to error with creating Internet Gateway" > ./error.log
fi

## Create route to Internet Gateway
aws ec2 create-route \
--route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
--destination-cidr-block 0.0.0.0/0 \
--gateway-id $AWS_INTERNET_GATEWAY_ID
echo "Created route from Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID "to" $AWS_INTERNET_GATEWAY_ID "Internet Gateway" | tee -a ./myvpc.log

## Associate the public subnet with route table
AWS_ROUTE_TABLE_ASSOID=$(aws ec2 associate-route-table \
--subnet-id $AWS_SUBNET_PUBLIC_ID \
--route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
--output text | head -1)
AWS_VPC="$AWS_VPC $AWS_ROUTE_TABLE_ASSOID"
echo "Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" associated to "$AWS_SUBNET_PUBLIC_ID" Public Subnet" | tee -a ./myvpc.log

## Create a security group
aws ec2 create-security-group \
--vpc-id $AWS_VPC_ID \
--group-name myvpc-security-group \
--description 'My VPC non default security group'
echo "Security Group for" $AWS_VPC_ID "successfuly created" | tee -a ./myvpc.log

AWS_CUSTOM_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
--filters "Name=vpc-id,Values=$AWS_VPC_ID" \
--query 'SecurityGroups[?GroupName == `myvpc-security-group`].GroupId' \
--output text)
AWS_VPC="$AWS_VPC $AWS_CUSTOM_SECURITY_GROUP_ID"
if
  [[ ! -z $AWS_CUSTOM_SECURITY_GROUP_ID ]]
then
echo "Myvpc-Custom-Security-Group has "$AWS_CUSTOM_SECURITY_GROUP_ID" ID" | tee -a ./myvpc.log
else
aws ec2 disassociate-route-table \
--association-id $AWS_ROUTE_TABLE_ASSOID && \
aws ec2 delete-route \
--route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
--destination-cidr-block 0.0.0.0/0 && \
aws ec2 delete-route-table \
--route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID && \
aws ec2 detach-internet-gateway \
--internet-gateway-id $AWS_INTERNET_GATEWAY_ID \
--vpc-id $AWS_VPC_ID && \
aws ec2 delete-internet-gateway \
--internet-gateway-id $AWS_INTERNET_GATEWAY_ID && \
aws ec2 delete-subnet \
--subnet-id $AWS_SUBNET_PUBLIC_ID && \ 
aws ec2 modify-vpc-attribute \
--vpc-id $AWS_VPC_ID \
--enable-dns-hostnames "{\"Value\":false}" && \
aws ec2 delete-vpc \
--vpc-id $AWS_VPC_ID && \
rm -f myvpc.txt myvpc.log && \
echo "Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID "are deleted due to error with creating Custom Security Group"> ./error.log
exit
fi

## Get security group ID's
AWS_DEFAULT_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
--filters "Name=vpc-id,Values=$AWS_VPC_ID" \
--query 'SecurityGroups[?GroupName == `default`].GroupId' \
--output text)
AWS_VPC="$AWS_VPC $AWS_DEFAULT_SECURITY_GROUP_ID"
echo "Default Security Group has "$AWS_DEFAULT_SECURITY_GROUP_ID" ID" | tee -a ./myvpc.log

## Create security group ingress rules
aws ec2 authorize-security-group-ingress \
--group-id $AWS_CUSTOM_SECURITY_GROUP_ID \
--ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]}]'
echo "Added ssh rule to "$AWS_CUSTOM_SECURITY_GROUP_ID" Security Group" | tee -a ./myvpc.log

aws ec2 authorize-security-group-ingress \
--group-id $AWS_CUSTOM_SECURITY_GROUP_ID \
--ip-permissions '[{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow HTTP"}]}]'
echo "Added http rule to "$AWS_CUSTOM_SECURITY_GROUP_ID" Security Group" | tee -a ./myvpc.log

## Get Amazon Linux 2 latest AMI ID
AWS_AMI_ID=$(aws ec2 describe-images \
--owners 'amazon' \
--filters 'Name=name,Values=amzn2-ami-hvm-2.0.20220426.0-x86_64-gp2' 'Name=state,Values=available' \
--query 'sort_by(Images, &CreationDate)[-1].[ImageId]' --output 'text')
AWS_VPC="$AWS_VPC $AWS_AMI_ID"
if
  [[ ! -z $AWS_CUSTOM_SECURITY_GROUP_ID ]]
then
echo "Amazon Linux 2 latest AMI ID is "$AWS_AMI_ID | tee  ./instance.log
else
exit
fi

## Create a key-pair
aws ec2 create-key-pair \
--key-name myvpc-ec2-keypair \
--query 'KeyMaterial' \
--output text > myvpc-ec2-keypair.pem
if
  [[ -f ./myvpc-ec2-keypair.pem ]]
then
chmod 400 myvpc-ec2-keypair.pem
echo "Security key-pair for Amazon Linux instance successfuly created and located in current directory with name myvpc-ec2-keypair.pem" | tee -a ./instance.log
else
exit
fi

## Create an EC2 instance
AWS_EC2_INSTANCE_ID=$(aws ec2 run-instances \
--image-id $AWS_AMI_ID \
--instance-type t2.micro \
--key-name myvpc-ec2-keypair \
--monitoring "Enabled=false" \
--security-group-ids $AWS_CUSTOM_SECURITY_GROUP_ID \
--subnet-id $AWS_SUBNET_PUBLIC_ID \
--user-data file://myuserdata.txt \
--private-ip-address 10.0.1.10 \
--query 'Instances[*].InstanceId' \
--output text)
AWS_VPC="$AWS_VPC $AWS_EC2_INSTANCE_ID"
if
  [[ ! -z $AWS_EC2_INSTANCE_ID ]]
then
echo "EC2 instance successfuly created and have "$AWS_EC2_INSTANCE_ID" ID" | tee -a ./instance.log
else
aws ec2 delete-key-pair \
--key-name myvpc-ec2-keypair && rm -f myvpc-ec2-keypair.pem instance.log && \
aws ec2 delete-security-group \
--group-id $AWS_CUSTOM_SECURITY_GROUP_ID && \
aws ec2 disassociate-route-table \
--association-id $AWS_ROUTE_TABLE_ASSOID && \
aws ec2 delete-route \
--route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
--destination-cidr-block 0.0.0.0/0 && \
aws ec2 delete-route-table \
--route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID && \
aws ec2 detach-internet-gateway \
--internet-gateway-id $AWS_INTERNET_GATEWAY_ID \
--vpc-id $AWS_VPC_ID && \
aws ec2 delete-internet-gateway \
--internet-gateway-id $AWS_INTERNET_GATEWAY_ID && \
aws ec2 delete-subnet \
--subnet-id $AWS_SUBNET_PUBLIC_ID && \ 
aws ec2 modify-vpc-attribute \
--vpc-id $AWS_VPC_ID \
--enable-dns-hostnames "{\"Value\":false}" && \
aws ec2 delete-vpc \
--vpc-id $AWS_VPC_ID && \
rm -f myvpc.txt myvpc.log && \
echo "Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID" are deleted due to error creating EC2 instance" > ./instance_error.log
echo "myvpc-keypair deleted from AWS and localhost due to error creating EC2 Instance" >> ./instance_error.log
exit
fi

# Get the public ip address of your instance
AWS_EC2_INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances \
--query "Reservations[*].Instances[*].PublicIpAddress" \
--output text)
AWS_VPC="$AWS_VPC $AWS_EC2_INSTANCE_PUBLIC_IP"
echo "The Amazon Linux 2 Instance "$AWS_EC2_INSTANCE_ID" has Public ip adress "$AWS_EC2_INSTANCE_PUBLIC_IP | tee -a ./instance.log

## Add a tag to the VPC
aws ec2 create-tags --resources $AWS_VPC_ID --tags "Key=Name,Value=myvpc"

## Add a tag to public subnet
aws ec2 create-tags --resources $AWS_SUBNET_PUBLIC_ID --tags "Key=Name,Value=myvpc-public-subnet"

## Add a tag to the Internet-Gateway
aws ec2 create-tags --resources $AWS_INTERNET_GATEWAY_ID --tags "Key=Name,Value=myvpc-internet-gateway"

## Add a tag to the default route table
aws ec2 create-tags --resources $AWS_DEFAULT_ROUTE_TABLE_ID --tags "Key=Name,Value=myvpc-default-route-table"

## Add a tag to the public route table
aws ec2 create-tags --resources $AWS_CUSTOM_ROUTE_TABLE_ID --tags "Key=Name,Value=myvpc-public-route-table"

## Add a tags to security groups
aws ec2 create-tags --resources $AWS_CUSTOM_SECURITY_GROUP_ID --tags "Key=Name,Value=myvpc-security-group"

aws ec2 create-tags --resources $AWS_DEFAULT_SECURITY_GROUP_ID --tags "Key=Name,Value=myvpc-default-security-group"

## Add a tag to the ec2 instance
aws ec2 create-tags --resources $AWS_EC2_INSTANCE_ID --tags "Key=Name,Value=myvpc-ec2-instance"
echo "Added Tags to created resources"
