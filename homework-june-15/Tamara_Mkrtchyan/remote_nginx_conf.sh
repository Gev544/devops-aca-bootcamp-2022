#!/bin/bash

install_nginx () {
	if [[ $(nginx -v) != 0 ]]; then
		apt update -y && \
		apt install nginx -y && \
		systemctl enable nginx.service && \
		systemctl restart nginx.service && \
		systemctl status nginx.service
		if [[ $? != 0 ]]; then
			exit 1
		fi
	else
		systemctl enable nginx.service && \
		systemctl restart nginx.service && \
		systemctl status nginx.service
		if [[ $? != 0 ]]; then
			exit 1
		fi
	fi
}

set_html_page () {
	mv /home/ubuntu/index.html /var/www/html/
}

install_nginx && set_html_page