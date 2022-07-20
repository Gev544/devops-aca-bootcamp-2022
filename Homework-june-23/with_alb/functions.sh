#!/bin/bash

vpcs_file="myvpc.txt"
myvpc_cidr_block="10.0.0.0/16"
public_subnet_cidr_block_1="10.0.1.0/24"
public_subnet_cidr_block_2="10.0.2.0/24"
availability_zone_1="us-east-1a"
availability_zone_2="us-east-1b"
destination_cidr_block="0.0.0.0/0"
myvpc_security_group="myvpc-security-group"
region="us-east-1"
instance_private_ip_address_1="10.0.1.10"
instance_private_ip_address_2="10.0.2.10"
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

tag_VPC ()
{
aws ec2 create-tags \
--resources $AWS_VPC_ID \
--tags "Key=Name,Value=myvpc"
}

Create_subnet_1 ()
{
AWS_SUBNET_PUBLIC_ID_1=$(aws ec2 create-subnet \
--vpc-id $AWS_VPC_ID \
--cidr-block $public_subnet_cidr_block_1 \
--availability-zone $availability_zone_1 \
--query 'Subnet.{SubnetId:SubnetId}' \
--output text)
AWS_VPC="$AWS_VPC $AWS_SUBNET_PUBLIC_ID_1"
}

Create_subnet_2 ()
{
AWS_SUBNET_PUBLIC_ID_2=$(aws ec2 create-subnet \
--vpc-id $AWS_VPC_ID \
--cidr-block $public_subnet_cidr_block_2 \
--availability-zone $availability_zone_2 \
--query 'Subnet.{SubnetId:SubnetId}' \
--output text)
AWS_VPC="$AWS_VPC $AWS_SUBNET_PUBLIC_ID_2"
}

tag_public_subnet_1 ()
{
aws ec2 create-tags \
--resources $AWS_SUBNET_PUBLIC_ID_1 \
--tags "Key=Name,Value=myvpc-public-subnet-1"
}

tag_public_subnet_2 ()
{
aws ec2 create-tags \
--resources $AWS_SUBNET_PUBLIC_ID_2 \
--tags "Key=Name,Value=myvpc-public-subnet-2"
}

Auto_assign_Public_IP_Public_Subnet_1 ()
{
aws ec2 modify-subnet-attribute \
--subnet-id $AWS_SUBNET_PUBLIC_ID_1 \
--map-public-ip-on-launch
}

Auto_assign_Public_IP_Public_Subnet_2 ()
{
aws ec2 modify-subnet-attribute \
--subnet-id $AWS_SUBNET_PUBLIC_ID_2 \
--map-public-ip-on-launch
}

Create_Internet_Gateway ()
{
AWS_INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway \
--query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
--output text)
AWS_VPC="$AWS_VPC $AWS_INTERNET_GATEWAY_ID"
}

