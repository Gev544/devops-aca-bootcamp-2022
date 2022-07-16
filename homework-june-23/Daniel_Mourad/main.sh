#!/bin/bash

# This is the main script which will run the other scripts

projectName="aca-homework"

# EC2 related variables
resources="${projectName}-resources.txt"
InstaceSshKeyName="${projectName}-ec2-key"
instanceUsername="ubuntu"

# Other scripts
remoteScript="remote.sh"
websiteScript="website.sh"



# Creates VPC, Subnet, Internet Gateway, Route Table, Security Group and Ubuntu EC2 Instance
function runInstances () {
    bash ec2.sh --create $projectName
    if [[ $? != 0 ]]; then
        echo "Something went wrong."
        cleanUp
    fi
}


# Removes the VPC, Subnet, Internet Gateway, Route Table, Security Group and the EC2 Instance
function deleteInstances () {
    bash ec2.sh --delete $projectName
    if [[ $? != 0 ]]; then
        echo "Something went wrong."
        cleanUp
    fi
}


# Creates DNS record with the public ip of EC2 Instance
function createRecord () {
    instancePublicIp=$(grep "ip-" $resources | cut -d "-" -f 2)
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
    instancePublicIp=$(grep "ip-" $resources | cut -d "-" -f 2)
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
    instancePublicIp=$1
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
            ${projectName} ${instanceUsername} ${websiteScript}"
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
    bash ec2.sh --delete $projectName
    echo "Done."
    exit 1
}



if [[ $1 = "--create" ]]; then
    runInstances && \
    instancePublicIp=$(grep "ip-" $resources | cut -d "-" -f 2) && \
    runRemote $instancePublicIp && \
    instancePublicIp=$(grep -A 1 "ip-" $resources | tail -1) && \
    runRemote $instancePublicIp && \
    bash ec2.sh --show-resources $projectName
elif [[ $1 = "--delete" ]]; then
    deleteInstances
fi