#!/bin/bash

source ./functions.sh

write_vpc_to_file ()
  {
echo $AWS_VPC >> $vpcs_file
  }

trap write_vpc_to_file EXIT

## Create a VPC
Create_VPC && tag_VPC
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
delete_vpc && \
echo "myvpc "$AWS_VPC_ID" deleted due to error with enabling DNS hostname on myvpc" | tee ./error.log
exit
else
echo "On "$AWS_VPC_ID" enabled DNS hostname" | tee -a ./myvpc.log
fi

## Create a public subnet 1
Create_subnet_1 && tag_public_subnet_1
if [[ ! -z $AWS_SUBNET_PUBLIC_ID_1 ]]
then
echo "Public Subnet for "$AWS_VPC_ID" successfully created and have "$AWS_SUBNET_PUBLIC_ID_1 "ID" | tee -a ./myvpc.log
else
delete_modified_vpc && \
echo "myvpc "$AWS_VPC_ID" deleted due to error with creating Custom Public Subnet_1" | tee ./error.log
exit
fi

## Create a public subnet 2
Create_subnet_2 && tag_public_subnet_2
if [[ ! -z $AWS_SUBNET_PUBLIC_ID_2 ]]
then
echo "Public Subnet for "$AWS_VPC_ID" successfully created and have "$AWS_SUBNET_PUBLIC_ID_2 "ID" | tee -a ./myvpc.log
else
delete_modified_vpc && \
echo "myvpc "$AWS_VPC_ID" and "$AWS_SUBNET_PUBLIC_ID_1" are deleted due to error with creating Custom Public Subnet_2" | tee ./error.log
exit
fi

## Enable Auto-assign Public IP on Public Subnet 1
Auto_assign_Public_IP_Public_Subnet_1
if [[ $? != 0 ]]
then
delete_subnet_1 && \
echo "Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2" and myvpc "$AWS_VPC_ID" are deleted due to error with Auto-assigning Public IP on Public Subnet_1" | tee ./error.log
exit
else
echo "Auto-assign Public ip on Public Subnet_1 "$AWS_SUBNET_PUBLIC_ID_1" is successful" | tee -a ./myvpc.log
fi

## Enable Auto-assign Public IP on Public Subnet 2
Auto_assign_Public_IP_Public_Subnet_2
if [[ $? != 0 ]]
then
delete_subnet_2 && \
echo "Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2" and myvpc "$AWS_VPC_ID" deleted due to error with Auto-assigning Public IP on Public Subnet_2" | tee ./error.log
exit
else
echo "Auto-assign Public ip on Public Subnet_2 "$AWS_SUBNET_PUBLIC_ID_2" is successful" | tee -a ./myvpc.log
fi

## Create an Internet Gateway
Create_Internet_Gateway && tag_Internet-Gateway
if
  [[ ! -z $AWS_INTERNET_GATEWAY_ID ]]
then
echo "Internet Gateway successfully created and have "$AWS_INTERNET_GATEWAY_ID "ID" | tee -a ./myvpc.log
else
delete_subnet_2 && \
echo "Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2" and myvpc "$AWS_VPC_ID" deleted due to error with creating Internet Gateway" | tee ./error.log
exit
fi

## Attach Internet gateway to your VPC
Attach_Internet_gateway_to_VPC
if [[ $? != 0 ]]
then
delete_internet_gateway && \
echo "Internet Gateway "$AWS_INTERNET_GATEWAY_ID", Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2" and myvpc "$AWS_VPC_ID" are deleted due to error with attaching Internet Gateway to myvpc" | tee ./error.log
exit
else
echo "Internet Gateway "$AWS_INTERNET_GATEWAY_ID" successfully attached to "$AWS_VPC_ID "VPC" | tee -a ./myvpc.log
fi

## Add a ID to the default route table
Add_ID_to_default_route_table && tag_default_route_table
if
  [[ ! -z $AWS_DEFAULT_ROUTE_TABLE_ID ]]
