#!/bin/bash

sudo apt-get update
if [ ! -x /usr/sbin/nginx ]
then
    sudo apt-get install -y nginx
fi

# Installing dependencies
sudo apt-get install automake autotools-dev fuse g++ git libcurl4-gnutls-dev libfuse-dev libssl-dev libxml2-dev make pkg-config -y
git clone https://github.com/s3fs-fuse/s3fs-fuse.git
cd s3fs-fuse
./autogen.sh
./configure --prefix=/usr --with-openssl
make
sudo make install

# fuse.conf (allow other users)
wait -n
sudo sed -i '$ d' /etc/fuse.conf
echo 'user_allow_other' | sudo tee --append /etc/fuse.conf

# IAM user config
cd
chmod 640 passwd-s3fs
sudo mv passwd-s3fs /etc/passwd-s3fs

# Mount & auto remount when reboot
mkdir myS3Bucket
sudo mv myS3Bucket/ /myS3Bucket/
s3fs $1 -o use_cache=/tmp -o allow_other -o uid=1001 -o mp_umask=002 -o multireq_max=5 /myS3Bucket
sudo mv Project_X/ /myS3Bucket/Project_X

# Create systemd service to autoremount
echo -e "s3fs#$1 /myS3Bucket fuse _netdev,allow_other,passwd_file=/etc/passwd-s3fs 0 0" | sudo tee --append /etc/fstab

# Nginx config 
echo "server {
        listen 80;
        listen [::]:80;

        root /myS3Bucket/Project_X;
        
        index index.html;

        server_name localhost;

}
" > port-index.conf

sudo mv port-index.conf /etc/nginx/sites-enabled/port-index.conf
sudo rm /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

# rate-parser service creation
touch rate-parser.service

echo -e "[Unit]
Description=My rate-parser from rate.am
After=network.target

[Service]
ExecStart=/home/ubuntu/rate-parser.sh
Restart=always
User=ubuntu
Group=ubuntu
StartLimitBurst=0

[Install]
WantedBy=multi-user.target" > rate-parser.service

sudo mv rate-parser.service /etc/systemd/system/rate-parser.service
sudo systemctl daemon-reload
sudo systemctl start rate-parser.service
sudo systemctl enable rate-parser.service


