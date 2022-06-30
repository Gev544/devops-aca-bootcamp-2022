#!/bin/bash

vpcs_file="myvpc.txt"
myvpc_cidr_block="10.0.0.0/16"
public_subnet_cidr_block="10.0.1.0/24"
availability_zone="us-east-1a"
destination_cidr_block="0.0.0.0/0"
myvpc_security_group="myvpc-security-group"
region="us-east-1"
instance_private_ip_address="10.0.1.10"
AWS_IAM_S3_USER="myvpcs3user"


### Create Functions ###

Create_VPC ()
  {
AWS_VPC_ID=$(aws ec2 create-vpc \
--cidr-block $myvpc_cidr_block \
--query 'Vpc.{VpcId:VpcId}' \
--output text)
AWS_VPC="$AWS_VPC_ID"
  }

Enable_DNS_hostname ()
  {
aws ec2 modify-vpc-attribute \
--vpc-id $AWS_VPC_ID \
--enable-dns-hostnames "{\"Value\":true}"
  }

Create_subnet ()
  {
AWS_SUBNET_PUBLIC_ID=$(aws ec2 create-subnet \
--vpc-id $AWS_VPC_ID \
--cidr-block $public_subnet_cidr_block \
--availability-zone $availability_zone \
--query 'Subnet.{SubnetId:SubnetId}' \
--output text)
AWS_VPC="$AWS_VPC $AWS_SUBNET_PUBLIC_ID"
  }

Auto_assign_Public_IP_on_Public_Subnet ()
  {
aws ec2 modify-subnet-attribute \
--subnet-id $AWS_SUBNET_PUBLIC_ID \
--map-public-ip-on-launch
  }

Create_Internet_Gateway ()
  {
AWS_INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway \
--query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
--output text)
AWS_VPC="$AWS_VPC $AWS_INTERNET_GATEWAY_ID"
  }

Attach_Internet_gateway_to_VPC ()
  {
aws ec2 attach-internet-gateway \
--vpc-id $AWS_VPC_ID \
--internet-gateway-id $AWS_INTERNET_GATEWAY_ID
  }

Add_ID_to_default_route_table ()
  {
AWS_DEFAULT_ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
--filters "Name=vpc-id,Values=$AWS_VPC_ID" \
--query 'RouteTables[?Associations[0].Main != flase].RouteTableId' \
--output text)
AWS_VPC="$AWS_VPC $AWS_DEFAULT_ROUTE_TABLE_ID"
  }

Create_route_table ()
  {
AWS_CUSTOM_ROUTE_TABLE_ID=$(aws ec2 create-route-table \
--vpc-id $AWS_VPC_ID \
--query 'RouteTable.{RouteTableId:RouteTableId}' \
--output text)
AWS_VPC="$AWS_VPC $AWS_CUSTOM_ROUTE_TABLE_ID"
  }

Create_route_to_Internet_Gateway ()
  {
aws ec2 create-route \
--route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
--destination-cidr-block $destination_cidr_block \
--gateway-id $AWS_INTERNET_GATEWAY_ID
  }

Associate_public_subnet_with_route_table ()
  {
AWS_ROUTE_TABLE_ASSOID=$(aws ec2 associate-route-table \
--subnet-id $AWS_SUBNET_PUBLIC_ID \
--route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
--output text | head -1)
AWS_VPC="$AWS_VPC $AWS_ROUTE_TABLE_ASSOID"
  }

Create_security_group ()
  {
aws ec2 create-security-group \
--vpc-id $AWS_VPC_ID \
--group-name $myvpc_security_group \
--description 'My VPC non default security group'
  }

Describe_Security_Group_id ()
  {
AWS_CUSTOM_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
--filters "Name=vpc-id,Values=$AWS_VPC_ID" \
--query 'SecurityGroups[?GroupName == `myvpc-security-group`].GroupId' \
--output text)
AWS_VPC="$AWS_VPC $AWS_CUSTOM_SECURITY_GROUP_ID"
  }

Get_Security_Group_id ()
  {
AWS_DEFAULT_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
--filters "Name=vpc-id,Values=$AWS_VPC_ID" \
--query 'SecurityGroups[?GroupName == `default`].GroupId' \
--output text)
AWS_VPC="$AWS_VPC $AWS_DEFAULT_SECURITY_GROUP_ID"
  }

Create_security_group_ssh_rule ()
  {
AWS_CUSTOM_SECURITY_GROUP_SSH_RULE_ID=$(aws ec2 authorize-security-group-ingress \
--group-id $AWS_CUSTOM_SECURITY_GROUP_ID \
--ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]}]')
  }

Create_security_group_http_rule ()
  {
AWS_CUSTOM_SECURITY_GROUP_HTTP_RULE_ID=$(aws ec2 authorize-security-group-ingress \
--group-id $AWS_CUSTOM_SECURITY_GROUP_ID \
--ip-permissions '[{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow HTTP"}]}]')
  }

Create_AWS_S3_Bucket ()
  {
AWS_S3=$(aws s3api create-bucket \
--bucket myvpc-s3 \
--output text | cut -c2-9)
AWS_VPC="$AWS_VPC $AWS_S3"
aws s3api wait bucket-exists \
--bucket $AWS_S3
  }

making_index_html_file ()
  {
echo "Hello World" > ./index.html
  }

