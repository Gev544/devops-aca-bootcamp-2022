#!/bin/bash

# this script will create/delete the bucket

set -e

region="eu-central-1"
bucketName="aca-bucket-homework-2"
bucketType="public-read"
bucketInfo="bucket_info.txt"
bucketURL=

# creates bucket with above defined variables using as arguments
function createBucket () {
    echo "Creating bucket $bucketName in $region ..."
    aws s3api create-bucket \
        --bucket $bucketName \
        --acl $bucketType \
        --region $region \
        --create-bucket-configuration LocationConstraint=$region \
        --output text > $bucketInfo && \
    echo "Done."
    bucketURL=$(cat $bucketInfo | head -1)
    echo "You can find your bucket at $bucketURL"
}

# deletes bucket and bucket_info.txt file which conatins bucket's URL
function deleteBucket () {
    echo "Deleting bucket $bucketName in $region ..."
    aws s3api delete-bucket \
        --bucket $bucketName \
        --region $region && \
        rm -f $bucketInfo && \
    echo "Done."
}

if [[ $1 = "--create" ]]
then
    createBucket
elif [[ $1 = "--delete" ]]
then
    deleteBucket
else
    echo "--create -> create bucket"
    echo "--delete -> delete bucket"
fi