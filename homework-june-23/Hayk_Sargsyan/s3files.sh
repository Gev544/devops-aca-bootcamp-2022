#!/bin/bash

set -e 

iam_user=Xuser
bucket_name=aca$(date +%s) 

#create s3 bucket

create-s3 () {
        bucketID=$(aws s3api create-bucket \
                --bucket $bucket_name)
                echo "bucket_name_is $bucket_name" >> fun-IDs.txt
                }

create-index-others () {
                echo "Barev World JAN !" > index.html
                echo -e "[Unit]\nDescription=Refresh html\n\n[Service]\nExecStart=/home/ubuntu/refresh-index.sh\n\n[Install]\nWantedBy=multi-user.target " > z-refresh.service
                aws s3 mv index.html s3://$bucket_name
                aws s3 mv z-refresh.service s3://$bucket_name
                aws s3 cp refresh-index.sh s3://$bucket_name
                fileUrl=https://s3.amazonaws.com/$bucket_name/index.html
                serviceUrl=https://s3.amazonaws.com/$bucket_name/z-refresh.service
                refreshIndex=https://s3.amazonaws.com/$bucket_name/refresh-index.sh
                echo "index.html, z-refresh and refresh-index are created and uploaded in s3 bucket"
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
                echo "Files are Public"
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
                echo "Files are Public"
}

#creating aws  IAM user

create_iam_user () {
        userID=$(aws iam create-user \
                --user-name  $iam_user \
                --permissions-boundary arn:aws:iam::aws:policy/AmazonS3FullAccess \
                --query 'User.UserId' \
                --output text)
                echo $userID > Xuser.credentials.txt
                echo "$iam_user IAM user is created"
        }

#attaching s3 full access to created user

attach_policy () {
        aws iam attach-user-policy \
                --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
                --user-name $iam_user
        echo "user policy AmazonS3FullAccess is attached"
        }

#creating  keys for IAM user and file with credentials for ec2 instance to merge s3 bucket

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
        echo "access keys are created and created .passwrd-s3fs file with credential"
        }

#checking bucket and files 

check_bucket () {
        number_of_files=$(aws s3 ls s3://$bucket_name | wc -l)
        if [[ $number_of_files -ne 3 ]]
        then
                echo "something is wrong with bucket"
		aws s3 rb s3://$bucket_name --force 2> /dev/null
		terminate_ec2 && delete_sg && delete-keys && disassociate_rt && delete_rt \
                && detach_igw && delete_igw && delete_subnet2  && delete_subnet1 && delete_vpc
                 exit 1
        fi
        }

#checking user and attached policies

check_user_policies () {
        policy=$(aws iam list-attached-user-policies --user-name $iam_user | grep AmazonS3FullAccess | wc -l)
        if [[ $policy -ne 2 ]]
        then
                echo "user not created or policy not attached"
                detach_policy > /dev/null
                delete_user > /dev/null
                aws s3 rb s3://$bucket_name --force
		terminate_ec2 && delete_sg && delete-keys && disassociate_rt && delete_rt \
                && detach_igw && delete_igw && delete_subnet2  && delete_subnet1 && delete_vpc
		exit 1
        fi
        }

check_credentials () {
        if [[ -f .passwd-s3fs ]] && [[ -n .passwd-s3fs ]]
        then
                echo ".passwd-s3fs file exists and not empty"
        else    echo "something goes wrong with creating .passwd-s3fs file"
                delete_access_key
                detach_policy
                delete_user
                aws s3 rb s3://$bucket_name --force
                terminate_ec2 && delete_sg && delete-keys && disassociate_rt && delete_rt \
		&& detach_igw && delete_igw && delete_subnet2  && delete_subnet1 && delete_vpc
		exit 1
        fi
}

#secure copy iam user credentials file to ec2 instance

copy_cred () {
        scp -i ./*.pem .passwd-s3fs ubuntu@$(cat fun-IDs.txt | grep ip | cut -d " " -f 2):~/ && \
        scp -i ./*.pem .passwd-s3fs ubuntu@$(cat fun-IDs.txt | grep -A 1 ip | tail -1):~/ && \
        scp -i ./*.pem forInstance.sh ubuntu@$(cat fun-IDs.txt | grep ip | cut -d " " -f 2):~/ &&  \
        scp -i ./*.pem forInstance.sh ubuntu@$(cat fun-IDs.txt | grep -A 1 ip | tail -1):~/ && \
        ssh -i ./*.pem ubuntu@$(cat fun-IDs.txt | grep ip | cut -d " " -f 2) "bash ~/forInstance.sh" && \
        ssh -i ./*.pem ubuntu@$(cat fun-IDs.txt | grep -A 1 ip | tail -1) "bash ~/forInstance.sh " && \
        rm -f .passwd-s3fs && rm -f forInstance.sh
        echo ".passwd-s3fs file copied to ec2 instances and removed from local "
        }

#delete access key for iam user

delete_access_key () {
        aws iam delete-access-key \
                --access-key-id  $(cat Xuser.credentials.txt | head -2 | tail -1) \
                --user-name $iam_user
	echo "access keys are deleted"
                }

#detaching policy from iam user

detach_policy () {
       	aws iam detach-user-policy \
		--user-name $iam_user \
		--policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
	echo "AmazonS3FullAccess policy is detached"
		}

#deleting iam user

delete_user () {
        aws iam delete-user --user-name $iam_user && rm -f Xuser.credentials.txt
	echo "IAM user is deleted"
	}

#deleting s3 bucket and objects

delete_s3_objects () {
	aws s3 rb s3://$(cat fun-IDs.txt | grep bucket | cut -d " " -f 2) --force
	echo "s3 bucket and objects are deleted"
		}

#create script file to send 

cretefile () {
echo -e "#!/bin/bash



mkdir ~/s3Volume
sudo s3fs $bucket_name /home/ubuntu/s3Volume/ \
	-o allow_other \
	-o use_path_request_style \
	-o passwd_file=/home/ubuntu/.passwd-s3fs \
	-o nonempty -o rw\
	-o mp_umask=002 -o uid=1000 -o gid=1000
sudo chmod 755 /home/ubuntu
sudo chmod 644 /home/ubuntu/s3Volume/index.html
sudo ln -s /home/ubuntu/s3Volume/index.html /var/www/html/index.html
sudo cp ~/s3Volume/z-refresh.service /lib/systemd/system/
sudo cp ~/s3Volume/refresh-index.sh ~/
sudo chmod +x refresh-index.sh
sudo systemctl daemon-reload
sudo systemctl restart nginx
sudo systemctl enable nginx
sudo service z-refresh restart
sudo systemctl enable z-refresh
    " > forInstance.sh
}

# Run the Script

        if [[ $1 = "create" ]]
        then
                create-s3 && create-index-others && make-public && check_bucket && create_iam_user &&\
                attach_policy && check_user_policies && create_iam_keys && check_credentials && cretefile && copy_cred
        elif [[ $1 = "delete" ]]
        then
                delete_access_key && detach_policy  && delete_user && delete_s3_objects
		else echo -e "Invalid Argument \n create / delete "
        fi                