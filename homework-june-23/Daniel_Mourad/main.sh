#!/bin/bash

# This is the main script which will run the other scripts

projectName="aca-homework"

# Bucket related variables
bucketName="aca-homework"
bucketRegion="eu-central-1"
bucketAcl="public-read-write"
bucketUrl=

# Object related variables
objectName="index.html"
objectAcl="public-read-write"
objectUrl=

# IAM related variables
iamUserName="aca-homework"
iamUserPermission="arn:aws:iam::aws:policy/AmazonS3FullAccess"
iamUserCredentials="${iamUserName}-credentials.csv"
iamUserAccessKeyId=
iamUserAccessKeySecret=

# EC2 related variables
resourceIds="${projectName}-resources.txt"
InstaceSshKeyName="${projectName}-ec2-key"
instanceUsername="ubuntu"
instancePublicIp=

# Other scripts
remoteScript="remote.sh"
websiteScript="website.sh"

# Route 53
domainName="${projectName}.$(cat hostedZone.txt)"
recordConfigFile="route53config.json"


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
        echo "Something went wrong."
        cleanUp
    else
        echo "You can find your bucket at $bucketUrl"
        echo "Done."
    fi
}


# Deletes Bucket using name and region
function deleteBucket () {
    echo "Deleting S3 bucket ($bucketName) from region ($bucketRegion)..."
    aws s3api delete-bucket \
        --bucket $bucketName \
        --region $bucketRegion
    if [[ $? != 0 ]]; then
        echo "Something went wrong."
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
        echo "Something went wrong."
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
        echo "Something went wrong."
        cleanUp
    else
        echo "You can find your object at $objectUrl"
        echo "Done."
    fi
}


# Deletes object from bucket
function deleteObject () {
    echo "Deleting object ($objectName) from S3 bucket ($bucketName)..."
    aws s3api delete-object \
        --bucket $bucketName \
        --key $objectName
    if [[ $? != 0 ]]; then
        echo "Something went wrong."
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
        echo "Something went wrong."
        cleanUp
    else
        echo "Done."
    fi
}


# Deletes IAM user
function deleteUser () {
    echo "Deleting IAM user ($iamUserName)..."
    aws iam delete-user \
        --user-name $iamUserName
    if [[ $? != 0 ]]; then
        echo "Something went wrong."
        cleanUp
    else
        echo "Done."
    fi
}


# Creates Access Key for IAM user
function createAccessKey () {
    echo "Creating Access Key for IAM user ($iamUserName)..."
    aws iam create-access-key \
        --user-name $iamUserName \
        --output text > $iamUserCredentials && \
    iamUserAccessKeyId=$(cat $iamUserCredentials | cut -d "	" -f 2) && \
    iamUserAccessKeySecret=$(cat $iamUserCredentials | cut -d "	" -f 4) && \
    if [[ $? != 0 ]]; then
        echo "Something went wrong."
        cleanUp
    else
        echo "Done."
    fi
}


# Deletes Access Key of IAM user
function deleteAccessKey () {
    echo "Deleting Access Key of IAM user ($iamUserName)..."
    iamUserAccessKeyId=$(cat $iamUserCredentials | cut -d "	" -f 2) && \
    aws iam delete-access-key \
        --user-name $iamUserName \
        --access-key-id $iamUserAccessKeyId && \
    rm -f $iamUserCredentials && \
    if [[ $? != 0 ]]; then
        echo "Something went wrong."
        cleanUp
    else
        echo "Done."
    fi
}


# Creates VPC, Subnet, Internet Gateway, Route Table, Security Group and Ubuntu EC2 Instance
function runInstance () {
    bash ec2.sh --create $projectName
    instancePublicIp=$(grep "ip-" $resourceIds | cut -d "-" -f 2)
    if [[ $? != 0 ]]; then
        echo "Something went wrong."
        cleanUp
    fi
}


# Removes the VPC, Subnet, Internet Gateway, Route Table, Security Group and the EC2 Instance
function deleteInstance () {
    bash ec2.sh --delete $projectName
    if [[ $? != 0 ]]; then
        echo "Something went wrong."
        cleanUp
    fi
}


