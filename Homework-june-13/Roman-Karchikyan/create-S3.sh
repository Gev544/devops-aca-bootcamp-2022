#!/bin/bash

ERRCODE=0
region="us-east-1"

# Bucket name
BName="site-demo-451"

function cleanUp () {
  echo "-Some error occurred, cleaning files..."

  if [[ $1 -eq 2 ]]
  then 
      aws s3api delete-bucket --bucket $BName --region $region &&
      echo "-Bucket deleted successfully" || echo "-Warning: Couldn't delete bucket !"
  else
      echo "-Bucket did't create"
  fi
}

# Create an s3 bucket
aws s3 mb s3://$BName --region $region || ((ERRCODE=ERRCODE+1))

# Copy project into the bucket
aws s3 cp --recursive Project_X s3://$BName || ((ERRCODE=ERRCODE+2))

# If there was any errors occurred do cleanUp
if [[ $ERRCODE -gt 0 ]]
then
    cleanUp $ERRCODE
else 
    echo "-Bucket created, project added successfully"
fi    
