#!/bin/bash

bucketName="aca-homework"
userName="aca-homework"
userPermission="arn:aws:iam::aws:policy/AmazonS3FullAccess"
credentialsFile="${userName}-access-key.csv"
mountLocation="/s3"


# Creates IAM user
function createUser () {
    echo "Creating IAM user ($userName)..."
    aws iam create-user \
        --user-name $userName \
        --permissions-boundary $userPermission \
        --output text > /dev/null
    echo "Done."
}


# Creates Access Key for IAM user
function createAccessKey () {
    echo "Creating Access Key for user ($userName)..."
    aws iam create-access-key \
        --user-name $userName \
        --output text > $credentialsFile && \
    accessKeyId=$(cat $credentialsFile | cut -d "	" -f 2) && \
    accessKeySecret=$(cat $credentialsFile | cut -d "	" -f 4) && \
    echo "Done."
}


# Deletes Access Key of IAM user
function deleteAccessKey () {
    echo "Deleting Access Key of user ($userName)..."
    accessKeyId=$(cat $credentialsFile | cut -d "	" -f 2) && \
    aws iam delete-access-key \
        --user-name $userName \
        --access-key-id $accessKeyId && \
    rm -f $credentialsFile && \
    echo "Done."
}


# Deletes IAM user
function deleteUser () {
    echo "Deleting IAM user ($userName)..."
    aws iam delete-user \
        --user-name $userName
    echo "Done."
}


# Installs s3fs and configures access key
function installAndMountS3 () {
    echo "Installing and configuring s3fs..."
    apt update -y && apt install s3fs -y && \
    echo ${accessKeyId}:${accessKeySecret} > /etc/.passwd-s3fs && \
    chmod 400 /etc/.passwd-s3fs && \
    mkdir -p $mountLocation && chmod 777 $mountLocation && \
    s3fs $bucketName $mountLocation -o passwd_file=/etc/.passwd-s3fs && \
    echo "Done."
}




createUser && createAccessKey && installAndMountS3

# deleteAccessKey && deleteUser