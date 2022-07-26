# #!/bin/bash
source aws.sh

function nginx {
        ssh -i EC2Key.pem ubuntu@$instancePublicIp "sudo chown ubuntu:ubuntu /var/www/html"
	    scp -i EC2Key.pem index.html ubuntu@$instancePublicIp:/var/www/html/index.html
        scp -i EC2Key.pem index.html ubuntu@$instancePublicIp:index.html
        ssh -i EC2Key.pem ubuntu@$instancePublicIp "sudo chown ubuntu:ubuntu /etc/nginx/sites-enabled/"
    	scp -i EC2Key.pem nginx.conf ubuntu@$instancePublicIp:/etc/nginx/sites-enabled/nginx.conf             
}
	
nginx
