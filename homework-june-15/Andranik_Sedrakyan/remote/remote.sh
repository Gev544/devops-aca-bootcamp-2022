#!/bin/bash
resource_name=$1
access_key=$(head -1 ${resource_name}'-user.txt')
secret_access_key=$(tail -1 ${resource_name}'-user.txt')

my_dir="/var/www/${resource_name}/"

function uninstallNginx() {
  sudo apt-get remove nginx nginx-common && \
  sudo apt-get purge nginx nginx-common && \
  sudo apt-get autoremove

}

function installNginx() {
  set -e
  if [ ! -x /usr/sbin/nginx ]; then
    echo "Installing nginx"
    sudo apt update -y
    sudo apt install nginx -y

    if [[ $? != 0 ]]; then
      echo "Something went wrong , uninstalling nginx"
      uninstallNginx
    else
      echo "nginx is installed"
    fi

  else
    echo "nginx is already installed"
  fi
}

#check if nginx is active
function checkNginx() {
  nginx_state=$(systemctl show nginx.service | grep ActiveState | cut -d "=" -f2)

  if [[ $nginx_state == "active" ]]; then
    echo "Nginx is active"
  else
    echo "Starting nginx"
    systemctl start nginx.service
  fi
}

#config for website
function configureNginx() {
  set -e
  echo "Nginx configuration"
  sudo touch /etc/nginx/sites-available/project.conf
  sudo chmod 446 /etc/nginx/sites-available/project.conf
  sudo echo -e "
  server {
         listen 80;
         listen [::]:80;

         server_name _;

         root $my_dir;
         index index.html;

         location / {
                 try_files \$uri \$uri/ =404;
         }
  }
" >> /etc/nginx/sites-available/project.conf

  sudo ln -s /etc/nginx/sites-available/project.conf /etc/nginx/sites-enabled/project.conf
  sudo rm -rf /etc/nginx/sites-available/default
  sudo rm -rf /etc/nginx/sites-enabled/default
  sudo rm -rf /var/www/html

  sudo mkdir $my_dir

  echo "Nginx is configred"
}

#install and mount s3 bucket
function installS3fs() {
  set -e
  sudo apt-get install s3fs
  sudo echo $access_key:$secret_access_key > /etc/passwd-s3fs && \
  chmod 600 /etc/passwd-s3fs && \
  sudo s3fs $resource_name'-aca-bootcamp-bucket' $my_dir -o passwd_file=/etc/passwd-s3fs -o allow_other && \
  service nginx reload
}

function createSystemd() {
  set -e
  mkdir -p /opt/${resource_name}/ && \
  mv /home/ubuntu/website.sh /opt/${resource_name}/website.sh
  echo "
  [Unit]
  Description=usd/amd price from rate.am for Ameria Bank
  After=network.target

  [Service]
  Type=simple
  ExecStart=/opt/${resource_name}/website.sh ${resource_name}

  [Install]
  WantedBy=multi-user.target
  " > /etc/systemd/system/${resource_name}.service
  systemctl start ${resource_name}.service && \
	systemctl restart nginx.service
}


#call functions to run code
installNginx
checkNginx
configureNginx
installS3fs
createSystemd
