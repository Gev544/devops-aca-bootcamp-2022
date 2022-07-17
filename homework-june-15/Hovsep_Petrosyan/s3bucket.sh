#!/bin/bash

# backet vars

bucket_name=my-bucket-hoso
count_bucket_name=$(echo $bucket_name | wc -m)
count_bucket_name_1=$(( $count_bucket_name - 1 ))
zone=us-east-1
region=us-east-1

bucket () {
        exist_buckets1=$(aws s3api list-buckets \
                --query "Buckets[].Name")

        null_bucket1=$(echo $exist_buckets1 | grep $bucket_name)
	if [[ ! -n $null_bucket1 ]] 
	then 
		echo $bucket_name > $bucket_name.txt
	fi


        created_bucket_name=$(aws s3api create-bucket \
                --bucket $bucket_name \
                --region $region )
        

        while [[ -n $null_bucket1 ]]
        do
                num=$(echo $bucket_name | cut -c ${count_bucket_name}-)

                name1=$(echo $bucket_name | cut -c 1-${count_bucket_name_1})

                num1=$(( $num + 1 ))

                bucket_name="${name1}${num1}"

                exist_buckets=$(aws s3api list-buckets \
                        --query "Buckets[].Name")

                null_bucket=$(echo $exist_buckets | grep $bucket_name)
                if [[ ! -n $null_bucket ]]
			    then
                        created_bucket_name=$(aws s3api create-bucket \
                                --bucket $bucket_name \
                                --region $region )
			echo $bucket_name > $bucket_name.txt

                        break
                fi
		echo $bucket_name > $bucket_name.txt


        done
}

html_for_bucket () {
        ### crate html file by name index.html and copy to s3 bucket


        aeb_usd_bay=$(curl -s https://rate.am | grep -A 6 'HAYEKONOMBANK' | tail -2 | head -1 | grep -o '[0-9]*')
        aeb_usd_sale=$(curl -s https://rate.am | grep -A 6 'HAYEKONOMBANK' | tail -2 | tail -1 | grep -o '[0-9]*')

        echo "<p style="text-align:center">usd AEB bay = $aeb_usd_bay</p>" > index.html
        echo "<p style="text-align:center">usd AEB sell = $aeb_usd_sale</p>" >> index.html
        aws s3 cp index.html s3://$bucket_name/

}


html () {
	'#!/bin/bash
	mkdir /home/ubuntu/nginix_html
	while true
do

	aeb_usd_bay=$(curl -s https://rate.am | grep -A 6 'HAYEKONOMBANK' | tail -2 | head -1 | grep -o '[0-9]*')
        aeb_usd_sale=$(curl -s https://rate.am | grep -A 6 'HAYEKONOMBANK' | tail -2 | tail -1 | grep -o '[0-9]*')
	date=$(date +"%d-%m-%Y")

        echo "<p style="text-align:center">usd AEB bay = $aeb_usd_bay</p>" > /home/ubuntu/nginix_html/index.html      #/var/www/html/index.html
        echo "<p style="text-align:center">usd AEB sell = $aeb_usd_sale</p>" >> /home/ubuntu/nginix_html/index.html   #/var/www/html/index.html
	echo "<p style="text-align:center">$date</p>" >>  /home/ubuntu/nginix_html/index.html     #/var/www/html/index.html

	sleep 60
done' > for_index.html.sh
# chnge mode for_index.html.sh
chmod 777 ./for_index.html.sh
}



bucket
#html_for_bucket
html
