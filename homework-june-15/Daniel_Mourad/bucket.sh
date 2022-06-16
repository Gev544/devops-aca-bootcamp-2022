#!/bin/bash

# This script will create/delete bucket

set -e

bucketName=$2
bucketRegion=$3
bucketType=$4

# Creates Bucket with above defined variables using as arguments
function createBucket () {
    echo "Creating bucket ($bucketName) in ($bucketRegion)..."
    bucketURL=$(aws s3api create-bucket \
        --bucket $bucketName \
        --acl $bucketType \
        --region $bucketRegion \
        --create-bucket-configuration LocationConstraint=$bucketRegion \
        --output text) && \
    echo "Done." && \
    echo "You can find your bucket at $bucketURL"
}

# Deletes Bucket using name and region
function deleteBucket () {
    echo "Deleting bucket ($bucketName) from ($bucketRegion)..."
    aws s3api delete-bucket \
        --bucket $bucketName \
        --region $bucketRegion && \
    echo "Done."
}

if [[ $1 = "--create" ]] && [[ ! -z $bucketName ]] && [[ ! -z $bucketRegion ]] && [[ ! -z $bucketType ]]
then
    createBucket
elif [[ $1 = "--delete" ]] && [[ ! -z $bucketName ]] && [[ ! -z $bucketRegion ]]
then
    deleteBucket
else
    echo " "
    echo "This script creates/deletes buckets in/from Amazon Web Services"
    echo " "
    echo "  --create -> creates bucket | The Bucket name, region, access type needs to be specified"
    echo "example -> ./bucket.sh --create example-bucket eu-central-1 public-read"
    echo " "
    echo "  --delete -> deletes bucket | Only the name and region needs to be specified"
    echo "example -> ./bucket.sh --delete example-bucket eu-central-1"
    echo " "
fi