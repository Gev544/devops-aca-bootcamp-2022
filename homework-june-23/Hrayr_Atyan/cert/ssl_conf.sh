#!/bin/bash

cert_link=https://s3.amazonaws.com/aca.files/letsencrypt.tar.gz

#downloading certificate from bucket
echo "Downloading Certificate from bucket"
wget $cert_link

#Unzipping tar.gz file
tar -xf letsencrypt.tar.gz

#Deleting zip
rm -f letsencrypt.tar.gz 

#Move it to its default directory
mv letsencrypt /etc/

#Updating nginx configurations
rm /etc/nginx/sites-enabled/default
mv nginx.conf /etc/nginx/sites-enabled/
mv aca-aws.mouradyan.xyz.conf /etc/nginx/conf.d/

service nginx reload 

#Configuring certificate update
apt-get update 1>/dev/null
apt-get -y install certbot 1>/dev/null
apt-get -y install python3-certbot-nginx 1>/dev/null

mv update_cert.sh /etc/cron.daily/
