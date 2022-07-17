#!/bin/bash

# colored bash:)
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
Blue='\033[0;34m'
Reset='\033[0m'

name=$1
ec2User=$2
rateamScript=$3
bucketName=$4
accessKeyIdAndSecret=$5
webServerPath="/var/www/${name}"

# install and config nginx
install_nginx () {
	if [[ $(nginx -v) != 0 ]]; then
		apt update -y >/dev/null && \
		apt install nginx -y >/dev/null && \
		systemctl enable nginx.service && \
		systemctl restart nginx.service && \
		systemctl status nginx.service
		if [[ $? != 0 ]]; then
			nginxStatus=$(systemctl show nginx.service --property=ActiveState | cut -d "=" -f 2)
			echo -e "${Red}Something went wrong nginx status: ${nginxStatus}${Reset}"
			exit 1
		fi
		echo -e "${Green}nginx is active and running.${Reset}"
	else
		systemctl enable nginx.service && \
		systemctl restart nginx.service && \
		systemctl status nginx.service
		if [[ $? != 0 ]]; then
			nginxStatus=$(systemctl show nginx.service --property=ActiveState | cut -d "=" -f 2)
			echo -e "${Red}Something went wrong\nNginx status: ${nginxStatus}${Reset}"
			exit 1
		fi
		echo -e "nginx is active and running"
	fi
}

set_html_page () {
	sudo mv /home/ubuntu/index.html $webServerPath
	sudo echo "server {
		listen 80 default_server;
		listen [::]:80 default_server;
		root $webServerPath;
		index index.html;

		server_name _;

location / {
		try_files $uri $uri/ =404;
}
}" > /etc/nginx/sites-available
	sudo rm /etc/nginx/sites-enabled/default
	sudo cp /etc/nginx/sites-available/index.html /etc/nginx/sites-enabled/
}

# install s3fs and configure access key
install_mount () {
	apt update -y >/dev/null && \
	echo -e "${Green}apt list updated successfully !${Reset}" && \
	apt install s3fs -y >/dev/null && \
	echo -e "${Green}s3fs installed successfully !${Reset}" && \
	echo $accessKeyIdAndSecret > /etc/passwd-s3fs && \
	chmod 600 /etc/passwd-s3fs && \
	mkdir -p $webServerPath && \
	sudo s3fs $bucketName $webServerPath \
		-o allow_other \
		-o passwd_file=/etc/passwd-s3fs \
		-o umask=000 && \
	echo -e "${Green}s3fs configured successfully !${Reset}"
}

# make website script to work as daemon
setup_website () {
	mkdir -p /opt/$name && \
	mv /home/$ec2User/$rateamScript /opt/$name/$rateamScript && \
	echo -e "[Unit]
Description=ACA Homework June 15
After=network.target

[Service]
ExecStart=/opt/'${name}'/'${rateamScript}'
Restart=on-failure

[Install]
WantedBy=multi-user.target" > /lib/systemd/system/$name.service && \
	systemctl start $name.service && \
	systemctl restart nginx.service
	echo -e "${Green}$name.service works as a daemon successfully !${Reset}"
}

install_nginx && set_html_page && install_mount && setup_website && bash /opt/$name/$rateamScript $name &