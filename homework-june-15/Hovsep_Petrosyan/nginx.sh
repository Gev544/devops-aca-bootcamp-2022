#!/bin/bash
function check_if_installed() {
  check=$(which nginx)
  active=$(systemctl is-active nginx.service)

  if [[ $check != "/usr/sbin/nginx" ]]; then
    echo "You have not installed nginx"
    sudo apt -y update
    sudo apt-get -y install nginx

    if [[ $active == "active" ]]; then
      echo "Nginx is active"
    fi
  else
    echo "You have nginx installed already!"
    if [[ $active == "active" ]]; then
      echo "Nginx is active"
    fi
  fi

}

check_if_installed
