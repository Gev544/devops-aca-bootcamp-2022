#!/bin/bash

# create function

function ensure_nginx(){
  if [ -x "$(command -v nginx)" ]; then
      echo "Nginx already installed"
  else
      echo "Installing nginx..."
      sudo apt update
      sudo apt install nginx -y
      echo "Nginx installed!"
  fi
}

ensure_nginx


function StatuscheckNginx() {
	Statuscheck=$(systemctl show nginx.service --property=ActiveState | cut -d "=" -f 2)
	if [[ $Statuscheck = active ]]; then
		echo "Nginx is active"
	else
		echo "Going to activate Nginx"
		systemctl start nginx.service
	fi
}

StatuscheckNginx

aws s3 ls

#Download file from s3 to ec2
aws s3 cp s3://$bucketname/index.html ./

