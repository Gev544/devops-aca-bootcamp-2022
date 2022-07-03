#!/bin/bash
# This script will create all required aws resources and launch ec2 instance from IAM........... acaunt in us-west 2 region, Please make sure that you know what are you doing. It is required to have 'ec2, s3, nginx, sources.list' files in the same directory as install.sh and uninstall.sh
#Resource names, ID-s, IP-s and other information abault created resources will be stored in sources.list untill uninstallation
# !!!!!!!!!!!!!!Do not run this script more than once!!!!!!!!!!!!!!!! otherwise you would have to manualy delete all created resources
#If something goes wrong please manually run uninstall.sh to delete all created resources

source sources.list 2>/dev/null
set -e

#Run script to create s3 bucket
bash ./s3
echo 's3 script ended'
#Run script to launch ec2
bash ./ec2


#Adding information aws config and cred
#echo "awsconfig=$(cat ~/.aws/config)" >> sources.list
#echo "awscredentials=$(cat ~/.aws/credentials)" >> sources.list

source sources.list 2>/dev/null
echo "$PUBLIC_IP instance launched"
sleep 10
set +e
#Run remote commands
echo 'start ssh part' | ssh -o StrictHostKeyChecking=no -i /home/narek/.ssh/sshkeygenerated.pem  ubuntu@$PUBLIC_IP 'sudo bash -s'

scp -o StrictHostKeyChecking=no -i /home/narek/.ssh/sshkeygenerated.pem /home/narek/.aws/config ubuntu@$PUBLIC_IP:/home/ubuntu
scp -o StrictHostKeyChecking=no -i /home/narek/.ssh/sshkeygenerated.pem /home/narek/.aws/credentials ubuntu@$PUBLIC_IP:/home/ubuntu
cat ./nginx | ssh -o StrictHostKeyChecking=no -i /home/narek/.ssh/sshkeygenerated.pem  ubuntu@$PUBLIC_IP 'sudo bash -s' 2>&1



#cat ./testfile	| ssh -o StrictHostKeyChecking=no -i /home/narek/.ssh/sshkeygenerated.pem  ubuntu@$PUBLIC_IP 'sudo bash -s' 2>./logs



#ssh to EC2
#ssh -o StrictHostKeyChecking=no -i /home/$(whoami)/.ssh/sshkeygenerated.pem ubuntu@$PUBLIC_IP
#sleep 5

#ssh ubuntu@$PUBLIC_IP echo "thats All" 

#if [ ! ssh $PUBLIC_IP ];
#then    
#echo "no ssh"
#else
#echo "ssh connection established"
#fi

