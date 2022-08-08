#!/bin/bash
while : ; do
	#getting rate

	rate=$(curl --silent rate.am | grep -A 3 ameria | tail -2 | head -1 | tr -dc '0-9')

	#creating new index.file

echo \
	"<Html>    
    <Head>  
    <title>  
    	Rate 
    </title>  
    </Head>  
    <Body>
		<h4 style='text-align: center;'><strong>USD/AMD rate From Ameria bank</strong></h4>
		<p style='text-align: center;'>1 USD/$rate AMD</p>
    </Body>  
    </Html>  " > index.html
	
	#Replacing it with old one

	sudo mv index.html /var/www/bootcamp_aca/
	sleep 60 
done
