#!/bin/bash

# Bucket related variables
bucketName="aca-homework"
bucketRegion="eu-central-1"
bucketAcl="private"
bucketUrl=

# Object related variables
objectName="index.html"
objectAcl="private"

# EC2 related variables
projectName="aca-homework"
resourceIds="${projectName}-resources.txt"
sshKeyName="${projectName}-ec2-key"
instanceUsername="ubuntu"
instancePublicIp=

# Other scripts
remoteScript="remote.sh"
websiteScript="website.sh"

# IAM related variables
iamUserName="aca-homework"
iamUserPermission="arn:aws:iam::aws:policy/AmazonS3FullAccess"
iamUserCredentialsFile="${iamUserName}-credentials.csv"


# Creates Bucket with above defined variables using as arguments
function createBucket () {
    echo "Creating S3 bucket ($bucketName) in region ($bucketRegion)..."
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
    echo "Deleting S3 bucket ($bucketName) from region ($bucketRegion)..."
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
    echo "Uploading object ($objectName) to S3 bucket ($bucketName)..."
    aws s3api put-object \
        --acl $objectAcl \
        --bucket $bucketName \
        --key $objectName \
        --body $objectName \
        --output text > /dev/null && \
    objectUrl="http://${bucketName}.s3.amazonaws.com/${objectName}" && \
    rm -f $objectName
    if [[ $? != 0 ]]; then
        cleanUp
    else
        echo "Done."
        echo "You can find your object at $objectUrl"
    fi
}


# Deletes object from bucket
function deleteObject () {
    echo "Deleting object ($objectName) from S3 bucket ($bucketName)..."
    aws s3api delete-object \
        --bucket $bucketName \
        --key $objectName
    if [[ $? != 0 ]]; then
        cleanUp
    else
        echo "Done."
    fi
}


# Creates IAM user
function createUser () {
    echo "Creating IAM user ($iamUserName)..."
    aws iam create-user \
        --user-name $iamUserName \
        --permissions-boundary $iamUserPermission \
        --output text > /dev/null
    if [[ $? != 0 ]]; then
        cleanUp
    else
        echo "Done."
    fi
}


# Creates Access Key for IAM user
function createAccessKey () {
    echo "Creating Access Key for user ($iamUserName)..."
    aws iam create-access-key \
        --user-name $iamUserName \
        --output text > $iamUserCredentialsFile && \
    accessKeyId=$(cat $iamUserCredentialsFile | cut -d "	" -f 2) && \
    accessKeySecret=$(cat $iamUserCredentialsFile | cut -d "	" -f 4) && \
    echo "Done."
}


# Deletes Access Key of IAM user
function deleteAccessKey () {
    echo "Deleting Access Key of user ($iamUserName)..."
    accessKeyId=$(cat $iamUserCredentialsFile | cut -d "	" -f 2) && \
    aws iam delete-access-key \
        --user-name $iamUserName \
        --access-key-id $accessKeyId && \
    rm -f $iamUserCredentialsFile && \
    echo "Done."
}


# Deletes IAM user
function deleteUser () {
    echo "Deleting IAM user ($iamUserName)..."
    aws iam delete-user \
        --user-name $iamUserName
    echo "Done."
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
    echo "Adding EC2 host key to known_hosts..." && \
    ssh-keyscan $instancePublicIp >> ~/.ssh/known_hosts 2> /dev/null && \
    echo "Copying ($remoteScript) and ($websiteScript) to remote EC2 Instance..." && \
    scp -i ${sshKeyName}.pem ./${remoteScript} \
        ${instanceUsername}@${instancePublicIp}:/home/${instanceUsername}/${remoteScript} && \
    scp -i ${sshKeyName}.pem ./${websiteScript} \
        ${instanceUsername}@${instancePublicIp}:/home/${instanceUsername}/${websiteScript} && \
    echo "Running ($remoteScript) on remote EC2 Instance..." && \
    ssh -i ${sshKeyName}.pem ${instanceUsername}@${instancePublicIp} \
        "sudo bash /home/${instanceUsername}/${remoteScript} ${accessKeyId}:${accessKeySecret}"
    if [[ $? != 0 ]]; then
        cleanUp
    else
        echo "Done."
    fi
}


# Cleans up if something goes wrong
function cleanUp () {
    echo "Something went wrong."
    echo "Cleaning up..."
    aws s3api delete-object --bucket $bucketName --key $objectName
    aws s3api delete-bucket --bucket $bucketName --region $bucketRegion
    ./ec2.sh --delete $projectName
    deleteAccessKey
    deleteUser
    echo "Done."
    exit 1
}


if [[ $1 = "--create" ]]; then
    createBucket && \
    generateHtml && \
    uploadObject && \
    createUser && \
    createAccessKey && \
    runInstance && \
    runRemote
elif [[ $1 = "--delete" ]]; then
    deleteObject && \
    deleteBucket && \
    deleteAccessKey && \
    deleteUser && \
    deleteInstance
fi