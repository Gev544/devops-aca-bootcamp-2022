#!/bin/bash
set -ea
function Create-vpc () {
 
echo "Creating a vpc, please wait..."

# Create vpc && name
VPC_ID=$(aws ec2 create-vpc \
--cidr-block 10.0.0.0/24 \
--query 'Vpc.{VpcId:VpcId}' \
--output text) &&
aws ec2 create-tags \
--resources $VPC_ID \
--tags "Key=Name,Value=MySecondVpc"


# Create a public subnet && name
SUBNET_PUB_ID=$(aws ec2 create-subnet \
--vpc-id $VPC_ID --cidr-block 10.0.0.0/24 \
--availability-zone us-east-1c --query 'Subnet.{SubnetId:SubnetId}' \
--output text) &&
aws ec2 create-tags \
--resources $SUBNET_PUB_ID \
--tags "Key=Name,Value=MySecondSub"

# Enable auto-assign public ip
aws ec2 modify-subnet-attribute \
--subnet-id $SUBNET_PUB_ID \
--map-public-ip-on-launch

# Create internet gateway && name
INT_GATEWAY_ID=$(aws ec2 create-internet-gateway \
--query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
--output text) &&
aws ec2 create-tags \
--resources $INT_GATEWAY_ID \
--tags "Key=Name,Value=MySecondGateway"

# Attach gateway to the VPC
aws ec2 attach-internet-gateway \
--vpc-id $VPC_ID \
--internet-gateway-id $INT_GATEWAY_ID

# Create a route table && name
ROUTE_TABLE_ID=$(aws ec2 create-route-table \
--vpc-id $VPC_ID \
--query 'RouteTable.{RouteTableId:RouteTableId}' \
--output text ) &&
aws ec2 create-tags \
--resources $ROUTE_TABLE_ID \
--tags "Key=Name,Value=MySecondRoute"

# Create a route to the route table
aws ec2 create-route \
--route-table-id $ROUTE_TABLE_ID \
--destination-cidr-block 0.0.0.0/0 \
--gateway-id $INT_GATEWAY_ID

# Associate the subnet with route table
AWS_ROUTE_TABLE_ASSOID=$(aws ec2 associate-route-table  \
--subnet-id $SUBNET_PUB_ID \
--route-table-id $ROUTE_TABLE_ID \
--output text)
AWS_ROUTE_TABLE_ASSOID=$(echo $AWS_ROUTE_TABLE_ASSOID | awk '{ print $1; }')

# Create security group
aws ec2 create-security-group \
--vpc-id $VPC_ID \
--group-name myvpc-security-group \
--description 'Wizzard-2'

# Get security group id
SEC_GROUP_ID=$(aws ec2 describe-security-groups \
--filters "Name=vpc-id,Values=$VPC_ID" \
--query 'SecurityGroups[?GroupName == `myvpc-security-group`].GroupId' \
--output text)

# Create security rules
aws ec2 authorize-security-group-ingress \
--group-id $SEC_GROUP_ID \
--ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]}]' &&
aws ec2 authorize-security-group-ingress \
--group-id $SEC_GROUP_ID \
--ip-permissions '[{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow HTTP"}]}]' &&
aws ec2 authorize-security-group-ingress \
--group-id $SEC_GROUP_ID \
--ip-permissions '[{"IpProtocol": "tcp", "FromPort": 443, "ToPort": 443, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow HTTP"}]}]' || echo "Security rules didn't created"

# Create key pair
KEY_PAIR="ubuntu-server-key-1"
aws ec2 create-key-pair \
--key-name $KEY_PAIR \
--query "KeyMaterial" \
--output text > $KEY_PAIR.pem &&
chmod 400 $KEY_PAIR.pem

# Create ec2
INSTANCE_ID=$(aws ec2 run-instances \
--image-id ami-052efd3df9dad4825 \
--instance-type t2.micro \
--count 1 \
--subnet-id $SUBNET_PUB_ID \
--key-name $KEY_PAIR \
--security-group-ids $SEC_GROUP_ID \
--query 'Instances[].InstanceId' \
--output text)

aws ec2 create-tags \
--resources $INSTANCE_ID \
--tags "Key=Name,Value=my-test-ints"

}
Create-vpc && echo "Instance created" || ./clean-vpc-instance.sh

# Create S3 bucket & upload project
region="us-east-1"
ERR=1
count=1
# Bucket name
BName="site-demo-$count"

function create-s3-bucket () 
{
  # Create an s3 bucket
  while [ $ERR != 0 ]
  do
      aws s3 mb s3://$BName --region $region
      ERR=$?

      if [ $ERR != 0 ]
      then
          echo "The name is bussy, trying to count bucket name '$count'"
          ((count=count+1))
          BName="site-demo-$count"
      fi
  done

  # Copy project into the bucket
  aws s3 cp --recursive Project_X s3://$BName 
}

# Create or if there was any errors occurred do cleanUp
create-s3-bucket || ./clean-vpc-instance.sh

# Connect to the instance
INSTANCE_PUB_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[].Instances[].PublicIpAddress" --output text)

# Create aws credentials file 
firstKey=$(cat /root/.aws/credentials | head -2 | tail -1 | cut -d ' ' -f 3)
secKey=$(cat /root/.aws/credentials | head -3 | tail -1 | cut -d ' ' -f 3)
echo "$firstKey:$secKey" > passwd-s3fs

function ssh-instance ()
{
    scp -i $KEY_PAIR.pem -o StrictHostKeyChecking=accept-new nginx.sh ubuntu@$INSTANCE_PUB_IP:/home/ubuntu/nginx.sh
    scp -i $KEY_PAIR.pem rate-parser.sh ubuntu@$INSTANCE_PUB_IP:/home/ubuntu/rate-parser.sh
    scp -i $KEY_PAIR.pem -r Project_X ubuntu@$INSTANCE_PUB_IP:/home/ubuntu/Project_X
    scp -i $KEY_PAIR.pem passwd-s3fs ubuntu@$INSTANCE_PUB_IP:/home/ubuntu/passwd-s3fs
    rm passwd-s3fs
    ssh -i $KEY_PAIR.pem ubuntu@$INSTANCE_PUB_IP "./nginx.sh $BName"
}

function get-instance-stat ()
{
    INSTANCE_STATUS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[].Instances[].State.Name" --output text)

}

# Check instans status & ssh
get-instance-stat || echo "Can't get instance status"

function connect-instance-scp-nginx ()
{
        sleep 1
        while [ "$INSTANCE_STATUS" = "pending" ]
        do
                echo "Waiting instance to run..."
                sleep 5
                get-instance-stat || echo "Can't get instance status"
        done

        echo "Waiting while instance initialize..."
        sleep 20
        ssh-instance || echo "SSH connections failed when calling function ssh-instance"
}
connect-instance-scp-nginx
bash