then
echo "Default Route Table ID is "$AWS_DEFAULT_ROUTE_TABLE_ID | tee -a ./myvpc.log
else
delete_internet_gateway && \
echo "Internet Gateway "$AWS_INTERNET_GATEWAY_ID", Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2" and myvpc "$AWS_VPC_ID" are deleted due to error with getting Default Route Table id" | tee ./error.log
exit
fi

## Create a route table
Create_custom_route_table && tag_custom_route_table
if
  [[ ! -z $AWS_CUSTOM_ROUTE_TABLE_ID ]]
then
echo "Custom Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" successfully created" | tee -a ./myvpc.log
else
delete_internet_gateway && \
echo "Internet Gateway "$AWS_INTERNET_GATEWAY_ID", Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2" and myvpc "$AWS_VPC_ID" are deleted due to error with creatingroute table" | tee ./error.log
exit
fi

## Create route to Internet Gateway
Create_route_to_Internet_Gateway
if [[ $? != 0 ]]
then
delete_custom_route_table && \
echo "Custom Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID", Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2 "and myvpc " $AWS_VPC_ID "are deleted due to error with creating route from "$AWS_CUSTOM_ROUTE_TABLE_ID "to Internet Gateway "$AWS_INTERNET_GATEWAY_ID | tee ./error.log
exit
else
echo "Created route from Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID "to" $AWS_INTERNET_GATEWAY_ID "Internet Gateway" | tee -a ./myvpc.log
fi

## Associate the public subnet 1 with route table
Associate_public_subnet_1_with_route_table
if
  [[ ! -z $AWS_ROUTE_TABLE_ASSOID_1 ]]
then
echo "Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" associated to "$AWS_SUBNET_PUBLIC_ID_1" Public Subnet" | tee -a ./myvpc.log
else
delete_custom_route_table && \
echo "Custom Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID", Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2 "and myvpc " $AWS_VPC_ID "are deleted due to error with associating Custom Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID "to "$AWS_SUBNET_PUBLIC_ID "Public Subnet_1" | tee ./error.log
exit
fi

## Associate the public subnet 1 with route table
Associate_public_subnet_2_with_route_table
if
  [[ ! -z $AWS_ROUTE_TABLE_ASSOID_2 ]]
then
echo "Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" associated to "$AWS_SUBNET_PUBLIC_ID_2" Public Subnet" | tee -a ./myvpc.log
else
delete_custom_route_table && \
echo "Custom Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2" and myvpc " $AWS_VPC_ID "are deleted due to error with associating Custom Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID "to "$AWS_SUBNET_PUBLIC_ID "Public Subnet_2" | tee ./error.log
exit
fi

## Create a security group
Create_custom_security_group
if [[ $? != 0 ]]
then
delete_associated_route_table_2 && \
echo "Custom Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2"  and myvpc " $AWS_VPC_ID "are deleted due to error with creating Custom Security Group" | tee ./error.log
exit
else
echo "Custom Security Group for" $AWS_VPC_ID "successfuly created" | tee -a ./myvpc.log
fi

## Get custom security group ID's
Describe_custom_security_Group_id && tag_custom_security_group
if
  [[ ! -z $AWS_CUSTOM_SECURITY_GROUP_ID ]]
then
echo "Custom Security Group has "$AWS_CUSTOM_SECURITY_GROUP_ID" ID" | tee -a ./myvpc.log
else
delete_custom_security_group && \
echo "Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID", Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID", Internet Gateway "$AWS_INTERNET_GATEWAY_ID", Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2" and myvpc " $AWS_VPC_ID "are deleted due to error with getting Custom Security Group ID" | tee ./error.log
exit
fi

## Get default security group ID's
Get_default_security_Group_id && tag_default_security_group
if
  [[ ! -z $AWS_DEFAULT_SECURITY_GROUP_ID ]]
