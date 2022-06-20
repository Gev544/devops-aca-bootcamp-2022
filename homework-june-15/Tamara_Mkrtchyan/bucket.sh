#!/bin/bash

# colored bash:)
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
Blue='\033[0;34m'
Reset='\033[0m'

command=$1
name=$2
bucketName=$name-bucket-aca
bucketRegion="us-east-1"
aclValue="public-read"
objectName="index.html"

# this function is being called after every command to check for a return value
# if the return value is not success then it deletes previously created all resources
check_for_error () {
	if [[ $? != 0 ]]; then
		echo -e "${Yellow}An error occured while $1\nshould delete everything now${Reset}"
		# delete html file if it exists with
		# aws s3api get-object --bucket $bucketName --key $objectName /dev/null >/dev/null; echo $?
		aws s3api delete-bucket \
		--bucket $bucketName \
		--region $bucketRegion && \
		aws s3api wait bucket-not-exists \
		--bucket $bucketName
		echo -e "${Red}$bucketName deleted !${Reset}"
		exit 1
	fi
}

# check and add error msg, bucket name should be unique
create_bucket () {
	bucketUrl=$(aws s3api create-bucket \
			--acl $aclValue \
			--bucket $bucketName \
			--region $bucketRegion)
	if [[ $? == 254 ]]; then
		echo -e "The requested bucket name is not available.\n\
		The bucket namespace is shared by all users of the system.\n\
		Please select a different name and try again."
	fi
	echo -e "${Yellow}Waiting for bucket exisitng confirmation..${Reset}"
	aws s3api wait bucket-exists \
		--bucket $bucketName
	echo -e "${Green}${bucketName} created successfully !${Reset}"
}

create_html () {
	echo "<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>Hey!</title>
</head>
<body>
	<h1>Hello World!</h1>
</body>
</html>" > $objectName
}

# copying the index.html file to our new bucket
upload_file () {
	aws s3api put-object \
	--bucket $bucketName \
	--acl $aclValue \
	--key $objectName \
	--body $objectName \
	--content-language html \
	--output text >/dev/null && \
	check_for_error "uploading a file to bucket"
	echo -e "${Yellow}Waiting for $objectName to upload...${Reset}"
	aws s3api wait object-exists \
	--bucket $bucketName \
	--key $objectName && \
	objectUrl="http://$bucketName.s3.amazonaws.com/$objectName"
	echo -e "${Green}$objectName uploaded successfully !${Reset}"
}

# creating ec2 instance
create_ec2 () {
	./aws_ec2 --create $name
	instanceId=$(grep "i-" $name-ids)
	publicIp=$(aws ec2 describe-instances \
				--instance-id $instanceId \
				--query 'Reservations[*].Instances[*].PublicIpAddress' \
				--output text)
	# waiting for the instance state to be OK, so we can work with it
	echo -e "${Yellow}waiting for an instance to start...${Reset}"
	aws ec2 wait instance-status-ok \
		--instance-ids $instanceId
	echo -e "${Green}$name instance is up and running !${Reset}"
}

delete_object () {

}

delete_bucket () {

}

delete_ec2 () {

}

delete_instance () {

}

config_ec2 () {
# add ec2 host key to our known hosts file (ssh-keyscan)
# copy nginx installation and configuration script to ec2 (scp)
# download index.html on instance
# run the nginx installation and configuration script
}

if [[ $command = "--create" ]]; then
# 
elif [[ $command = "--delete" ]]; then
# 
fi