making_nginx_conf_file ()
  {
sudo echo -e "server {
	listen 80 default_server;
	listen [::]:80 default_server;


        root /home/ubuntu/s3-drive;

        index index.html;


        location / {
                try_files \$uri \$uri/ =404;
                   }
        }" > ./nginx.conf
  }

Upload_html_to_bucket ()
  {
aws s3api put-object \
--acl public-read \
--bucket $AWS_S3 \
--key index.html \
--body index.html
  }

Upload_nginx_conf_to_bucket ()
  {
aws s3api put-object \
--acl public-read \
--bucket $AWS_S3 \
--key nginx.conf \
--body nginx.conf
  }

Create_key_pair ()
  {
aws ec2 create-key-pair \
--key-name myvpc-ec2-keypair \
--query 'KeyMaterial' \
--output text > myvpc-ec2-keypair.pem
  }

Create_EC2_instance ()
  {
AWS_EC2_INSTANCE_ID=$(aws ec2 run-instances \
--image-id ami-08d4ac5b634553e16 \
--instance-type t2.micro \
--key-name myvpc-ec2-keypair \
--monitoring "Enabled=false" \
--security-group-ids $AWS_CUSTOM_SECURITY_GROUP_ID \
--subnet-id $AWS_SUBNET_PUBLIC_ID \
--user-data file://myuserdata.txt \
--private-ip-address $instance_private_ip_address \
--query 'Instances[*].InstanceId' \
--output text)
AWS_VPC="$AWS_VPC $AWS_EC2_INSTANCE_ID"
  }

Get_public_ip_address_of_instance ()
  {
aws ec2 wait instance-status-ok \
--instance-ids $AWS_EC2_INSTANCE_ID
AWS_EC2_INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances \
--query "Reservations[*].Instances[*].PublicIpAddress" \
--output text)
AWS_VPC="$AWS_VPC $AWS_EC2_INSTANCE_PUBLIC_IP"
  }

create_myvpcs3user ()
  {
aws iam create-user \
--user-name $AWS_IAM_S3_USER \
--output text > /dev/null 
AWS_VPC="$AWS_VPC $AWS_IAM_S3_USER"
aws iam attach-user-policy \
--user-name $AWS_IAM_S3_USER \
--policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam create-access-key \
--user-name $AWS_IAM_S3_USER \
--output text > s3iamuser.txt
ACCESS_KEY_ID=$(cat s3iamuser.txt | awk '{print$2}')
AWS_VPC="$AWS_VPC $ACCESS_KEY_ID"
SECRET_ACCESS_KEY=$(cat s3iamuser.txt | awk '{print$4}')
AWS_VPC="$AWS_VPC $SECRET_ACCESS_KEY"  
  }


### Delete Functions ###

delete_vpc ()
  {
  aws ec2 delete-vpc \
--vpc-id $AWS_VPC_ID && \
  rm -f myvpc.txt myvpc.log
  }

delete_modified_vpc ()
  {
  aws ec2 modify-vpc-attribute \
--vpc-id $AWS_VPC_ID \
--enable-dns-hostnames "{\"Value\":false}" && \
  delete_vpc
  }

delete_subnet ()
  {
  aws ec2 delete-subnet \
--subnet-id $AWS_SUBNET_PUBLIC_ID && \
  delete_modified_vpc
  }

delete_internet_gateway ()
  {
  aws ec2 detach-internet-gateway \
--internet-gateway-id $AWS_INTERNET_GATEWAY_ID \
--vpc-id $AWS_VPC_ID && \
aws ec2 delete-internet-gateway \
--internet-gateway-id $AWS_INTERNET_GATEWAY_ID && \
  delete_subnet
  }

delete_route_table ()
  {
  aws ec2 delete-route-table \
--route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID && \
  delete_internet_gateway
  }

delete_associated_route_table ()
  {
  aws ec2 disassociate-route-table \
--association-id $AWS_ROUTE_TABLE_ASSOID && \
  delete_route_table
  }

delete_custom_security_group ()
  {
  aws ec2 delete-security-group \
--group-id $AWS_CUSTOM_SECURITY_GROUP_ID && \
  delete_associated_route_table
  }

delete_S3 ()
  {
  aws s3 rb --force s3://$AWS_S3 && \
  rm -f index.html nginx.conf && \
  delete_custom_security_group
  }

delete_S3_objects ()
  {
  aws ec2 wait instance-status-ok \
--instance-ids $AWS_EC2_INSTANCE_ID && \
  aws s3 rm s3://$AWS_S3 --recursive
  }

delete_key_pair ()
  {
  aws ec2 delete-key-pair \
--key-name myvpc-ec2-keypair && rm -f myvpc-ec2-keypair.pem && \
  delete_S3
  }

terminate_instance ()
  {
  aws ec2 terminate-instances \
--instance-ids $AWS_EC2_INSTANCE_ID && \
  aws ec2 wait instance-terminated \
--instance-ids $AWS_EC2_INSTANCE_ID && \
  delete_key_pair
  }

delete_myvpcs3user ()
  {
aws iam delete-access-key \
--user-name $AWS_IAM_S3_USER \
--access-key-id $ACCESS_KEY_ID && \
aws iam detach-user-policy \
--user-name $AWS_IAM_S3_USER \
--policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess && \
aws iam delete-user \
--user-name $AWS_IAM_S3_USER && \
rm -f s3iamuser.txt && \
terminate_instance
  }

