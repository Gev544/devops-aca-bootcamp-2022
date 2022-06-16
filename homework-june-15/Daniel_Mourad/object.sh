#!/bin/bash

# This script will upload/delete object

set -e

fileName=$2
bucketName=$3


# Generates simple Hello World! html file
function generateHtml () {
    echo "Generating ($fileName)..."
    echo -e "<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello World!</title>
</head>
<body>
    <h1>Hello World!</h1>
</body>
</html>" > $fileName && \
    echo "Done."
}


# Uploads object to specified bucket
function uploadObject () {
    echo "Uploading object ($fileName) to bucket ($bucketName)..."
    aws s3api put-object \
        --bucket $bucketName \
        --key $fileName \
        --body $fileName \
        --output text > /dev/null && \
    rm -f $fileName && \
    echo "Done."

}

# Deletes object from spceified bucket
function deleteObject () {
    echo "Deleting object ($fileName) from bucket ($bucketName)..."
    aws s3api delete-object \
        --bucket $bucketName \
        --key $fileName && \
    echo "Done."

}

if [[ $1 = "--upload" ]] && [[ $fileName ]] && [[ ! -z $bucketName ]]
then
    generateHtml && uploadObject
elif [[ $1 = "--delete" ]] && [[ ! -z $fileName ]] && [[ ! -z $bucketName ]]
then
    deleteObject
else
    echo " "
    echo "This script uploads/deletes objects to/from Amazon Web Services"
    echo " "
    echo "  --upload -> uploads object | The file and bucket name needs to be specified"
    echo "example -> ./object.sh --upload example.html example-bucket"
    echo " "
    echo "  --delete -> deletes object | The object and bucket name needs to be specified"
    echo "example -> ./object.sh --delete example.html example-bucket"
    echo " "
fi