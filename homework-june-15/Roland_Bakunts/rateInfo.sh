# #!/bin/bash
source aws.sh

function nginx {

        # var=$(curl --silent rate.am | grep -A 3 ameria | tail -2 | sed 's/<\/*[^>]*>//g')
        # now=$(date)

        # echo "<h1>show usd/amd price from rate.am for Ameria Bank </h1> <h2>$var</h2> <span>"$now" </span>" >> index.html
        # echo "<meta http-equiv="refresh" content="10">" >> index.html

        ssh -i EC2Key.pem ubuntu@$instancePublicIp "sudo chown ubuntu:ubuntu /var/www/html"
	    scp -i EC2Key.pem index.html ubuntu@$instancePublicIp:/var/www/html/index.html
        scp -i EC2Key.pem index.html ubuntu@$instancePublicIp:index.html
        ssh -i EC2Key.pem ubuntu@$instancePublicIp "sudo chown ubuntu:ubuntu /etc/nginx/sites-enabled/"
    	scp -i EC2Key.pem nginx.conf ubuntu@$instancePublicIp:/etc/nginx/sites-enabled/nginx.conf 
              
}
	
nginx
