#!/bin/bash
echo "Deleting the vpc and dependencies, please wait...";

if [ ! -z "$SEC_GROUP_ID" ]
then	
    aws ec2 delete-security-group \
    --group-id $SEC_GROUP_ID;
fi
if [ ! -z "$INT_GATEWAY_ID" ]
then
    aws ec2 detach-internet-gateway \
    --internet-gateway-id $INT_GATEWAY_ID \
    --vpc-id $VPC_ID &&
    aws ec2 delete-internet-gateway \
    --internet-gateway-id $INT_GATEWAY_ID;
fi
if [ ! -z "$AWS_ROUTE_TABLE_ASSOID" ]
then
    aws ec2 disassociate-route-table \
    --association-id $AWS_ROUTE_TABLE_ASSOID &&
    aws ec2 delete-route-table \
    --route-table-id $ROUTE_TABLE_ID;
fi
if [ ! -z "$SUBNET_PUB_ID" ]
then
    aws ec2 delete-subnet \
    --subnet-id $SUBNET_PUB_ID;
fi
if [ ! -z "$VPC_ID" ]
then  
    aws ec2 delete-vpc \
    --vpc-id $VPC_ID;
fi
