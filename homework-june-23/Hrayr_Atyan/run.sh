#!/bin/bash

domain=aca-aws.mouradyan.xyz
Instance_ID=i-0853b1e3c75eaa1ef
certificate_ARN=arn:aws:acm:us-east-1:795422140241:certificate/47deeb2f-00ce-4652-bc5d-0d0ce9b641e8 ertificate_ARN=arn:aws:acm:us-east-1:795422140241:certificate/47deeb2f-00ce-4652-bc5d-0d0ce9b641e8
key_path=/home/hro/.ssh/MyKeyPair.pem
Bucket_name=bucket.aca

#checking if instance id is valid
aws ec2 describe-instances --instance-ids $Instance_ID 1>/dev/null 2>/dev/null

if [ ! $? -eq 0 ]
then
	echo "Instance ID is incorrect"
	exit
fi

#checking if certificate arn is valid
aws acm describe-certificate \
    --certificate-arn $certificate_ARN \
    1>/dev/null 2>/dev/null

if [ ! $? -eq 0 ]
then
	echo "Certificate ARN is incorrect"
	exit
fi

#checking if key exists
if [ ! -f $key_path ]
then
	echo "Key file doesn't exist"
	exit
fi

#getting it's ip address
ip_address=$(aws ec2 describe-instances \
    --instance-ids $Instance_ID \
    --query Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicIp \
    --output text)

zone_id=$(aws route53 list-hosted-zones-by-name  \
            --dns-name $domain \
             --output text \
            --query HostedZones[0].Id | grep -o "Z\w*")

#checking if zone id is valid
if [ -z $zone_id ]
then
    echo "Can't get the Hosted Zone id"
    exit
fi

#Creating json file to update dns zone

echo    '{
                "Comment": "Domain for our web page",
                "Changes": [ {
                             "Action": "UPSERT",
                            "ResourceRecordSet": {
                                "Name": "'$domain'",
                                    "Type": "A",
                                     "TTL": 300,
                                  "ResourceRecords": [{"Value": "'$ip_address'"}]
                            }
                }]
}' > dns_conf.json

#Updating the zone
aws route53 change-resource-record-sets \
    --hosted-zone-id $zone_id \
    --change-batch file://dns_conf.json 1>/dev/null

#deleting that file
rm -f dns_conf.json

#cp certificate configuration files to server
echo "Copying certificate configuration files to server.."
scp -oStrictHostKeyChecking=accept-new -i $key_path cert/* ubuntu@$ip_address:.
ssh -i $key_path ubuntu@$ip_address 'sudo ./ssl_conf.sh'

if [ ! $? -eq 0 ]
then
	echo "Cant connect to instance via ssh"
	exit
fi


#Openning HTTPS in Sec Group
sg_id=$(aws ec2 describe-instances \
        --instance-ids $Instance_ID \
        --query Reservations[0].Instances[0].SecurityGroups[0].GroupId \
        --output text)

aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 443 --cidr 0.0.0.0/0


#--------Part 2------


#Launching new instance
echo "Launching second instance.."
./ec2_conf.sh $Instance_ID

if [ ! $? -eq 0 ]
then
    echo "Can't launch Second instance"
    exit
fi

#Getting its IP address
Second_Instance_IP=$(tail -1 ids)

#installing and confinguaring second web server
echo "installing and confinguring second web server"

#Copying files to instance and runnig them
scp -oStrictHostKeyChecking=accept-new -i $key_path  clone/* clone/.passwd-s3fs ubuntu@$Second_Instance_IP:. && \
ssh -i $key_path  ubuntu@$Second_Instance_IP  "sudo ./run.sh $Bucket_name"

#cp certificate configuration files to server
echo "Configuring certificate on it"
scp -oStrictHostKeyChecking=accept-new -i $key_path cert/* ubuntu@$Second_Instance_IP:.  && \
ssh -i $key_path ubuntu@$Second_Instance_IP 'sudo ./ssl_conf.sh'

#configuaring ALB
./alb_conf.sh $domain $certificate_ARN && \
echo "Done!"
