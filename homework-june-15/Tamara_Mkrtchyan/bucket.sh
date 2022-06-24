#!/bin/bash

# colored bash:)
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
Blue='\033[0;34m'
Reset='\033[0m'

# initiating variables for bucket and objects
option=$1
name=$2
bucketName="$name-bucket-aca"
bucketRegion="us-east-1"
aclValue="public-read"
objectName="index.html"

# deletes all objects in given s3 bucket
delete_objects () {
# get all s3 objects listed in a temporary file
	aws s3api list-objects --bucket $bucketName --query 'Contents[].{Key: Key}' --output text > ./s3_obj_list
# recoursively delete all the objects in s3 bucket
	if [[ $(cat ./s3_obj_list) != "None" ]]; then
		for obj in $(cat ./s3_obj_list); do
			aws s3api delete-object --bucket $bucketName --key $obj && \
			aws s3api wait object-not-exists --bucket $bucketName --key $obj
			echo -e "${Red}$obj file from s3 is deleted${Reset}"
		done
# deletes the temporary file
		rm ./s3_obj_list
	fi
}

# deletes the prevously created bucket
delete_bucket () {
	aws s3api delete-bucket \
		--bucket $bucketName \
		--region $bucketRegion && \
# waits for the bucket to confirm it's deletion
	aws s3api wait bucket-not-exists \
		--bucket $bucketName
		echo -e "${Red}$bucketName deleted !${Reset}"
}

# this function is being called after every command to check for a return value
# if the return value is not success then it deletes previously created all resources
check_for_error () {
	if [[ $? != 0 ]]; then
		echo -e "${Yellow}An error occured while $1\nshould delete everything now${Reset}"
		delete_objects && \
		delete_bucket
		if [[ ! -z $ec2Id ]]; then
			delete_ec2
		fi
		if [[ -f $objectName ]]; then
			rm -f $objectName
		fi
		exit 1
	fi
}

# creates an s3 bucket with given name
# if that name already exist in selected region then it prints corresponding error message
create_bucket () {
	bucketUrl=$(aws s3api create-bucket \
			--acl $aclValue \
			--bucket $bucketName \
			--region $bucketRegion)
	return_value=$?
# error 254 triggers if selected bucket name already exists
	if [[ $return_value == 254 ]]; then
		echo -e "${Red}The requested bucket name is not available.\n\
		The bucket namespace is shared by all users of the system.\n\
		Please select a different name and try again.${Reset}"
		exit 1
	elif [[ $return_value != 0 ]]; then
		echo -e "${Red}An error occured while creating the bucket\nerror: $?${Reset}"
		exit 1
	fi
	echo -e "${Yellow}Waiting for bucket exisitng confirmation...${Reset}"
# before working with s3 bucket we should be waiting for bucket exisitng confirmation..
	aws s3api wait bucket-exists \
		--bucket $bucketName
	echo -e "${Green}${bucketName} created successfully !${Reset}"
}

# creates an html file to upload to our bucket
create_html () {
	echo "<!DOCTYPE html>
<html lang=en>
<head>
	<meta charset=UTF-8>
	<meta http-equiv=X-UA-Compatible content=IE=edge>
	<meta name=viewport content=width=device-width, initial-scale=1.0>
	<title>USD Rate</title>
</head>
<body>
	<p style=\"text-align:center\"><span style=\"font-size:26px\"><strong>Exchange Rates</strong></span></p>
	<p style=\"text-align:center\"><span style=\"color:\#0a3325\"><span style=\"font-size:20px\">Ameria bank</span></span></p>
	<hr />
	<table border=\"1\" cellpadding=\"1\" cellspacing=\"1\" style=\"width:500px\" align=\"center\">
		<thead>
			<tr>
				<th scope=\"col\">BUY</th>
				<th scope=\"col\">SELL</th>
			</tr>
		</thead>
		<tbody>
			<tr>
				<td style=\"text-align:center\">&nbsp;</td>
				<td style=\"text-align:center\">&nbsp;</td>
			</tr>
		</tbody>
	</table>
</body>
</html>" > $objectName
}

# uploading the index.html file to our new bucket
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
	echo -e "${Green}$objectName uploaded successfully ! -> ${Blue}${objectUrl}${Reset}"
}

# creating ec2 instance with the same name as our bucket
create_ec2 () {
	./aws_ec2.sh --create $name
	check_for_error "creating an instance"
	# waiting for the instance state to be OK, so we can work with it
	echo -e "${Yellow}waiting for an instance to start...${Reset}"
	aws ec2 wait instance-status-ok \
		--instance-ids $instanceId
	echo -e "${Green}$name instance is up and running !${Reset}"
}

# deleting created ec2 instance with its resouces and unsetting created variables
delete_ec2 () {
	./aws_ec2 --delete $name
	unset ec2User ec2Id ec2PublicIp ec2RemoteScript
}

# this function copies remote working script to ec2 instance via scp and executes it via ssh
config_ec2 () {
	ec2User="ubuntu"
	ec2Id=$(grep "i-" $name-ids)
	ec2PublicIp=$(aws ec2 describe-instances \
	--instance-id $instanceId \
	--query 'Reservations[*].Instances[*].PublicIpAddress' \
	--output text)
	ec2RemoteScript="remote_nginx_conf.sh"
# add ec2 host key to our known hosts file (ssh-keyscan)
	ssh-keyscan $ec2publicIp >> ~/.ssh/known_hosts
	check_for_error "keyscanning the ec2 public ip to known hosts"
# copy nginx installation and configuration script to ec2 (scp)
	scp -i $name-keypair.pem $ec2RemoteScript \
		$ec2User@$ec2PublicIp:/home/$ec2User/$ec2RemoteScript
	check_for_error "copying remote script to ec2 instance"
# download index.html on instance
	ssh -i $name-keypair.pem $ec2User@$ec2PublicIp \
		wget $objectUrl
	check_for_error "downloading html file from s3 bucket to ec2 instance via wget"
# run the nginx installation and configuration script
	ssh -i $name-keypair.pem $ec2User@$ec2PublicIp \
		sudo bash /home/$ec2User/$ec2RemoteScript
	check_for_error "executing remote script in ec2 inastance"
}

# the script starts here
if [[ $option == "--create" ]] && [[ ! -z $name ]]; then
	create_bucket && \
	create_html && \
	upload_file && \
	create_ec2 && \
	config_ec2
elif [[ $option == "--delete" ]] && [[ ! -z $name ]]; then
	delete_objects && \
	delete_bucket && \
	delete_ec2
	unset option name bucketName bucketRegion bucketUrl aclValue objectName objectUrl
fi
