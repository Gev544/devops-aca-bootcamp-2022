#!/bin/bash

AWS_VPC_ID=$(cat myvpc.txt | cut -d " " -f1)
AWS_SUBNET_PUBLIC_ID=$(cat myvpc.txt | cut -d " " -f2)
AWS_INTERNET_GATEWAY_ID=$(cat myvpc.txt | cut -d " " -f3)
AWS_CUSTOM_ROUTE_TABLE_ID=$(cat myvpc.txt | cut -d " " -f5)
AWS_ROUTE_TABLE_ASSOID=$(cat myvpc.txt | cut -d " " -f6)
AWS_CUSTOM_SECURITY_GROUP_ID=$(cat myvpc.txt | cut -d " " -f7)
AWS_DEFAULT_SECURITY_GROUP_ID=$(cat myvpc.txt | cut -d " " -f8)
AWS_S3=$(cat myvpc.txt | cut -d " " -f9)
AWS_EC2_INSTANCE_ID=$(cat myvpc.txt | cut -d " " -f10)
AWS_IAM_S3_USER=$(cat myvpc.txt | cut -d " " -f12)
ACCESS_KEY_ID=$(cat myvpc.txt | cut -d " " -f13)

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

## Terminate the ec2 instance
aws ec2 terminate-instances \
--instance-ids $AWS_EC2_INSTANCE_ID && \
aws ec2 wait instance-terminated \
--instance-ids $AWS_EC2_INSTANCE_ID && \
echo "Amazon Linux Instance "$AWS_EC2_INSTANCE_ID" successfully terminated"

## Delete key pair
aws ec2 delete-key-pair \
--key-name myvpc-ec2-keypair && rm -f myvpc-ec2-keypair.pem instance.log && \
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
--association-id $AWS_ROUTE_TABLE_ASSOID && \
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

## Delete the public subnet
aws ec2 modify-subnet-attribute \
--subnet-id $AWS_SUBNET_PUBLIC_ID \
--no-map-public-ip-on-launch && \
aws ec2 delete-subnet \
--subnet-id $AWS_SUBNET_PUBLIC_ID && \
echo "Public Subnet "$AWS_SUBNET_PUBLIC_ID" successfuly deleted"

## Delete the vpc
aws ec2 modify-vpc-attribute \
--vpc-id $AWS_VPC_ID \
--enable-dns-hostnames "{\"Value\":false}" && \
aws ec2 delete-vpc \
--vpc-id $AWS_VPC_ID && \
rm -f myvpc.txt myvpc.log && \
echo "myvpc "$AWS_VPC_ID" successfuly deleted"
