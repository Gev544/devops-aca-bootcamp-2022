#!/bin/bash
echo "Deleting the instance $INSTANCE_ID, please wait..."

function get-instance-stat () {
    INSTANCE_STATUS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[].Instances[].State.Name" --output text)

}

function terminate-inst () {
   aws ec2 terminate-instances --instance-ids $INSTANCE_ID
}

# Terminate If Instance created
if [ ! -z "$INSTANCE_ID" ]
then
    get-instance-stat
    
    # Waiting to be able to terminate & terminating this instance
    if [ "$INSTANCE_STATUS" = "running" || "$INSTANCE_STATUS" = "stopped" ||
         "$INSTANCE_STATUS" = "pending" || "$INSTANCE_STATUS" = "shutting-down" ]
    then

        echo "Terminating the Instance, please wait..."
        terminate-inst

        while [ "$INSTANCE_STATUS" != "terminated" ]
        do
            sleep 3
	    get-instance-stat
        done
    fi

    if [ "$INSTANCE_STATUS" = "stopping" ]
    then

        while [ "$INSTANCE_STATUS" != "stopped" ]
        do
            sleep 3
            get-instance-stat
        done
	terminate-inst
    fi

    echo "Instance Terminated !"
fi

# Delete key pair
if [ ! -z "$KEY_PAIR" ]
then
    aws ec2 delete-key-pair \
    --key-name $KEY_PAIR;

    rm $KEY_PAIR.pem
fi

# Delete Security group
if [ ! -z "$SEC_GROUP_ID" ]
then	
    aws ec2 delete-security-group \
    --group-id $SEC_GROUP_ID;
fi

# Delete Internet gateway
if [ ! -z "$INT_GATEWAY_ID" ]
then
    aws ec2 detach-internet-gateway \
    --internet-gateway-id $INT_GATEWAY_ID \
    --vpc-id $VPC_ID &&
    aws ec2 delete-internet-gateway \
    --internet-gateway-id $INT_GATEWAY_ID;
fi

# Disassociate & delete route table
if [ ! -z "$AWS_ROUTE_TABLE_ASSOID" ]
then
    aws ec2 disassociate-route-table \
    --association-id $AWS_ROUTE_TABLE_ASSOID &&
    aws ec2 delete-route-table \
    --route-table-id $ROUTE_TABLE_ID;
fi

# Delete Public subnet
if [ ! -z "$SUBNET_PUB_ID" ]
then
    aws ec2 delete-subnet \
    --subnet-id $SUBNET_PUB_ID;
fi

# Delete VPC
if [ ! -z "$VPC_ID" ]
then  
    aws ec2 delete-vpc \
    --vpc-id $VPC_ID;
fi

# Delete bucket
exists=$(aws s3api list-buckets --query "Buckets[?Name == '$BName'].Name" --output text)
if [ $exists ]
then
    aws s3 rm s3://$BName --recursive
    aws s3api delete-bucket \
    --bucket $BName \
    --region $region;
fi

echo "Deleted"
