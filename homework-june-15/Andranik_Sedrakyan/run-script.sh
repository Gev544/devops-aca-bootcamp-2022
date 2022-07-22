#!/bin/bash

function copyCode() {
  set -e
  resource_name=$1
  instance_ip=$2

  echo "copying code to instance"

  echo "resource name - $resource_name"
  echo "instance ip - $instance_ip"

  #adding to known hosts
  ssh-keyscan $instance_ip >> ~/.ssh/known_hosts 2> /dev/null
  echo "host added"

  scp -i ./key-pairs/key-${resource_name}.pem ./remote/remote.sh ubuntu@${instance_ip}:~/ && \
  scp -i ./key-pairs/key-${resource_name}.pem ./remote/website.sh ubuntu@${instance_ip}:~/ && \
  scp -i ./key-pairs/key-${resource_name}.pem ./user-key/${resource_name}'-user.txt' ubuntu@${instance_ip}:~/
  echo "copied"

  #run code in instance
  echo "running script"
  yes yes | sudo ssh -i ./key-pairs/key-${resource_name}.pem ubuntu@${instance_ip} "sudo ./remote.sh $resource_name"

}

#calling all functions
function runScript() {

  source ./create-instance.sh

  #create instance
  createVpc
  createSubnet
  createInternetGateway
  attachIgw
  createRouteTable
  createRoute
  associateRouteTable
  createSecurityGroup
  authorizeSecurityGroup
  createKeyPair
  createInstance

  #create user
  createUser
  putPermission
  attachPolicy
  createAccessKey
  createSecretAccessKey

  source ./create-bucket.sh

  #create and upload index.html file to s3
  createIndex
  createBucket
  upload


  #taking necessary information and calling the function to copy the code
  resourcesIds="./resources_ids/$resource_name.txt"
  instance_id=$(grep "i-" $resourcesIds)
  instance_ip=$(aws ec2 describe-instances \
    --filters \
    "Name=instance-state-name,Values=running" \
    "Name=instance-id,Values=${instance_id}" \
    --query 'Reservations[*].Instances[*].[PublicIpAddress]' \
    --output text)

  copyCode $resource_name $instance_ip

}

#calling necessary functions to delete project
function deleteScript() {
  #passing resource name
  resource_name=$1

  source ./delete.sh

  #terminate instance
  terminateInstance
  deleteKeyPair
  deleteSecurityGroup
  deleteSubnet
  deleteRouteTable
  detachIgw
  deleteInternetGateway
  deleteVpc

  #delete user
  deleteAccessKey
  detachUserPolicy
  deleteUser

  source ./create-bucket.sh

  #delete s3 bucket
  emptyBucket
  deleteBucket
}


#taking input from user to create or delete project
echo "Type [create] to run the script"
echo "Type [delete] to delete created resources"

read task

if [[ -n $task ]]; then
  if [[ $task == "create" ]]; then
    runScript
  elif [[ $task == "delete" ]]; then
    echo "Enter projects name you want to delete"
    read project_name

    if [[ -n  $project_name ]]; then
      if [[ -f ./resources_ids/$project_name.txt ]]; then
        deleteScript $project_name
      else
        echo "Project does not exist"
      fi
    else
      echo "Enter project name"
    fi
  else
    echo "Try again"
  fi
else
  echo "Enter the command"
fi
