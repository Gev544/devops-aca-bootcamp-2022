#!/bin/bash

# Bucket related variables
bucketName="aca-homework"
bucketRegion="eu-central-1"
bucketAcl="public-read"
bucketUrl=

# Object related variables
objectName="helloworld.html"
objectAcl="public-read"

# EC2 related variables
projectName="aca-homework"
resourceIds="${projectName}-resources.txt"
sshKeyName="${projectName}-ec2-key"
instanceUsername="ubuntu"
instancePublicIp=

remoteScript="remote.sh"


# Creates Bucket with above defined variables using as arguments
function createBucket () {
    echo "Creating bucket ($bucketName) in ($bucketRegion)..."
    bucketUrl=$(aws s3api create-bucket \
        --bucket $bucketName \
        --region $bucketRegion \
        --create-bucket-configuration LocationConstraint=$bucketRegion \
        --acl $bucketAcl \
        --output text)
    if [[ $? != 0 ]]; then
        cleanUp
    else
        echo "Done."
        echo "You can find your bucket at $bucketUrl"
    fi
}


# Deletes Bucket using name and region
function deleteBucket () {
    echo "Deleting bucket ($bucketName) from ($bucketRegion)..."
    aws s3api delete-bucket \
        --bucket $bucketName \
        --region $bucketRegion
    if [[ $? != 0 ]]; then
        cleanUp
    else
        echo "Done."
    fi
}


# Generates simple Hello World! html file
function generateHtml () {
    echo "Generating ($objectName)..."
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
</html>" > $objectName
    if [[ $? != 0 ]]; then
        cleanUp
    else
        echo "Done."
    fi
}


# Uploads object to bucket and deletes from local
function uploadObject () {
    echo "Uploading object ($objectName) to bucket ($bucketName)..."
    aws s3api put-object \
        --acl $objectAcl \
        --bucket $bucketName \
        --key $objectName \
        --body $objectName \
        --output text > /dev/null
    rm -f $objectName
    objectUrl="http://${bucketName}.s3.amazonaws.com/${objectName}"
    if [[ $? != 0 ]]; then
        cleanUp
    else
        echo "Done."
        echo "You can find your object at $objectUrl"
    fi
}


# Deletes object from bucket
function deleteObject () {
    echo "Deleting object ($objectName) from bucket ($bucketName)..."
    aws s3api delete-object \
        --bucket $bucketName \
        --key $objectName
    if [[ $? != 0 ]]; then
        cleanUp
    else
        echo "Done."
    fi
}


# Creates VPC, Subnet, Internet Gateway, Route Table, Security Group and Ubuntu EC2 Instance
function runInstance () {
    ./ec2.sh --create $projectName
    instancePublicIp=$(grep "ip-" $resourceIds | cut -d "-" -f 2)
    if [[ $? != 0 ]]; then
        cleanUp
    fi
}


# Removes the VPC, Subnet, Internet Gateway, Route Table, Security Group and the EC2 Instance
function deleteInstance () {
    ./ec2.sh --delete $projectName
    if [[ $? != 0 ]]; then
        cleanUp
    fi
}


# Copies remote script and runs on remote server and downloads object from S3 on remote
function runRemote () {
    echo "Adding EC2 host key to known_hosts..."
    ssh-keyscan $instancePublicIp >> ~/.ssh/known_hosts 2> /dev/null
    if [[ $? != 0 ]]; then
        cleanUp
    else
        echo "Done."
    fi

    echo "Copying ($remoteScript) to remote EC2 Instance..."
    scp -i ${sshKeyName}.pem ./${remoteScript} \
        ${instanceUsername}@${instancePublicIp}:/home/${instanceUsername}/${remoteScript}
    if [[ $? != 0 ]]; then
        cleanUp
    else
        echo "Done."
    fi

    echo "Downloading ($objectName) on remote EC2 Instance..."
    ssh -i ${sshKeyName}.pem ${instanceUsername}@${instancePublicIp} "wget --quiet $objectUrl"
    if [[ $? != 0 ]]; then
        cleanUp
    else
        echo "Done."
    fi

    echo "Running ($remoteScript) on remote EC2 Instance..."
    ssh -i ${sshKeyName}.pem ${instanceUsername}@${instancePublicIp} \
        "sudo bash /home/${instanceUsername}/${remoteScript}"
    if [[ $? != 0 ]]; then
        cleanUp
    else
        echo "Done."
    fi
}


# Cleans up if something goes wrong
function cleanUp () {
    set +e
    echo "Something went wrong."
    echo "Cleaning up..."
    aws s3api delete-object --bucket $bucketName --key $objectName
    aws s3api delete-bucket --bucket $bucketName --region $bucketRegion
    ./ec2.sh --delete $projectName
    echo "Done."
}


if [[ $1 = "--create" ]]; then
    createBucket && \
    generateHtml && \
    uploadObject && \
    runInstance && \
    runRemote
elif [[ $1 = "--delete" ]]; then
    deleteObject && \
    deleteBucket && \
    deleteInstance
fi