#!/bin/bash

set -e

if [[ $1 = "create" ]]
then
./create-aws-ec2.sh create && ./s3files.sh create
elif [[ $1 = "delete" ]]
then
./s3files delete && ./create-aws-ec2.sh delete
else echo "Need an Argument \n  create\delete"
fi