# Creates DNS record with the public ip of EC2 Instance
function createRecord () {
    instancePublicIp=$(grep "ip-" $resourceIds | cut -d "-" -f 2)
    echo "Creating DNS Record ($domainName)..."
	echo -e '{
   "Comment": "Create A record ",
   "Changes": [{
   "Action": "CREATE",
               "ResourceRecordSet": {
                           "Name": "'$domainName'",
                           "Type": "A",
                           "TTL": 300,
                        "ResourceRecords": [{ "Value": "'$instancePublicIp'"}]
}}]
}' > ${recordConfigFile} && \
	aws route53 change-resource-record-sets \
		--hosted-zone-id $(aws route53 list-hosted-zones --output yaml | grep "Id" | cut -d "/" -f 3) \
		--change-batch file://${recordConfigFile} --output text > /dev/null && \
	rm -f ${recordConfigFile}
    if [[ $? != 0 ]]; then
        echo "Something went wrong."
        cleanUp
    else
    	echo "Done."
    fi
}


# Deletes DNS record with the public ip of EC2 Instance
function deleteRecord () {
    instancePublicIp=$(grep "ip-" $resourceIds | cut -d "-" -f 2)
    echo "Deleting DNS Record ($domainName)..."
	echo -e '{
   "Comment": "Create A record ",
   "Changes": [{
   "Action": "DELETE",
               "ResourceRecordSet": {
                           "Name": "'$domainName'",
                           "Type": "A",
                           "TTL": 300,
                        "ResourceRecords": [{ "Value": "'$instancePublicIp'"}]
}}]
}' > ${recordConfigFile} && \
	aws route53 change-resource-record-sets \
		--hosted-zone-id $(aws route53 list-hosted-zones --output yaml | grep "Id" | cut -d "/" -f 3) \
		--change-batch file://${recordConfigFile} --output text > /dev/null && \
	rm -f ${recordConfigFile}
    if [[ $? != 0 ]]; then
        echo "Something went wrong."
        cleanUp
    else
    	echo "Done."
    fi
}


# Copies remote script and runs on remote server and downloads object from S3 on remote
function runRemote () {
    echo "Adding EC2 host key to known_hosts..." && \
    ssh-keyscan $instancePublicIp >> ~/.ssh/known_hosts 2> /dev/null && \
    echo "Copying ($remoteScript) and ($websiteScript) to remote EC2 Instance..." && \
    scp -i ${InstaceSshKeyName}.pem ./${remoteScript} \
        ${instanceUsername}@${instancePublicIp}:/home/${instanceUsername}/${remoteScript} && \
    scp -i ${InstaceSshKeyName}.pem ./${websiteScript} \
        ${instanceUsername}@${instancePublicIp}:/home/${instanceUsername}/${websiteScript} && \
    echo "Running ($remoteScript) on remote EC2 Instance..." && \
    ssh -i ${InstaceSshKeyName}.pem ${instanceUsername}@${instancePublicIp} \
        "sudo bash /home/${instanceUsername}/${remoteScript} \
            ${projectName} ${instanceUsername} \
            ${websiteScript} ${bucketName} \
            ${iamUserAccessKeyId}:${iamUserAccessKeySecret} \
            ${domainName}"
    if [[ $? != 0 ]]; then
        echo "Something went wrong."
        cleanUp
    else
        echo "Done."
    fi
}


# Cleans up if something goes wrong
function cleanUp () {
    echo "Cleaning up..."
    aws s3api delete-object --bucket $bucketName --key $objectName
    aws s3api delete-bucket --bucket $bucketName --region $bucketRegion
    rm -f $objectName
    aws iam delete-access-key --user-name $iamUserName --access-key-id $iamUserAccessKeyId
    rm -f $iamUserCredentials
    aws iam delete-user --user-name $iamUserName
    deleteRecord
    bash ec2.sh --delete $projectName
    echo "Done."
    exit 1
}



if [[ $1 = "--create" ]]; then
    createBucket && \
    createUser && \
    createAccessKey && \
    runInstance && \
    createRecord && \
    runRemote && \
    bash ec2.sh --show-resources $projectName
elif [[ $1 = "--delete" ]]; then
    deleteObject && \
    deleteBucket && \
    deleteAccessKey && \
    deleteUser && \
    deleteRecord && \
    deleteInstance
fi