#!/bin/bash

source ./functions.sh

write_vpc_to_file ()
  {
echo $AWS_VPC >> $vpcs_file
  }

trap write_vpc_to_file EXIT

## Create a VPC
Create_VPC
if
  [[ ! -z $AWS_VPC_ID ]]
then
echo "myvpc successfuly created and have "$AWS_VPC_ID" ID" | tee ./myvpc.log
else
echo "myvpc not created due to error" | tee ./error.log
exit
fi

## Enable DNS hostname for your VPC
Enable_DNS_hostname
if [[ $? != 0 ]]
then
delete_vpc
echo "myvpc "$AWS_VPC_ID" deleted due to error with enabling DNS hostname on myvpc" | tee ./error.log
exit
else
echo "On "$AWS_VPC_ID" enabled DNS hostname" | tee -a ./myvpc.log
fi

## Create a public subnet
Create_subnet
if [[ ! -z $AWS_SUBNET_PUBLIC_ID ]]
then
echo "Public Subnet for "$AWS_VPC_ID" successfully created and have "$AWS_SUBNET_PUBLIC_ID "ID" | tee -a ./myvpc.log
else
delete_modified_vpc
echo "myvpc "$AWS_VPC_ID" deleted due to error with creating Custom Public Subnet" | tee ./error.log
exit
fi

## Enable Auto-assign Public IP on Public Subnet
Auto_assign_Public_IP_on_Public_Subnet
if [[ $? != 0 ]]
then
delete_subnet
echo "Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc "$AWS_VPC_ID" deleted due to error with Auto-assigning Public IP on Public Subnet" | tee ./error.log
exit
else
echo "Auto-assign Public ip on Public Subnet "$AWS_SUBNET_PUBLIC_ID" is successful" | tee -a ./myvpc.log
fi

## Create an Internet Gateway
Create_Internet_Gateway
if
  [[ ! -z $AWS_INTERNET_GATEWAY_ID ]]
then
echo "Internet Gateway successfully created and have "$AWS_INTERNET_GATEWAY_ID "ID" | tee -a ./myvpc.log
else
delete_subnet
echo "Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc "$AWS_VPC_ID" deleted due to error with creating Internet Gateway" | tee ./error.log
exit
fi

## Attach Internet gateway to your VPC
Attach_Internet_gateway_to_VPC
if [[ $? != 0 ]]
then
delete_internet_gateway
echo "Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc "$AWS_VPC_ID" are deleted due to error with attaching Internet Gateway to myvpc" | tee ./error.log
exit
else
echo "Internet Gateway "$AWS_INTERNET_GATEWAY_ID" successfully attached to "$AWS_VPC_ID "VPC" | tee -a ./myvpc.log
fi

## Add a ID to the default route table
Add_ID_to_default_route_table
if
  [[ ! -z $AWS_DEFAULT_ROUTE_TABLE_ID ]]
then
echo "Default Route Table ID is "$AWS_DEFAULT_ROUTE_TABLE_ID | tee -a ./myvpc.log
else
delete_internet_gateway
echo "Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc "$AWS_VPC_ID" are deleted due to error with getting Default Route Table id" | tee ./error.log
exit
fi

## Create a route table
Create_route_table
if
  [[ ! -z $AWS_CUSTOM_ROUTE_TABLE_ID ]]
then
echo "Custom Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" successfully created" | tee -a ./myvpc.log
else
delete_internet_gateway
echo "Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc "$AWS_VPC_ID" are deleted due to error with creatingroute table" | tee ./error.log
exit
fi

## Create route to Internet Gateway
Create_route_to_Internet_Gateway
if [[ $? != 0 ]]
then
delete_route_table
cho "Custom Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID "are deleted due to error with creating route from "$AWS_CUSTOM_ROUTE_TABLE_ID "to Internet Gateway "$AWS_INTERNET_GATEWAY_ID | tee ./error.log
exit
else
echo "Created route from Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID "to" $AWS_INTERNET_GATEWAY_ID "Internet Gateway" | tee -a ./myvpc.log
fi

## Associate the public subnet with route table
Associate_public_subnet_with_route_table
if
  [[ ! -z $AWS_ROUTE_TABLE_ASSOID ]]
