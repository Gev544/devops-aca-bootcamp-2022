#!/bin/bash
source ./Create_EC2_Instance
if [[ $? = 0 ]]
then 
echo "it is ok"
else
./Delete_ec2
fi
