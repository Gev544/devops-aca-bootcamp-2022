#!/bin/bash

source sources.list


set +e
echo "Cleaning up..."
# ec 2
if [ ! -z $INSTANCE_ID ]
then
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --output text > /dev/null
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
fi
aws ec2 delete-key-pair --key-name $SSHKEY
aws ec2 delete-security-group --group-id $CUSTOM_SECURITY_GROUP_ID
aws ec2 delete-subnet --subnet-id $SUBNET_ID
aws ec2 delete-route-table --route-table-id $ROUTE_TABLE_ID
aws ec2 detach-internet-gateway --internet-gateway-id $INTERNET_GATEWAY_ID --vpc-id $VPC_ID
aws ec2 delete-vpc --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $INTERNET_GATEWAY_ID
rm -f /home/$(whoami)/.ssh/${SSHKEY}.pem
> sources.list
echo "#!/bin/bash" >sources.list
echo "Done"
# s3
aws s3 rm s3://aca-bootcamp-narek --recursive
aws s3api delete-bucket --bucket aca-bootcamp-narek
rm -f $(pwd)/index.html
aws s3 rm $(pwd)/index.html s3://aca-bootcamp-narek/index.html

exit