tag_Internet-Gateway ()
{
aws ec2 create-tags \
--resources $AWS_INTERNET_GATEWAY_ID \
--tags "Key=Name,Value=myvpc-internet-gateway"
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

tag_default_route_table ()
{
aws ec2 create-tags \
--resources $AWS_DEFAULT_ROUTE_TABLE_ID \
--tags "Key=Name,Value=myvpc-default-route-table"
}

Create_custom_route_table ()
{
AWS_CUSTOM_ROUTE_TABLE_ID=$(aws ec2 create-route-table \
--vpc-id $AWS_VPC_ID \
--query 'RouteTable.{RouteTableId:RouteTableId}' \
--output text)
AWS_VPC="$AWS_VPC $AWS_CUSTOM_ROUTE_TABLE_ID"
}

tag_custom_route_table ()
{
aws ec2 create-tags \
--resources $AWS_CUSTOM_ROUTE_TABLE_ID \
--tags "Key=Name,Value=myvpc-public-route-table"
}

Create_route_to_Internet_Gateway ()
{
aws ec2 create-route \
--route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
--destination-cidr-block $destination_cidr_block \
--gateway-id $AWS_INTERNET_GATEWAY_ID
}

Associate_public_subnet_1_with_route_table ()
{
AWS_ROUTE_TABLE_ASSOID_1=$(aws ec2 associate-route-table \
--subnet-id $AWS_SUBNET_PUBLIC_ID_1 \
--route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
--query 'AssociationId' \
--output text)
AWS_VPC="$AWS_VPC $AWS_ROUTE_TABLE_ASSOID_1"
}

Associate_public_subnet_2_with_route_table ()
{
AWS_ROUTE_TABLE_ASSOID_2=$(aws ec2 associate-route-table \
--subnet-id $AWS_SUBNET_PUBLIC_ID_2 \
--route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
--query 'AssociationId' \
--output text)
AWS_VPC="$AWS_VPC $AWS_ROUTE_TABLE_ASSOID_2"
}

Create_custom_security_group ()
{
aws ec2 create-security-group \
--vpc-id $AWS_VPC_ID \
--group-name $myvpc_security_group \
--description 'My VPC custom security group'
}

Describe_custom_security_Group_id ()
{
AWS_CUSTOM_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
--filters "Name=vpc-id,Values=$AWS_VPC_ID" \
--query 'SecurityGroups[?GroupName == `myvpc-security-group`].GroupId' \
--output text)
AWS_VPC="$AWS_VPC $AWS_CUSTOM_SECURITY_GROUP_ID"
}

tag_custom_security_group ()
{
aws ec2 create-tags \
--resources $AWS_CUSTOM_SECURITY_GROUP_ID \
--tags "Key=Name,Value=myvpc-custom-security-group"
}

Get_default_security_Group_id ()
{
AWS_DEFAULT_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
--filters "Name=vpc-id,Values=$AWS_VPC_ID" \
--query 'SecurityGroups[?GroupName == `default`].GroupId' \
--output text)
AWS_VPC="$AWS_VPC $AWS_DEFAULT_SECURITY_GROUP_ID"
}