then
echo "Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" associated to "$AWS_SUBNET_PUBLIC_ID" Public Subnet" | tee -a ./myvpc.log
else
delete_route_table
echo "Custom Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID "are deleted due to error with associating Custom Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID "to "$AWS_SUBNET_PUBLIC_ID "Public Subnet" | tee ./error.log
exit
fi

## Create a security group
Create_security_group
if [[ $? != 0 ]]
then
delete_associated_route_table
echo "Custom Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID "are deleted due to error with creating Custom Security Group" | tee ./error.log
exit
else
echo "Security Group for" $AWS_VPC_ID "successfuly created" | tee -a ./myvpc.log
fi

## Get custom security group ID's
Describe_Security_Group_id
if
  [[ ! -z $AWS_CUSTOM_SECURITY_GROUP_ID ]]
then
echo "Custom Security Group has "$AWS_CUSTOM_SECURITY_GROUP_ID" ID" | tee -a ./myvpc.log
else
delete_custom_security_group
echo "Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID "are deleted due to error with creating Custom Security Group ID" | tee ./error.log
exit
fi

## Get default security group ID's
Get_Security_Group_id
if
  [[ ! -z $AWS_DEFAULT_SECURITY_GROUP_ID ]]
then
echo "Default Security Group has "$AWS_DEFAULT_SECURITY_GROUP_ID" ID" | tee -a ./myvpc.log
else
delete_custom_security_group
echo "Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID "are deleted due to error with creating Default Security Group ID" | tee ./error.log
exit
fi

## Create security group ssh rule
Create_security_group_ssh_rule
if
  [[ ! -z $AWS_CUSTOM_SECURITY_GROUP_SSH_RULE_ID ]]
then
echo "Added ssh rule to "$AWS_CUSTOM_SECURITY_GROUP_ID" Security Group" | tee -a ./myvpc.log
else
delete_custom_security_group
echo "Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID "are deleted due to error with creating Custom Security Group ssh rule" | tee ./error.log
exit
fi

## Create security group http rule
Create_security_group_http_rule
if 
  [[ ! -z $AWS_CUSTOM_SECURITY_GROUP_HTTP_RULE_ID ]]
then
echo "Added http rule to "$AWS_CUSTOM_SECURITY_GROUP_ID" Security Group" | tee -a ./myvpc.log
else
delete_custom_security_group
echo "Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID "are deleted due to error with creating Custom Security Group http rule" | tee ./error.log
exit
fi

## Create security group https rule
Create_security_group_https_rule
if 
  [[ ! -z $AWS_CUSTOM_SECURITY_GROUP_HTTPS_RULE_ID ]]
then
echo "Added https rule to "$AWS_CUSTOM_SECURITY_GROUP_ID" Security Group" | tee -a ./myvpc.log
else
delete_custom_security_group && \
echo "Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID", Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID", Internet Gateway "$AWS_INTERNET_GATEWAY_ID", Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2" and myvpc " $AWS_VPC_ID "are deleted due to error with creating Custom Security Group https rule" | tee ./error.log
exit
fi

## Create AWS S3 Bucket
Create_AWS_S3_Bucket
if
  [[ ! -z $AWS_S3 ]]
then
echo "S3 successfuly created and have "$AWS_S3" name" | tee -a ./myvpc.log
else
delete_custom_security_group
echo "All resources are deleted du to error creating S3 bucket" | tee ./error.log
exit
fi

## making index.html and nginx.conf files
making_index_html_file
making_nginx_https_conf_file
if [[ -f ./index.html ]] && [[ -f ./nginx_https.conf ]]
then
echo "Nginx files are created and located in current directory"
else
delete_S3
echo "All recorces deleted due to error creating nginx files" | tee ./error.log
exit
fi

