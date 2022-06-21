#!/bin/bash


projectName="aca-homework"
instanceUsername="ubuntu"
websiteScript="website.sh"



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
	echo -e "server {
	listen 80 default_server;
	listen [::]:80 default_server;
	root /var/www/${projectName};" > /etc/nginx/sites-available/${projectName}.conf && \
	echo -e '	index index.html;
	server_name _;
	location / {
		try_files $uri $uri/ =404;
	}
}' >> /etc/nginx/sites-available/${projectName}.conf && \
	rm -r /etc/nginx/sites-enabled/default && \
	ln -s /etc/nginx/sites-available/${projectName}.conf /etc/nginx/sites-enabled/${projectName}.conf && \
	rm -rf /var/www/html && \
	mkdir -p /var/www/${projectName} && \
	mv /home/${instanceUsername}/index.html /var/www/${projectName}/index.html && \
	systemctl reload nginx.service
}


# Makes website script to work as a daemon
function setupWebsite () {
	mkdir -p /opt/${projectName} && \
	mv /home/${instanceUsername}/${websiteScript} /opt/${projectName}/${websiteScript} && \
	echo -e "[Unit]
Description=ACA Homework June 15 Website
After=network.target

[Service]
ExecStart=/opt/${projectName}/${websiteScript}
Restart=on-failure

[Install]
WantedBy=multi-user.target" > /lib/systemd/system/${projectName}.service && \
	systemctl start ${projectName}.service
}



# Checks if script running with superuser privileges
if [[ $USER != root ]]
then    
    echo "Permission denied: run script as root"
else
	installNginx && checkNginx && configureNginx && setupWebsite
fi 