#!/bin/bash

projectName=$2
resourceIds="${projectName}-resources.txt"
domainName="${projectName}"
recordConfigFile="route53config.json"
instancePublicIp=$(grep "ip-" $resourceIds | cut -d "-" -f 2)

# Creates DNS record with the public ip of EC2 Instance
function createRecord () {
	echo "Creating DNS Record..."
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
	rm -f ${recordConfigFile} && \
	echo "Done."
}


# Deletes DNS record with the public ip of EC2 Instance
function deleteRecord () {
	echo "Deleting DNS Record..."
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
	rm -f ${recordConfigFile} && \
	echo "Done."
}

if [[ $1 = "--add-record" ]]; then
    createRecord
elif [[ $1 = "--remove-record" ]]; then
    deleteRecord
fi