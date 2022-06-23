#!/bin/bash
Bucket_name=$1


#downloading index file
wget https://s3.amazonaws.com/bucket.aca/index.html

#installing nginx 
#---Checking if Nginx is installed and works 

nginx_exists=$(nginx -v 2> /dev/null)
nginx_exists=$?

if [ ! $nginx_exists = 0 ]
then
	apt-get update 1>/dev/null 2>/dev/null
	#if nginx isn't installed
	apt-get install -y nginx 1>/dev/null 2>/dev/null
fi
sleep 1

#checking if nginx works
response=$(curl -i 127.0.0.1 2>/dev/null | head -n 1 | cut -d ' ' -f2)

if [[ $response -eq 200 ]]
then
	echo "Everything works correctly"
else
	echo "Your nginx has a problem"
	exit
fi

#configuring nginx
sudo rm -rf /etc/nginx/sites-enabled/default
sudo mv nginx.conf /etc/nginx/sites-enabled/ 

#Creating root folder for index.html

root_folder=$(cat /etc/nginx/sites-enabled/nginx.conf | grep root | awk '{print $2}' | tr -d ";")

if [ ! -d $root_folder ]
then
        sudo mkdir -p $root_folder
fi

#Installing s3fs to mount bucket
apt-get -y install s3fs 1>/dev/null && \
chmod 600 .passwd-s3fs && \
mv .passwd-s3fs /root && \
s3fs $Bucket_name $root_folder -o use_path_request_style -o allow_other && \
echo "Bucket is mounted in $root_folder"

service nginx reload

#making systemd service

mv update_page.sh /usr/bin/

#creating conf file for service
echo \
"[Unit]
Description=Rate Web Page Updater
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /usr/bin/update_page.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target" > update_page.service

#checking if service already exists

if [ ! -f /etc/systemd/system/update_page.service ]
then
	sudo mv update_page.service /etc/systemd/system/

	sudo systemctl daemon-reload
	sudo systemctl start update_page && \
	echo "Update page service started."
fi




