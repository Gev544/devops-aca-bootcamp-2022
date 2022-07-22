#!/bin/bash

#resource ids file path
resourcesIds="./resources_ids/$resource_name.txt"

#taking ids from file
vpc_id=$(grep "vpc-" $resourcesIds -s)
subnet_id=$(grep "subnet-" $resourcesIds -s)
igw_id=$(grep "igw-" $resourcesIds -s)
route_table_id=$(grep "rtb-" $resourcesIds -s)
security_group_id=$(grep "sg-" $resourcesIds -s)
instance_id=$(grep "i-" $resourcesIds -s)
ssh_key_name=$(grep "key-" $resourcesIds -s)
access_key=$(head -1 "./user-key/${resource_name}-user.txt" 2>/dev/null)

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

#detach user policy
function detachUserPolicy() {
  aws iam detach-user-policy \
  --user-name "${resource_name}-User" \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

  if [[ $? != 0 ]]; then
    echo "Something went wrong when detaching user policy"
  else
    echo " User Policy detached"
  fi

}

#delete user permissions
function deleteUserPermissions() {
  aws iam delete-user-permissions-boundary \
    --user-name "${resource_name}-User"

    if [[ $? != 0 ]]; then
      echo "Something went wrong when deleting user permissions"
    else
      echo "user permissions deleted"
    fi
}

#delete access key
function deleteAccessKey() {
  aws iam delete-access-key \
  --access-key-id $access_key \
  --user-name "${resource_name}-User"

  if [[ $? != 0 ]]; then
    echo "Something went wrong when deleting access key"
  else
    echo "access key deleted"
  fi
}

#delete user
function deleteUser() {
  aws iam delete-user \
  --user-name "${resource_name}-User"

  if [[ $? != 0 ]]; then
    echo "Something went wrong when deleting user"
  else
    echo "user deleted"
  fi

  rm -f ./user-key/"${resource_name}-user.txt"
}