tag_default_security_group ()
{
aws ec2 create-tags \
--resources $AWS_DEFAULT_SECURITY_GROUP_ID \
--tags "Key=Name,Value=myvpc-default-security-group"
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

Create_security_group_https_rule ()
{
AWS_CUSTOM_SECURITY_GROUP_HTTPS_RULE_ID=$(aws ec2 authorize-security-group-ingress \
--group-id $AWS_CUSTOM_SECURITY_GROUP_ID \
--ip-permissions '[{"IpProtocol": "tcp", "FromPort": 443, "ToPort": 443, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow HTTPS"}]}]')
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

        server_name artur-tshitoyan.acadevopscourse.xyz;

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

Create_EC2_instance_1 ()
{
AWS_EC2_INSTANCE_ID_1=$(aws ec2 run-instances \
--image-id ami-08d4ac5b634553e16 \
--instance-type t2.micro \
--key-name myvpc-ec2-keypair \
--monitoring "Enabled=false" \
--security-group-ids $AWS_CUSTOM_SECURITY_GROUP_ID \
--subnet-id $AWS_SUBNET_PUBLIC_ID_1 \
--user-data file://myuserdata.txt \
--private-ip-address $instance_private_ip_address_1 \
--query 'Instances[0].InstanceId' \
--output text)
AWS_VPC="$AWS_VPC $AWS_EC2_INSTANCE_ID_1"
}

tag_ec2_instance_1 ()
{
aws ec2 create-tags \
--resources $AWS_EC2_INSTANCE_ID_1 \
--tags "Key=Name,Value=myvpc-ec2-instance-1"
}

Create_EC2_instance_2 ()
{
AWS_EC2_INSTANCE_ID_2=$(aws ec2 run-instances \
--image-id ami-08d4ac5b634553e16 \
--instance-type t2.micro \
--key-name myvpc-ec2-keypair \
--monitoring "Enabled=false" \
--security-group-ids $AWS_CUSTOM_SECURITY_GROUP_ID \
--subnet-id $AWS_SUBNET_PUBLIC_ID_2 \
--user-data file://myuserdata.txt \
--private-ip-address $instance_private_ip_address_2 \
--query 'Instances[0].InstanceId' \
--output text)
AWS_VPC="$AWS_VPC $AWS_EC2_INSTANCE_ID_2"
}

tag_ec2_instance_2 ()
{
aws ec2 create-tags \
--resources $AWS_EC2_INSTANCE_ID_2 \
--tags "Key=Name,Value=myvpc-ec2-instance-2"
}

Get_public_ip_address_of_instance_1 ()
{
aws ec2 wait instance-status-ok \
--instance-ids $AWS_EC2_INSTANCE_ID_1
AWS_EC2_INSTANCE_PUBLIC_IP_1=$(aws ec2 describe-instances \
--filters "Name=instance-id,Values=$AWS_EC2_INSTANCE_ID_1" \
--query "Reservations[*].Instances[*].PublicIpAddress" \
--output text)
AWS_VPC="$AWS_VPC $AWS_EC2_INSTANCE_PUBLIC_IP_1"
}

Get_public_ip_address_of_instance_2 ()
{
aws ec2 wait instance-status-ok \
--instance-ids $AWS_EC2_INSTANCE_ID_2
AWS_EC2_INSTANCE_PUBLIC_IP_2=$(aws ec2 describe-instances \
--filters "Name=instance-id,Values=$AWS_EC2_INSTANCE_ID_2" \
--query "Reservations[*].Instances[*].PublicIpAddress" \
--output text)
AWS_VPC="$AWS_VPC $AWS_EC2_INSTANCE_PUBLIC_IP_2"
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

create_alb ()
{
AWS_ALB_ARN=$(aws elbv2 create-load-balancer \
--name my-application-load-balancer  \
--subnets $AWS_SUBNET_PUBLIC_ID_1 $AWS_SUBNET_PUBLIC_ID_2 \
--security-groups $AWS_CUSTOM_SECURITY_GROUP_ID \
--query 'LoadBalancers[0].LoadBalancerArn' \
--output text)
AWS_VPC="$AWS_VPC $AWS_ALB_ARN"
}

create_alb_http_target_group ()
{
AWS_ALB_HTTP_TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
--name my-alb-http-targets \
--protocol HTTP --port 80 \
--vpc-id $AWS_VPC_ID \
--query 'TargetGroups[0].TargetGroupArn' \
--output text)
AWS_VPC="$AWS_VPC $AWS_ALB_HTTP_TARGET_GROUP_ARN"
}

register_instances_in_http_target_group ()
{
aws elbv2 register-targets \
--target-group-arn $AWS_ALB_HTTP_TARGET_GROUP_ARN  \
--targets Id=$AWS_EC2_INSTANCE_ID_1 Id=$AWS_EC2_INSTANCE_ID_2
}

create_alb_http_listener_forward_to_target_group_rule ()
{
AWS_ALB_HTTP_LISTNER_ARN=$(aws elbv2 create-listener \
--load-balancer-arn $AWS_ALB_ARN \
--protocol HTTP --port 80  \
--default-actions Type=forward,TargetGroupArn=$AWS_ALB_HTTP_TARGET_GROUP_ARN \
--query 'Listeners[0].ListenerArn' \
--output text)
AWS_VPC="$AWS_VPC $AWS_ALB_HTTP_LISTNER_ARN"
}

create_alb_https_target_group ()
{
AWS_ALB_HTTPS_TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
--name my-alb-https-targets \
--protocol HTTP --port 443 \
--vpc-id $AWS_VPC_ID \
--query 'TargetGroups[0].TargetGroupArn' \
--output text)
AWS_VPC="$AWS_VPC $AWS_ALB_HTTPS_TARGET_GROUP_ARN"
}

register_instances_in_https_target_group ()
{
aws elbv2 register-targets \
--target-group-arn $AWS_ALB_HTTPS_TARGET_GROUP_ARN  \
--targets Id=$AWS_EC2_INSTANCE_ID_1 Id=$AWS_EC2_INSTANCE_ID_2
}

create_alb_https_listener_forward_to_target_group_rule ()
{
AWS_ALB_HTTPS_LISTNER_ARN=$(aws elbv2 create-listener \
--load-balancer-arn $AWS_ALB_ARN \
--protocol HTTPS --port 443  \
--certificates CertificateArn=arn:aws:acm:us-east-1:763021817125:certificate/c50307f2-3ab6-437f-8ee6-91e6ce0ceb7c \
--default-actions Type=forward,TargetGroupArn=$AWS_ALB_HTTPS_TARGET_GROUP_ARN \
--query 'Listeners[0].ListenerArn' \
--output text)
AWS_VPC="$AWS_VPC $AWS_ALB_HTTPS_LISTNER_ARN"
aws elbv2 modify-listener \
--listener-arn $AWS_ALB_HTTPS_LISTNER_ARN \
--default-actions '[{"Type": "redirect", "RedirectConfig": {"Protocol": "HTTPS", "Port": "443", "Host": "#{host}", "Query": "#{query}", "Path": "/#{path}", "StatusCode": "HTTP_301"}}]'
}

get_alb_dns ()
{
AWS_ALB_DNS=$(aws elbv2 describe-load-balancers \
--load-balancer-arns $AWS_ALB_ARN \
--query 'LoadBalancers[0].DNSName' \
--output text)
AWS_VPC="$AWS_VPC $AWS_ALB_DNS"
}

make_hosted_zone_id ()
{
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
--query HostedZones[].Id \
--output text | cut -c13-33)
AWS_VPC="$AWS_VPC $HOSTED_ZONE_ID"
ALB_HOSTED_ZONE_ID=$(aws elbv2 describe-load-balancers \
--load-balancer-arns $AWS_ALB_ARN \
--query 'LoadBalancers[0].CanonicalHostedZoneId' \
--output text)
AWS_VPC="$AWS_VPC $ALB_HOSTED_ZONE_ID"
}

