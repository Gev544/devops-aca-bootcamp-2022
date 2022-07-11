#!/bin/bash

# This is the remote script which will be executed by main script

projectName=$1
instanceUsername=$2
websiteScript=$3
bucketName=$4
accessKeyIdAndSecret=$5
domainName=$6
webServerPath="/var/www/${projectName}"


# Checks if Nginx is installed or not, if not installs
function installNginx () {
	if [ ! -x /usr/sbin/nginx ]; then
    	echo "Nginx is not installed."
		echo "Installing Nginx..."
		apt update -y && apt install nginx -y && \
		echo "Done."
	elif [ -x /usr/sbin/nginx ]; then
		echo "Nginx is already installed."
		echo "Restarting Nginx..."
		systemctl enable nginx.service && systemctl restart nginx.service && \
		echo "Done."
	fi
}


# Checks if Nginx running or not
function checkNginx () {
	nginxStatus=$(systemctl show nginx.service --property=ActiveState | cut -d "=" -f 2)
	if [[ $nginxStatus = active ]]; then
		echo "Nginx is active and running."
	elif [[ $nginxStatus = inactive ]]; then
		echo "Nginx is not running."
		echo "Starting Nginx..."
		systemctl start nginx.service
	else
		echo "Something went wrong nginx status: ${nginxStatus}."
	fi
}


# Configures Nginx to use custom configuration
function configureNginx () {
	echo "Configuring Nginx..."
	echo -e 'server {
	listen 80 default_server;
	listen [::]:80 default_server;
	root '$webServerPath';
		index index.html;
	server_name _;
	location / {
		try_files $uri $uri/ =404;
	}
}' > /etc/nginx/sites-available/${projectName}.conf && \
	rm -rf /etc/nginx/sites-enabled/default && \
	ln -s /etc/nginx/sites-available/${projectName}.conf /etc/nginx/sites-enabled/${projectName}.conf && \
	rm -rf /var/www/html && \
	echo "Done."
}


# Installs certbot and configures nginx for https
function configureHttps () {
	echo "Installing Certbot..."
	apt install certbot python3-certbot-nginx -y && \
	certbot --nginx --register-unsafely-without-email --agree-tos --redirect -d $domainName && \
	echo "Done."
}


# Installs s3fs and configures access key
function installAndMountS3 () {
    echo "Installing and configuring s3fs..."
    apt update -y && apt install s3fs -y && \
    echo $accessKeyIdAndSecret > /etc/passwd-s3fs && \
    chmod 600 /etc/passwd-s3fs && \
    mkdir -p $webServerPath && \
    s3fs ${bucketName} ${webServerPath} -o allow_other -o passwd_file=/etc/passwd-s3fs -o umask=000 && \
    echo "Done."
}


# Makes website script to work as a daemon
function setupWebsite () {
	mkdir -p /opt/${projectName} && \
	mv /home/${instanceUsername}/${websiteScript} /opt/${projectName}/${websiteScript} && \
	echo -e '[Unit]
Description=ACA Homework June 15 Website
After=network.target

[Service]
ExecStart=/opt/'${projectName}'/'${websiteScript} ${webServerPath}'
Restart=on-failure

[Install]
WantedBy=multi-user.targe' > /lib/systemd/system/${projectName}.service && \
	systemctl start ${projectName}.service && \
	systemctl restart nginx.service
}


# Checks if script running with superuser privileges
if [[ $USER != root ]]
then    
    echo "Permission denied: run script as root"
else
	installNginx && checkNginx && configureNginx && configureHttps && installAndMountS3 && setupWebsite
fi 