then
echo "Default Security Group has "$AWS_DEFAULT_SECURITY_GROUP_ID" ID" | tee -a ./myvpc.log
else
delete_custom_security_group && \
echo "Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID", Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID", Internet Gateway "$AWS_INTERNET_GATEWAY_ID", Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2" and myvpc " $AWS_VPC_ID "are deleted due to error with getting Default Security Group ID" | tee ./error.log
exit
fi

## Create security group ssh rule
Create_security_group_ssh_rule
if
  [[ ! -z $AWS_CUSTOM_SECURITY_GROUP_SSH_RULE_ID ]]
then
echo "Added ssh rule to "$AWS_CUSTOM_SECURITY_GROUP_ID" Security Group" | tee -a ./myvpc.log
else
delete_custom_security_group && \
echo "Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID", Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID", Internet Gateway "$AWS_INTERNET_GATEWAY_ID", Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2" and myvpc " $AWS_VPC_ID "are deleted due to error with creating Custom Security Group ssh rule" | tee ./error.log
exit
fi

## Create security group http rule
Create_security_group_http_rule
if 
  [[ ! -z $AWS_CUSTOM_SECURITY_GROUP_HTTP_RULE_ID ]]
then
echo "Added http rule to "$AWS_CUSTOM_SECURITY_GROUP_ID" Security Group" | tee -a ./myvpc.log
else
delete_custom_security_group && \
echo "Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID", Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID", Internet Gateway "$AWS_INTERNET_GATEWAY_ID", Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2" and myvpc " $AWS_VPC_ID "are deleted due to error with creating Custom Security Group http rule" | tee ./error.log
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
delete_custom_security_group && \
echo "Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID", Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID", Internet Gateway "$AWS_INTERNET_GATEWAY_ID", Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2" and myvpc " $AWS_VPC_ID "are deleted due to error with creating s3 bucket" | tee ./error.log
exit
fi

## making index.html and nginx.conf files
making_index_html_file && making_nginx_conf_file
if [[ -f ./index.html ]] && [[ -f ./nginx.conf ]]
then
echo "Nginx files are created and located in current directory"
else
delete_S3 && \
echo "S3 bucket "$AWS_S3", Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID", Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID", Internet Gateway "$AWS_INTERNET_GATEWAY_ID", Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2" and myvpc " $AWS_VPC_ID "are deleted due to error with creating s3 bucket" | tee ./error.log
exit
fi

