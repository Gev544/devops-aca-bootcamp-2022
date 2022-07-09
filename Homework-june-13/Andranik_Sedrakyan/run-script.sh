#!/bin/bash

#calling all functions
function runScript() {
  source ./create.sh

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
}

#calling necessary functions to delete project
function deleteScript() {
  #passing resource name
  resource_name=$1

  source ./delete.sh

  terminateInstance
  deleteKeyPair
  deleteSecurityGroup
  deleteSubnet
  deleteRouteTable
  detachIgw
  deleteInternetGateway
  deleteVpc
}


#taking input from user to create or delete project
echo "Type [create] to create VPC, Subnet, Internet Gateway, Route Table,
Security Group, SSH Key Pair and Launch Instance "
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
