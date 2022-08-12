#!/bin/bash

terraform apply -auto-approve
instance_id=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --output text)
aws ec2 wait instance-status-ok --instance-ids $instance_id &&
instance_ip=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].PublicIpAddress' --output text) &&
echo -e "[aws]\n$instance_ip" | xargs -n1 > hosts.txt &&
ansible-playbook playbook.yml
terraform output | grep [1..255.0..255.0..255.0..255]