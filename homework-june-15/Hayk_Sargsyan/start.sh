#!/bin/bash

set -e

bucket_name=aca$(date +%s)
iam_user=Xuser

#creating s3 public bucket

create-s3 () {
	bucketID=$(aws s3api create-bucket \
		--bucket $bucket_name) 
		#--acl public-read \
		#--output text)
		echo "$bucketID"
		}

#creating index.html and other files and move them to the created s3 bucket

create-index-others () {
		echo "Barev World JAN !" > index.html
		echo -e "[Unit]\nDescription=Refresh html\n\n[Service]\nExecStart=/home/ubuntu/refresh-index.sh\n\n[Install]\nWantedBy=multi-user.target " > z-refresh.service
		aws s3 mv index.html s3://$bucket_name
		aws s3 mv z-refresh.service s3://$bucket_name
		aws s3 cp refresh-index.sh s3://$bucket_name
		fileUrl=https://s3.amazonaws.com/$bucket_name/index.html
		serviceUrl=https://s3.amazonaws.com/$bucket_name/z-refresh.service
		refreshIndex=https://s3.amazonaws.com/$bucket_name/refresh-index.sh
		}

#make file public

make-public () {
		aws s3api put-object-acl \
		--bucket $bucket_name \
		--key index.html \
		--acl public-read
		aws s3api put-object-acl \
                --bucket $bucket_name \
                --key z-refresh.service \
                --acl public-read
		aws s3api put-object-acl \
                --bucket $bucket_name \
                --key refresh-index.sh \
                --acl public-read
}

#creating a userdata.txt file for ec2 instance

create-userdata () {
		echo -e '#!/bin/bash\nsudo apt update -y\nsudo apt install nginx -y' > userdata.txt
		#echo -e "wget -P /var/www/html/ $fileUrl" >> userdata.txt
		echo "wget -P /lib/systemd/system/ $serviceUrl" >> userdata.txt
		echo "wget -P /home/ubuntu/ $refreshIndex" >> userdata.txt
		echo "sudo chmod +x /home/ubuntu/refresh-index.sh" >> userdata.txt
		echo "sudo apt install s3fs -y" >> userdata.txt
		echo "sudo apt install openjdk-11-jre -y" >> userdata.txt
		echo "sudo systemctl daemon-reload" >> userdata.txt
		echo "sudo service nginx restart" >> userdata.txt
		echo "sudo service nginx enable" >> userdata.txt
		echo "sudo service z-refresh restart" >> userdata.txt
		echo "sudo service z-refresh enable" >> userdata.txt
		}

create_iam_user () {
        userID=$(aws iam create-user \
                --user-name  $iam_user \
                --permissions-boundary arn:aws:iam::aws:policy/AmazonS3FullAccess \
                --query 'User.UserId' \
                --output text)
                echo $userID > Xuser.credentials.txt
        }

attach_policy () {
	aws iam attach-user-policy \
		--policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
		--user-name $iam_user
	}

create_iam_keys () {
        credentials=$(aws iam create-access-key \
                --user-name $iam_user \
                --query 'AccessKey.[AccessKeyId,SecretAccessKey]' \
                --output text)
        accessKeyID=$(echo ${credentials} | cut -d " " -f 1)
        secretAccessKey=$(echo ${credentials} |tr -s " " | cut -d " " -f 2)
        echo -e "$accessKeyID\n$secretAccessKey" >> Xuser.credentials.txt
        echo -e "$accessKeyID:$secretAccessKey" > .passwd-s3fs
        sudo chmod 600 .passwd-s3fs
        }

#secure copy iam user credentials file to ec2 instance

copy_cred () {
	scp -i ./*.pem .passwd-s3fs ubuntu@$(cat fun-IDs.txt | grep ip | cut -d " " -f 2):~/ && \
	rm -f .passwd-s3fs
	}

#create folder and mount s3 to ec2

mount () {
	ssh -i ./*.pem ubuntu@$(cat fun-IDs.txt | grep ip | cut -d " " -f 2) \
	"mkdir ~/s3Volume"
	ssh -i ./*.pem ubuntu@$(cat fun-IDs.txt | grep ip | cut -d " " -f 2) \
	"sudo s3fs $bucket_name /home/ubuntu/s3Volume/ \
	-o allow_other \
	-o use_path_request_style \
	-o passwd_file=/home/ubuntu/.passwd-s3fs \
	-o nonempty -o rw\
	-o mp_umask=002 -o uid=1000 -o gid=1000"
	ssh -i ./*.pem ubuntu@$(cat fun-IDs.txt | grep ip | cut -d " " -f 2) \
	"sudo chmod 755 /home/ubuntu"
	ssh -i ./*.pem ubuntu@$(cat fun-IDs.txt | grep ip | cut -d " " -f 2) \
	"sudo chmod 644 /home/ubuntu/s3Volume/index.html"
	}

#creating link from /var/www/html/ to ~/s3Volume/

run_commands_ec2 () {
	ssh -i ./*.pem ubuntu@$(cat fun-IDs.txt | grep ip | cut -d " " -f 2) \
	"sudo ln -s /home/ubuntu/s3Volume/index.html /var/www/html/index.html"
	}

#delete access key for iam user

delete_access_key () {
        aws iam delete-access-key \
                --access-key-id  $(cat Xuser.credentials.txt | head -2 | tail -1) \
                --user-name $iam_user
                }

#detaching policy from iam user

detach_policy () {
       	aws iam detach-user-policy \
		--user-name $iam_user \
		--policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
		}

#deleting iam user

delete_user () {
        aws iam delete-user --user-name $iam_user && rm -f Xuser.credentials.txt
}

#deleting s3 bucket and objects

delete_s3_objects () {
	aws s3 rb s3://$(cat fun-IDs.txt | grep bucket | cut -d " " -f 2) --force
		}



if [[ $1 == "create" ]]
then
	create-s3 && create-index-others && make-public && create-userdata && create_iam_user && attach_policy \
	&& create_iam_keys && ./create-aws-ec2.sh create && echo "bucket_name_is $bucket_name" >> fun-IDs.txt  && copy_cred && mount && run_commands_ec2 && echo "DONE !"
elif [[ $1 == "delete" ]]
then
	delete_access_key && detach_policy  && delete_user && delete_s3_objects && ./create-aws-ec2.sh delete
else echo -e "  Invalid Argument \n   create or delete"
fi


