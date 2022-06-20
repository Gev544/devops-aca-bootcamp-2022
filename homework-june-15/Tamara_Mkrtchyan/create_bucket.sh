#!/bin/bash

# colored bash:)
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
Blue='\033[0;34m'
Reset='\033[0m'

bucketName=$2-bucket-aca
bucketRegion="us-east-1"
bucketAcl="public-read"

helloWorld="index.html"

# this function is being called after every command to check for a return value
# if the return value is not success then it deletes previously created all resources
check_for_error () {
	if [[ $? != 0 ]]; then
		echo -e "${Yellow}An error occured while $1\nshould delete everything now${Reset}"
		aws s3api delete-object \
		--key nginx_install.sh \
		--bucket $helloWorld
		aws s3api delete-bucket \
		--bucket $bucketName \
		--region $bucketRegion
		exit 1
	fi
}

# check and add error msg, bucket name should be unique
create_bucket () {
bucketUrl=$(aws s3api create-bucket \
		--acl $bucketAcl \
		--bucket $bucketName \
		--region $bucketRegion)
if [[ $? == 254 ]]; then
	echo -e "The requested bucket name is not available.\nThe bucket namespace is shared by all users of the system.\nPlease select a different name and try again."
fi
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
</html>" > $helloWorld
}

# copying the index.html file to our new bucket
aws s3 cp ./index.html s3://$2-bucket

# creating ec2 instance
./aws_ec2 --create $name

instanceId=$(grep "i-" $name-ids)
publicIp=$(aws ec2 describe-instances \
			--instance-id $instanceId \
			--query 'Reservations[*].Instances[*].PublicIpAddress' \
			--output text)

# waiting for the instance state to be OK, so we can ssh into it
echo -e "${Yellow}waiting for an instance to start...${Reset}"
aws ec2 wait instance-status-ok \
	--instance-ids $instanceId

