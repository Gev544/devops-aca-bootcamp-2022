#!/bin/bash

# checks if nginx is installed or not, if not installs and enables
function nginxInstall () {
	if [ ! -x /usr/sbin/nginx ]; then
    	echo "Nginx is not installed"
		echo "Installing and enabling Nginx..."
		apt update -y && apt install nginx -y && systemctl enable --now nginx.service
	else
		echo "Nginx is already installed"
		echo "Restarting Nginx..."
		systemctl enable nginx.service && systemctl restart nginx.service
	fi
}

# checks nginx status
function nginxStatusCheck () {
	nginxStatus=$(systemctl show nginx.service --property=ActiveState | cut -d "=" -f 2)
	if [[ $nginxStatus = active ]]; then
		echo "Nginx is running"
	elif [[ $nginxStatus = inactive ]]; then
		echo "Nginx is not running"
		echo "Starting Nginx..."
		systemctl start nginx.service
	else
		echo "Something went wrong nginx status: $nginxStatus"
	fi
}

# checks if script running with superuser privileges
if [[ $USER != root ]] 
then    
        echo "Permission denied: run script as root"
else
	nginxInstall && nginxStatusCheck
fi 