## uploading files to s3 bucket
Upload_html_to_bucket
Upload_nginx_https_conf_to_bucket
aws s3api wait object-exists \
--bucket $AWS_S3 \
--key index.html \
--key nginx_https.conf
S3_file_count=$(aws s3 ls s3://$AWS_S3 | wc -l)
if [[ $S3_file_count = 2 ]]
then
echo "Nginx files uploaded to s3 bucket successfully"
else
delete_S3
echo "Nginx files upload to s3 bucket failed S3 bucket and myvpc are deleted" | tee ./error.log
exit
fi

## Checking Read access to s3 bucket files
index_check=$(aws s3api get-object-acl --bucket $AWS_S3 --key index.html --output text | grep -i read | cut -c8-12)
index_check_2=$(aws s3api get-object-acl --bucket $AWS_S3 --key index.html --output text | grep -i group | cut -c40-60)
nginx_check=$(aws s3api get-object-acl --bucket $AWS_S3 --key nginx_https.conf --output text | grep -i read | cut -c8-12)
nginx_check_2=$(aws s3api get-object-acl --bucket $AWS_S3 --key nginx_https.conf --output text | grep -i group | cut -c40-60)
if [[ "$index_check" == "READ" ]] && [[ "$index_check_2" == "groups/global/AllUser" ]] && \
   [[ "$nginx_check" == "READ" ]] && [[ "$nginx_check_2" == "groups/global/AllUser" ]]
then
echo "Nginx files are public"
else
delete_S3
echo "Files in S3 bucket are not public S3 bucket and myvpc are deleted" | tee ./error.log
exit
fi

## Create a key-pair
Create_key_pair
if
  [[ -f ./myvpc-ec2-keypair.pem ]]
then
chmod 400 myvpc-ec2-keypair.pem
echo "Security key-pair for Amazon Linux instance successfuly created and located in current directory with name myvpc-ec2-keypair.pem" | tee -a ./myvpc.log
else
delete_S3
echo "Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID "are deleted due to error with creating security key-pair" | tee ./error.log
exit
fi

## Create an EC2 instance
Create_EC2_instance
if
  [[ ! -z $AWS_EC2_INSTANCE_ID ]]
then
echo "EC2 instance successfuly created and have "$AWS_EC2_INSTANCE_ID" ID" | tee -a ./myvpc.log
else
delete_key_pair
echo "myvpc-ec2-keypair deleted from AWS and localhost, Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID" are deleted due to error creating EC2 instance" | tee ./error.log
exit
fi

## Get the public ip address of your instance
Get_public_ip_address_of_instance
if
  [[ ! -z $AWS_EC2_INSTANCE_PUBLIC_IP ]]
then
echo "The Amazon Linux 2 Instance "$AWS_EC2_INSTANCE_ID" has Public ip adress "$AWS_EC2_INSTANCE_PUBLIC_IP | tee -a ./myvpc.log
else
terminate_instance
echo "EC2 instance" $AWS_EC2_INSTANCE_ID" and myvpc-ec2-keypair deleted from AWS and localhost, Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID" are deleted due to error getting EC2 instance Public ip adress" | tee ./error.log
exit
fi

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

echo "Added Tags to Created Resources"

## Create s3fullaccess iam user
create_myvpcs3user
if  [[ ! -z $ACCESS_KEY_ID ]]
then
echo "$ACCESS_KEY_ID:$SECRET_ACCESS_KEY" > ec2/.passwd-s3fs && \
echo "IAM s3 user $AWS_IAM_S3_USER successfuly created with Credentials and s3fullaccess" | tee -a ./myvpc.log
else
delete_myvpcs3user && \
echo "IAM s3 user not created"  | tee ./error.log
fi

## Making A Record for Hosted DNS Zone
make_A_record_create_file && make_hosted_zone_id && add_A_record
if [[ -f ./create_A_record.json ]] && [[ ! -z $HOSTED_ZONE_CHANGE_ID ]]
then
echo "DNS A Record $HOSTED_ZONE_CHANGE_ID added to AWS Route53 Hosted Zone" | tee -a ./myvpc.log
else
delete_myvpcs3user && \
rm -f create_A_record.json delete_A_Record.json && \
echo "Adding DNS A Record to AWS Route53 Hosted Zone failed"  | tee ./error.log
fi

## Copying files from ec2 directory to instance and executing run.sh from instance
ssh-keyscan $AWS_EC2_INSTANCE_PUBLIC_IP >> ~/.ssh/known_hosts
scp -i myvpc-ec2-keypair.pem ec2/refresh_index.sh ubuntu@$AWS_EC2_INSTANCE_PUBLIC_IP:~
scp -i myvpc-ec2-keypair.pem ec2/run.sh ubuntu@$AWS_EC2_INSTANCE_PUBLIC_IP:~
scp -i myvpc-ec2-keypair.pem ec2/.passwd-s3fs ubuntu@$AWS_EC2_INSTANCE_PUBLIC_IP:~
ssh -i myvpc-ec2-keypair.pem ubuntu@$AWS_EC2_INSTANCE_PUBLIC_IP './run.sh'
