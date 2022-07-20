#!/bin/bash

AWS_VPC_ID=$(cat myvpc.txt | cut -d " " -f1)
AWS_PUBLIC_SUBNET_ID_1=$(cat myvpc.txt | cut -d " " -f2)
AWS_PUBLIC_SUBNET_ID_2=$(cat myvpc.txt | cut -d " " -f3)
AWS_INTERNET_GATEWAY_ID=$(cat myvpc.txt | cut -d " " -f4)
AWS_CUSTOM_ROUTE_TABLE_ID=$(cat myvpc.txt | cut -d " " -f6)
AWS_ROUTE_TABLE_ASSOID_1=$(cat myvpc.txt | cut -d " " -f7)
AWS_ROUTE_TABLE_ASSOID_2=$(cat myvpc.txt | cut -d " " -f8)
AWS_CUSTOM_SECURITY_GROUP_ID=$(cat myvpc.txt | cut -d " " -f9)
AWS_DEFAULT_SECURITY_GROUP_ID=$(cat myvpc.txt | cut -d " " -f10)
AWS_S3=$(cat myvpc.txt | cut -d " " -f11)
AWS_EC2_INSTANCE_ID_1=$(cat myvpc.txt | cut -d " " -f12)
AWS_EC2_INSTANCE_ID_2=$(cat myvpc.txt | cut -d " " -f13)
AWS_IAM_S3_USER=$(cat myvpc.txt | cut -d " " -f16)
ACCESS_KEY_ID=$(cat myvpc.txt | cut -d " " -f17)
AWS_ALB_ARN=$(cat myvpc.txt | cut -d " " -f19)
AWS_ALB_HTTP_TARGET_GROUP_ARN=$(cat myvpc.txt | cut -d " " -f20)
AWS_ALB_HTTP_LISTNER_ARN=$(cat myvpc.txt | cut -d " " -f21)
AWS_ALB_HTTPS_TARGET_GROUP_ARN=$(cat myvpc.txt | cut -d " " -f22)
AWS_ALB_HTTP_LISTNER_ARN=$(cat myvpc.txt | cut -d " " -f23)
AWS_ALB_DNS=$(cat myvpc.txt | cut -d " " -f24)
HOSTED_ZONE_ID=$(cat myvpc.txt | cut -d " " -f25)
ALB_HOSTED_ZONE_ID=$(cat myvpc.txt | cut -d " " -f26)


## Delete ALB Alias Record
echo '{
     "Comment": "Delete Alias resource record sets for a domain that point to an Elastic Load Balancer endpoint",
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
cat delete_ALB_alias_record.json
aws route53 change-resource-record-sets \
--hosted-zone-id $HOSTED_ZONE_ID \
--change-batch file://delete_ALB_alias_record.json && \
rm -f ./create_ALB_alias_record.json ./delete_ALB_alias_record.json

## Delete https listener
aws elbv2 delete-listener \
--listener-arn $AWS_ALB_HTTPS_LISTNER_ARN

## Deregister https targets
aws elbv2 deregister-targets \
--target-group-arn $AWS_ALB_HTTPS_TARGET_GROUP_ARN \
--targets Id=$AWS_EC2_INSTANCE_ID_1 Id=$AWS_EC2_INSTANCE_ID_2

## Delete https target group
aws elbv2 delete-target-group \
--target-group-arn $AWS_ALB_HTTPS_TARGET_GROUP_ARN

## Delete http listener
aws elbv2 delete-listener \
--listener-arn $AWS_ALB_HTTP_LISTNER_ARN
 
## Deregister http targets
aws elbv2 deregister-targets \
--target-group-arn $AWS_ALB_HTTP_TARGET_GROUP_ARN \
--targets Id=$AWS_EC2_INSTANCE_ID_1 Id=$AWS_EC2_INSTANCE_ID_2
 
## Delete http target group
aws elbv2 delete-target-group \
--target-group-arn $AWS_ALB_HTTP_TARGET_GROUP_ARN
 
## Delete Application Load Balancer
aws elbv2 delete-load-balancer \
--load-balancer-arn $AWS_ALB_ARN && \
rm -f ./create_ALB_alias_record.json ./delete_ALB_alias_record.json && \
echo "Aplication Load Balanser successfuly deleted"

