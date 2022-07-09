#!/bin/bash

#resource ids file path
resourcesIds="./resources_ids/$resource_name.txt"

#taking ids from file
vpc_id=$(grep "vpc-" $resourcesIds)
subnet_id=$(grep "subnet-" $resourcesIds)
igw_id=$(grep "igw-" $resourcesIds)
route_table_id=$(grep "rtb-" $resourcesIds)
security_group_id=$(grep "sg-" $resourcesIds)
instance_id=$(grep "i-" $resourcesIds)
ssh_key_name=$(grep "key-" $resourcesIds)

#functions for deleting resources
function deleteVpc() {
  aws ec2 delete-vpc --vpc-id $vpc_id
  echo "Vpc deleted"
}

function deleteSubnet() {
  aws ec2 delete-subnet --subnet-id $subnet_id
  echo "Subnet deleted"
}

function deleteInternetGateway() {
  aws ec2 delete-internet-gateway --internet-gateway-id $igw_id
  echo "Igw deleted"
}

function detachIgw() {
  aws ec2 detach-internet-gateway \
    --internet-gateway-id $igw_id \
    --vpc-id $vpc_id
}

function deleteRouteTable() {
  aws ec2 delete-route-table --route-table-id $route_table_id
  echo "Route table deleted"
}

function deleteRoute() {
  aws ec2 delete-route \
  --route-table-id $route_table_id \
  --destination-cidr-block 0.0.0.0/0
  echo "Route deleted"
}

function deleteSecurityGroup() {
  aws ec2 delete-security-group --group-id $security_group_id
  echo "Security group deleted"
}

function deleteKeyPair() {
  aws ec2 delete-key-pair --key-name $ssh_key_name
  rm -f ./key-pairs/$ssh_key_name.pem
  rm -f ./resources_ids/$resource_name.txt

  echo "key-pair deleted"
}

function terminateInstance(){
  echo "Terminating instance"

  aws ec2 terminate-instances --instance-ids $instance_id --output text > /dev/null
  aws ec2 wait instance-terminated --instance-ids $instance_id

  echo "Instance terminated"
}