make_ALB_alias_record_file ()
{
echo '{
     "Comment": "Create Alias resource record sets for a domain to point to an Elastic Load Balancer endpoint",
     "Changes": [{
                "Action": "CREATE",
                "ResourceRecordSet": {
                            "Name": "artur-tshitoyan.acadevopscourse.xyz",
                            "Type": "A",
                            "AliasTarget":{
                                    "HostedZoneId": "'$ALB_HOSTED_ZONE_ID'",
                                    "DNSName": "dualstack.'$AWS_ALB_DNS'",
                                    "EvaluateTargetHealth": false
                              }}
                          }]
}' > ./create_ALB_alias_record.json
}

add_ALB_alias_record ()
{
HOSTED_ZONE_ALB_CHANGE_ID=$(aws route53 change-resource-record-sets \
--hosted-zone-id $HOSTED_ZONE_ID \
--change-batch file://create_ALB_alias_record.json \
--output text | awk '{print$18}')
AWS_VPC="$AWS_VPC $HOSTED_ZONE_ALB_CHANGE_ID"
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

delete_subnet_1 ()
{
aws ec2 delete-subnet \
--subnet-id $AWS_SUBNET_PUBLIC_ID_1 && \
delete_modified_vpc
}

delete_subnet_2 ()
{
aws ec2 delete-subnet \
--subnet-id $AWS_SUBNET_PUBLIC_ID_2 && \
delete_subnet_1
}

delete_internet_gateway ()
{
aws ec2 detach-internet-gateway \
--internet-gateway-id $AWS_INTERNET_GATEWAY_ID \
--vpc-id $AWS_VPC_ID && \
aws ec2 delete-internet-gateway \
--internet-gateway-id $AWS_INTERNET_GATEWAY_ID && \
delete_subnet_2
}

delete_custom_route_table ()
{
aws ec2 delete-route-table \
--route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID && \
delete_internet_gateway
}

delete_associated_route_table_1 ()
{
aws ec2 disassociate-route-table \
--association-id $AWS_ROUTE_TABLE_ASSOID_1 && \
delete_custom_route_table
}

delete_associated_route_table_2 ()
{
aws ec2 disassociate-route-table \
--association-id $AWS_ROUTE_TABLE_ASSOID_2 && \
delete_associated_route_table_1
}

delete_custom_security_group ()
{
aws ec2 delete-security-group \
--group-id $AWS_CUSTOM_SECURITY_GROUP_ID && \
delete_associated_route_table_2
}

delete_S3 ()
{
aws s3 rb --force s3://$AWS_S3 && \
rm -f index.html nginx.conf && \
delete_custom_security_group
}

delete_S3_objects ()
{
aws ec2 wait instance-terminated \
--instance-ids $AWS_EC2_INSTANCE_ID_1 $AWS_EC2_INSTANCE_ID_2 && \
aws s3 rm s3://$AWS_S3 --recursive
}

delete_key_pair ()
{
aws ec2 delete-key-pair \
--key-name myvpc-ec2-keypair && rm -f myvpc-ec2-keypair.pem && \
delete_S3
}

terminate_instance_1 ()
{
aws ec2 terminate-instances \
--instance-ids $AWS_EC2_INSTANCE_ID_1 && \
aws ec2 wait instance-terminated \
--instance-ids $AWS_EC2_INSTANCE_ID_1 && \
delete_key_pair
}

terminate_instance_2 ()
{
aws ec2 terminate-instances \
--instance-ids $AWS_EC2_INSTANCE_ID_2 && \
aws ec2 wait instance-terminated \
--instance-ids $AWS_EC2_INSTANCE_ID_2 && \
terminate_instance_1
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
terminate_instance_2
}

delete_Application_Load_Balancer ()
{
aws elbv2 delete-load-balancer \
--load-balancer-arn $AWS_ALB_ARN && \
delete_myvpcs3user
}

delete_http_target_group ()
{
aws elbv2 delete-target-group \
--target-group-arn $AWS_ALB_HTTP_TARGET_GROUP_ARN && \
delete_Application_Load_Balancer
}

deregister_http_targets ()
{
aws elbv2 deregister-targets \
--target-group-arn $AWS_ALB_HTTP_TARGET_GROUP_ARN \
--targets Id=$AWS_EC2_INSTANCE_ID_1 Id=$AWS_EC2_INSTANCE_ID_2 && \
delete_http_target_group
}

delete_http_listener ()
{
aws elbv2 delete-listener \
--listener-arn $AWS_ALB_HTTP_LISTNER_ARN && \
deregister_http_targets
}

delete_https_target_group ()
{
aws elbv2 delete-target-group \
--target-group-arn $AWS_ALB_HTTPS_TARGET_GROUP_ARN && \
delete_http_listener
}

deregister_https_targets ()
{
aws elbv2 deregister-targets \
--target-group-arn $AWS_ALB_HTTPS_TARGET_GROUP_ARN \
--targets Id=$AWS_EC2_INSTANCE_ID_1 Id=$AWS_EC2_INSTANCE_ID_2 && \
delete_https_target_group
}

delete_https_listener ()
{
aws elbv2 delete-listener \
--listener-arn $AWS_ALB_HTTPS_LISTNER_ARN && \
deregister_https_targets
}

make_ALB_alias_record_delete_file ()
{
echo '{
     "Comment": "Delete Alias resource record sets for a domain to point to an Elastic Load Balancer endpoint",
     "Changes": [{
                "Action": "DELETE",
                "ResourceRecordSet": {
                            "Name": "artur-tshitoyan.acadevopscourse.xyz",
                            "Type": "A",
                            "AliasTarget":{
                                    "HostedZoneId": "'$ALB_HOSTED_ZONE_ID'",
                                    "DNSName": "dualstack.'$AWS_ALB_DNS'",
                                    "EvaluateTargetHealth": false
                              }}
                          }]
}' > ./delete_ALB_alias_record.json
}

delete_ALB_alias_record ()
{
aws route53 change-resource-record-sets \
--hosted-zone-id $HOSTED_ZONE_ID \
--change-batch file://delete_ALB_alias_record.json && \
rm -f ./create_ALB_alias_record.json ./delete_ALB_alias_record.json
}