## Delete S3 IAM user
aws iam delete-access-key \
--user-name $AWS_IAM_S3_USER \
--access-key-id $ACCESS_KEY_ID && \
aws iam detach-user-policy \
--user-name $AWS_IAM_S3_USER \
--policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess && \
aws iam delete-user \
--user-name $AWS_IAM_S3_USER && \
rm -f s3iamuser.txt ec2/.passwd-s3fs && \
echo "AWS S3 IAM user successfully deleted"

## Terminate the ec2 instance_1
aws ec2 terminate-instances \
--instance-ids $AWS_EC2_INSTANCE_ID_1 && \
aws ec2 wait instance-terminated \
--instance-ids $AWS_EC2_INSTANCE_ID_1 && \
echo "Amazon Linux Instance "$AWS_EC2_INSTANCE_ID_1" successfully terminated"

## Terminate the ec2 instance_2
aws ec2 terminate-instances \
--instance-ids $AWS_EC2_INSTANCE_ID_2 && \
aws ec2 wait instance-terminated \
--instance-ids $AWS_EC2_INSTANCE_ID_2 && \
echo "Amazon Linux Instance "$AWS_EC2_INSTANCE_ID_2" successfully terminated"

## Delete key pair
aws ec2 delete-key-pair \
--key-name myvpc-ec2-keypair && rm -f myvpc-ec2-keypair.pem && \
echo "myvpc-ec2-keypair successfuly deleted from AWS and localhost"

## Delete s3 bucket
aws s3 rb --force s3://$AWS_S3 && \
rm -f nginx.conf index.html && \
echo "s3 bucket "$AWS_S3" and nginx files are deleted"

## Delete custom security group
aws ec2 delete-security-group \
--group-id $AWS_CUSTOM_SECURITY_GROUP_ID && \
echo "Custom Security Group "$AWS_CUSTOM_SECURITY_GROUP_ID" successfuly deleted"

## Delete the custom route table
aws ec2 disassociate-route-table \
--association-id $AWS_ROUTE_TABLE_ASSOID_2 && \
aws ec2 disassociate-route-table \
--association-id $AWS_ROUTE_TABLE_ASSOID_1 && \
aws ec2 delete-route \
--route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
--destination-cidr-block 0.0.0.0/0 && \
aws ec2 delete-route-table \
--route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID && \
echo "Custom Route Table "$AWS_CUSTOM_ROUTE_TABLE_ID" successfuly deleted"

## Delete internet gateway
aws ec2 detach-internet-gateway \
--internet-gateway-id $AWS_INTERNET_GATEWAY_ID \
--vpc-id $AWS_VPC_ID && \
aws ec2 delete-internet-gateway \
--internet-gateway-id $AWS_INTERNET_GATEWAY_ID && \
echo "Internet Gateway "$AWS_INTERNET_GATEWAY_ID" successfully deleted"

## Delete the public subnet 2
aws ec2 modify-subnet-attribute \
--subnet-id $AWS_PUBLIC_SUBNET_ID_2 \
--no-map-public-ip-on-launch && \
aws ec2 delete-subnet \
--subnet-id $AWS_PUBLIC_SUBNET_ID_2 && \
echo "Public Subnet "$AWS_PUBLIC_SUBNET_ID_2" successfuly deleted"

## Delete the public subnet 1
aws ec2 modify-subnet-attribute \
--subnet-id $AWS_PUBLIC_SUBNET_ID_1 \
--no-map-public-ip-on-launch && \
aws ec2 delete-subnet \
--subnet-id $AWS_PUBLIC_SUBNET_ID_1 && \
echo "Public Subnet "$AWS_PUBLIC_SUBNET_ID_1" successfuly deleted"

## Delete the vpc
aws ec2 modify-vpc-attribute \
--vpc-id $AWS_VPC_ID \
--enable-dns-hostnames "{\"Value\":false}" && \
aws ec2 delete-vpc \
--vpc-id $AWS_VPC_ID && \
rm -f myvpc.txt myvpc.log && \
echo "myvpc "$AWS_VPC_ID" successfuly deleted"