## uploading files to s3 bucket
Upload_html_to_bucket && Upload_nginx_conf_to_bucket
aws s3api wait object-exists \
--bucket $AWS_S3 \
--key index.html \
--key nginx.conf
S3_file_count=$(aws s3 ls s3://$AWS_S3 | wc -l)
if [[ $S3_file_count = 2 ]]
then
echo "Nginx files uploaded to s3 bucket $AWS_S3 successfully"
else
delete_S3 && \
echo "S3 bucket "$AWS_S3", Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID", Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID", Internet Gateway "$AWS_INTERNET_GATEWAY_ID", Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2" and myvpc " $AWS_VPC_ID "are deleted due to error with uploading files to s3 bucket" | tee ./error.log
exit
fi

## Checking Read access to s3 bucket files
index_check=$(aws s3api get-object-acl --bucket $AWS_S3 --key index.html --output text | grep -i read | cut -c8-12)
index_check_2=$(aws s3api get-object-acl --bucket $AWS_S3 --key index.html --output text | grep -i group | cut -c40-60)
nginx_check=$(aws s3api get-object-acl --bucket $AWS_S3 --key nginx.conf --output text | grep -i read | cut -c8-12)
nginx_check_2=$(aws s3api get-object-acl --bucket $AWS_S3 --key nginx.conf --output text | grep -i group | cut -c40-60)
if [[ "$index_check" == "READ" ]] && [[ "$index_check_2" == "groups/global/AllUser" ]] && \
   [[ "$nginx_check" == "READ" ]] && [[ "$nginx_check_2" == "groups/global/AllUser" ]]
then
echo "Nginx files are public"
else
delete_S3 && \
echo "Files in S3 bucket are not public - S3 bucket "$AWS_S3", Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID", Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID", Internet Gateway "$AWS_INTERNET_GATEWAY_ID", Public Subnets "$AWS_SUBNET_PUBLIC_ID_1", "$AWS_SUBNET_PUBLIC_ID_2" and myvpc " $AWS_VPC_ID "are deleted" | tee ./error.log
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
delete_S3 && \
echo "S3 bucket "$AWS_S3", Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID "are deleted due to error with creating security key-pair" | tee ./error.log
exit
fi

## Create an EC2 instance_1
Create_EC2_instance_1 && tag_ec2_instance_1
if
  [[ ! -z $AWS_EC2_INSTANCE_ID_1 ]]
then
echo "EC2 instance_1 successfuly created and have "$AWS_EC2_INSTANCE_ID_1" ID" | tee -a ./myvpc.log
else
delete_key_pair && \
echo "myvpc-ec2-keypair deleted from AWS and localhost, S3 bucket "$AWS_S3", Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID " are deleted due to error creating EC2 instance" | tee ./error.log
exit
fi

## Create an EC2 instance_2
Create_EC2_instance_2 && tag_ec2_instance_2
if
  [[ ! -z $AWS_EC2_INSTANCE_ID_2 ]]
then
echo "EC2 instance_2 successfuly created and have "$AWS_EC2_INSTANCE_ID_2" ID" | tee -a ./myvpc.log
else
terminate_instance_1 && \
echo "EC2 instance_1 "$AWS_EC2_INSTANCE_ID_1", myvpc-ec2-keypair from AWS and localhost, S3 bucket "$AWS_S3", Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID" are deleted due to error creating EC2 instance_2" | tee ./error.log
exit
fi

## Get the public ip address of your instance_1
Get_public_ip_address_of_instance_1
if
  [[ ! -z $AWS_EC2_INSTANCE_PUBLIC_IP_1 ]]
then
echo "The Amazon Linux 2 Instance_1 "$AWS_EC2_INSTANCE_ID_1" has Public ip adress "$AWS_EC2_INSTANCE_PUBLIC_IP_1 | tee -a ./myvpc.log
else
terminate_instance_2 && \
echo "EC2 instance_1" $AWS_EC2_INSTANCE_ID_1", EC2 instance_2" $AWS_EC2_INSTANCE_ID_2", S3 bucket "$AWS_S3", myvpc-ec2-keypair from AWS and localhost, Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID" are deleted due to error getting EC2 instance_1 Public ip adress" | tee ./error.log
exit
fi

## Get the public ip address of your instance_2
Get_public_ip_address_of_instance_2
if
  [[ ! -z $AWS_EC2_INSTANCE_PUBLIC_IP_2 ]]
then
echo "The Amazon Linux 2 Instance_2 "$AWS_EC2_INSTANCE_ID_2" has Public ip adress "$AWS_EC2_INSTANCE_PUBLIC_IP_2 | tee -a ./myvpc.log
else
terminate_instance_2 && \
echo "EC2 instance_1" $AWS_EC2_INSTANCE_ID_1", EC2 instance_2" $AWS_EC2_INSTANCE_ID_2", S3 bucket "$AWS_S3", myvpc-ec2-keypair from AWS and localhost, Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID" are deleted due to error getting EC2 instance_2 Public ip adress" | tee ./error.log
exit
fi

## Create s3fullaccess iam user
create_myvpcs3user
if  [[ ! -z $ACCESS_KEY_ID ]]
then
echo "$ACCESS_KEY_ID:$SECRET_ACCESS_KEY" > ec2/.passwd-s3fs && \
echo "IAM s3 user successfuly created with Credentials and s3fullaccess" | tee -a ./myvpc.log
else
terminate_instance_2 && \
echo "EC2 instance_1" $AWS_EC2_INSTANCE_ID_1", EC2 instance_2" $AWS_EC2_INSTANCE_ID_2", S3 bucket "$AWS_S3", myvpc-ec2-keypair from AWS and localhost, Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID" are deleted due to error with creating s3 Full Access user" | tee ./error.log
exit
fi

## Copying files from localhost "ec2" directory to instance_1 and executing run.sh from instance_1
ssh-keyscan $AWS_EC2_INSTANCE_PUBLIC_IP_1 >> ~/.ssh/known_hosts
scp -i myvpc-ec2-keypair.pem ec2/refresh_index.sh ubuntu@$AWS_EC2_INSTANCE_PUBLIC_IP_1:~
scp -i myvpc-ec2-keypair.pem ec2/run.sh ubuntu@$AWS_EC2_INSTANCE_PUBLIC_IP_1:~
scp -i myvpc-ec2-keypair.pem ec2/.passwd-s3fs ubuntu@$AWS_EC2_INSTANCE_PUBLIC_IP_1:~
ssh -i myvpc-ec2-keypair.pem ubuntu@$AWS_EC2_INSTANCE_PUBLIC_IP_1 './run.sh'

## Copying files from localhost "ec2" directory to instance_2 and executing run.sh from instance_2
ssh-keyscan $AWS_EC2_INSTANCE_PUBLIC_IP_2 >> ~/.ssh/known_hosts
scp -i myvpc-ec2-keypair.pem ec2/refresh_index.sh ubuntu@$AWS_EC2_INSTANCE_PUBLIC_IP_2:~
scp -i myvpc-ec2-keypair.pem ec2/run.sh ubuntu@$AWS_EC2_INSTANCE_PUBLIC_IP_2:~
scp -i myvpc-ec2-keypair.pem ec2/.passwd-s3fs ubuntu@$AWS_EC2_INSTANCE_PUBLIC_IP_2:~
ssh -i myvpc-ec2-keypair.pem ubuntu@$AWS_EC2_INSTANCE_PUBLIC_IP_2 './run.sh'

## Create application load balancer ##
create_alb
if  [[ ! -z $AWS_ALB_ARN ]]
then
echo "ALB $AWS_ALB_ARN successfuly created" | tee -a ./myvpc.log
else
delete_myvpcs3user && \
echo "aws iam create-user" $AWS_IAM_S3_USER" with access key id "$ACCESS_KEY_ID", EC2 instance_1" $AWS_EC2_INSTANCE_ID_1", EC2 instance_2" $AWS_EC2_INSTANCE_ID_2", S3 bucket "$AWS_S3", myvpc-ec2-keypair from AWS and localhost, Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID" are deleted due to error with creating Aplication Load Balancer" | tee ./error.log
exit
fi

## Create the http target group for your ALB
create_alb_http_target_group
if  [[ ! -z $AWS_ALB_HTTP_TARGET_GROUP_ARN ]]
then
echo "HTTP Target Group $AWS_ALB_HTTP_TARGET_GROUP_ARN successfuly created"  | tee -a ./myvpc.log
else
delete_Application_Load_Balancer && \
echo "Aplication Load Balancer" $AWS_ALB_ARN" aws iam create-user" $AWS_IAM_S3_USER" with access key id "$ACCESS_KEY_ID", EC2 instance_1" $AWS_EC2_INSTANCE_ID_1", EC2 instance_2" $AWS_EC2_INSTANCE_ID_2", S3 bucket "$AWS_S3", myvpc-ec2-keypair from AWS and localhost, Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID" are deleted due to error creating target group for Aplication Load Balancer" | tee ./error.log
exit
fi

## Register both the instances in the http target group
register_instances_in_http_target_group
if [[ $? = 0 ]]
then
echo "EC2 instance_1" $AWS_EC2_INSTANCE_ID_1" and EC2 instance_2" $AWS_EC2_INSTANCE_ID_2" are registered in "$AWS_ALB_TARGET_GROUP_ARN" http target group"  | tee -a ./myvpc.log
else
delete_http_target_group && \
echo "HTTP Target Group "$AWS_ALB_HTTP_TARGET_GROUP_ARN", Aplication Load Balancer" $AWS_ALB_ARN" aws iam create-user" $AWS_IAM_S3_USER" with access key id "$ACCESS_KEY_ID", EC2 instance_1" $AWS_EC2_INSTANCE_ID_1", EC2 instance_2" $AWS_EC2_INSTANCE_ID_2", S3 bucket "$AWS_S3", myvpc-ec2-keypair from AWS and localhost, Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID" are deleted due to error with registering instances in HTTP Target Group" | tee ./error.log
exit
fi

## Create a http listener for load balancer with a default rule that forwards requests to HTTP target group
create_alb_http_listener_forward_to_target_group_rule
if  [[ ! -z $AWS_ALB_HTTP_LISTNER_ARN ]]
then
echo "HTTP Listener $AWS_ALB_HTTP_LISTNER_ARN for Load Balancer with forwards request to HTTP target group rule are successfuly created" | tee -a ./myvpc.log
else
deregister_http_targets && \
echo "HTTP Target Group "$AWS_ALB_HTTP_TARGET_GROUP_ARN", Aplication Load Balancer" $AWS_ALB_ARN" aws iam create-user" $AWS_IAM_S3_USER" with access key id "$ACCESS_KEY_ID", EC2 instance_1" $AWS_EC2_INSTANCE_ID_1", EC2 instance_2" $AWS_EC2_INSTANCE_ID_2", S3 bucket "$AWS_S3", myvpc-ec2-keypair from AWS and localhost, Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID" are deleted due to error with creating ALB HTTP Listener" | tee ./error.log
exit
fi

## Create the https target group for your ALB
create_alb_https_target_group
if  [[ ! -z $AWS_ALB_HTTPS_TARGET_GROUP_ARN ]]
then
echo "HTTPS Target Group $AWS_ALB_HTTPS_TARGET_GROUP_ARN successfuly created"  | tee -a ./myvpc.log
else
delete_http_listener && \
echo "HTTP Listener "$AWS_ALB_HTTP_LISTNER_ARN", HTTP Target Group "$AWS_ALB_HTTP_TARGET_GROUP_ARN", Aplication Load Balancer" $AWS_ALB_ARN" aws iam create-user" $AWS_IAM_S3_USER" with access key id "$ACCESS_KEY_ID", EC2 instance_1" $AWS_EC2_INSTANCE_ID_1", EC2 instance_2" $AWS_EC2_INSTANCE_ID_2", S3 bucket "$AWS_S3", myvpc-ec2-keypair from AWS and localhost, Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID" are deleted due to error creating ALB HTTPS Target Group" | tee ./error.log
exit
fi

## Register both the instances in the https target group
register_instances_in_https_target_group
if [[ $? = 0 ]]
then
echo "EC2 instance_1" $AWS_EC2_INSTANCE_ID_1" and EC2 instance_2" $AWS_EC2_INSTANCE_ID_2" are registered in "$AWS_ALB_HTTPS_TARGET_GROUP_ARN" https target group" | tee -a ./myvpc.log
else
delete_https_target_group && \
echo "HTTPS Target Group "$AWS_ALB_HTTPS_TARGET_GROUP_ARN", HTTP Listener "$AWS_ALB_HTTP_LISTNER_ARN", HTTP Target Group "$AWS_ALB_HTTP_TARGET_GROUP_ARN", Aplication Load Balancer" $AWS_ALB_ARN" aws iam create-user" $AWS_IAM_S3_USER" with access key id "$ACCESS_KEY_ID", EC2 instance_1" $AWS_EC2_INSTANCE_ID_1", EC2 instance_2" $AWS_EC2_INSTANCE_ID_2", S3 bucket "$AWS_S3", myvpc-ec2-keypair from AWS and localhost, Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID" are deleted due to error with registering instances in HTTPS TArget Group" | tee ./error.log
exit
fi
## Create a https listener for load balancer with a default rule that forwards requests to HTTPS target group
create_alb_https_listener_forward_to_target_group_rule
if  [[ ! -z $AWS_ALB_HTTPS_LISTNER_ARN ]]
then
echo "HTTPS Listener $AWS_ALB_HTTPS_LISTNER_ARN for Load Balancer with forwards request to HTTPS target group rule are successfuly created" | tee -a ./myvpc.log
else
deregister_https_targets && \
echo "HTTPS Target Group "$AWS_ALB_HTTPS_TARGET_GROUP_ARN", HTTP Listener "$AWS_ALB_HTTP_LISTNER_ARN", HTTP Target Group "$AWS_ALB_HTTP_TARGET_GROUP_ARN", Aplication Load Balancer" $AWS_ALB_ARN" aws iam create-user" $AWS_IAM_S3_USER" with access key id "$ACCESS_KEY_ID", EC2 instance_1" $AWS_EC2_INSTANCE_ID_1", EC2 instance_2" $AWS_EC2_INSTANCE_ID_2", S3 bucket "$AWS_S3", myvpc-ec2-keypair from AWS and localhost, Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID" are deleted due to error with creating ALB HTTPS Listener" | tee ./error.log
exit
fi

##Get Aplication Load Balancer DNS name
get_alb_dns
if  [[ $? = 0 ]]
then
echo "Aplication Load Balanser DNS is "$AWS_ALB_DNS | tee -a ./myvpc.log
else
delete_https_listener && \
echo "HTTPS Target Group "$AWS_ALB_HTTPS_TARGET_GROUP_ARN", HTTP Listener "$AWS_ALB_HTTP_LISTNER_ARN", HTTP Target Group "$AWS_ALB_HTTP_TARGET_GROUP_ARN", Aplication Load Balancer" $AWS_ALB_ARN" aws iam create-user" $AWS_IAM_S3_USER" with access key id "$ACCESS_KEY_ID", EC2 instance_1" $AWS_EC2_INSTANCE_ID_1", EC2 instance_2" $AWS_EC2_INSTANCE_ID_2", S3 bucket "$AWS_S3", myvpc-ec2-keypair from AWS and localhost, Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID" are deleted due to error getting ALB DNS Name" | tee ./error.log
exit
fi

## Making A Record for ALB in Hosted DNS Zone
make_hosted_zone_id && make_ALB_alias_record_file && add_ALB_alias_record
if [[ -f ./create_ALB_alias_record.json ]] && [[ ! -z $HOSTED_ZONE_ALB_CHANGE_ID ]]
then
echo "DNS A Record $HOSTED_ZONE_ALB_CHANGE_ID for ALB added to AWS Route53 Hosted Zone" | tee -a ./myvpc.log
else
delete_https_listener && rm -f ./create_ALB_alias_record.json && \
echo "HTTPS Target Group "$AWS_ALB_HTTPS_TARGET_GROUP_ARN", HTTP Listener "$AWS_ALB_HTTP_LISTNER_ARN", HTTP Target Group "$AWS_ALB_HTTP_TARGET_GROUP_ARN", Aplication Load Balancer" $AWS_ALB_ARN" aws iam create-user" $AWS_IAM_S3_USER" with access key id "$ACCESS_KEY_ID", EC2 instance_1" $AWS_EC2_INSTANCE_ID_1", EC2 instance_2" $AWS_EC2_INSTANCE_ID_2", S3 bucket "$AWS_S3", myvpc-ec2-keypair from AWS and localhost, Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" Internet Gateway "$AWS_INTERNET_GATEWAY_ID" Public Subnet "$AWS_SUBNET_PUBLIC_ID" and myvpc " $AWS_VPC_ID" are deleted due to error with creating DNS A Record for ALB" | tee ./error.log
exit
fi
