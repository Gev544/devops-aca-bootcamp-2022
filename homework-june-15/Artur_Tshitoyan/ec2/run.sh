#!/bin/bash

# Restricting permissions to key file
sudo chmod 600 .passwd-s3fs

# Making directory where should be  mount s3 bucket
sudo mkdir s3-drive

# Mounting s3 bucket to ec2 instance
sudo s3fs myvpc-s3 s3-drive/ -o allow_other -o use_path_request_style -o passwd_file=/home/ubuntu/.passwd-s3fs -o nonempty -o rw -o mp_umask=002 -o uid=1000 -o gid=1000

sleep 10

# Adding read permission to nginx files
sudo chmod 666 s3-drive/index.html
sudo chmod 644 s3-drive/nginx.conf

# Removing nginx default config files
sudo rm /etc/nginx/sites-available/default
sudo rm /etc/nginx/sites-enabled/default

# Copying nginx.conf to nginx 
sudo cp /home/ubuntu/s3-drive/nginx.conf /etc/nginx/sites-available/

# making soft link to nginx config file from "sites-available" directory to "sites-enabled" directory
sudo ln -s /etc/nginx/sites-available/nginx.conf /etc/nginx/sites-enabled/default

# Restart nginx
sudo systemctl restart nginx

start_service ()
  {
sudo systemctl daemon-reload && \
sudo systemctl enable refresh_index.service &&  \
sudo systemctl start refresh_index.service
  }

# Make script to work as a systemd service
echo -e "[Unit]\nDescription=Refresh index file\n\n[Service]\nExecStart=/home/ubuntu/refresh_index.sh\nRestart=always\n\n[Install]\nWantedBy=multi-user.target" > /home/ubuntu/refresh_index.service

if [[ ! -f /lib/systemd/system/refresh_index.service ]]
then
sudo mv /home/ubuntu/refresh_index.service /lib/systemd/system/ && \
start_service
elif [[ $(cat /home/ubuntu/refresh_index.service) = $(cat /lib/systemd/system/refresh_index.service) ]]
then
start_service
else
sudo rm -f /lib/systemd/system/refresh_index.service && \
sudo mv /home/ubuntu/refresh_index.service /lib/systemd/system/ && \
start_service
fi
