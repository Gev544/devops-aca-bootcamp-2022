#!/bin/bash

#run provider
terraform plan -var-file=provider.tf
terraform apply -auto-approve

#run ec2
terraform plan -var-file=main.tf
terraform apply -auto-approve


# ansible install nginx
ansible-playbook -i ./ansible/hosts.ini ./ansible/nginxPlaybook.yaml

# ansible locale file to instance
ansible-playbook -i ./ansible/hosts.ini ./ansible/htmlPlaybook.yaml

# ansible change nginx.conf of instance
ansible-playbook -i ./ansible/hosts.ini ./ansible/nginxConfPlaybook.yaml

#run output
terraform plan -var-file=output.tf
terraform apply -auto-approve
