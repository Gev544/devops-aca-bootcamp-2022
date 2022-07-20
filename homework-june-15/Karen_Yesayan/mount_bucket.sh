#!/bin/bash
# create user

bucket_mount() {
	bucket_info=$(aws iam create-user\
       	--user-name s3bucket_use1)

	#create acsseskaey without permisione
	credenshals_bucket=$(aws iam create-access-key\
	       	--user-name s3bucket_use1)

	# attach policy to use s3bucket full access
	aws iam attach-user-policy\
	       	--policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess\
	       	--user-name s3bucket_use

	# access kay id
	ACCESS_KEY_ID=$(echo $credenshals_bucket | cut -d " " -f 2)

	# secret key
	SECRET_ACCESS_KEY=$(echo $credenshals_bucket | cut -d " " -f 4)

	# credenshals file
	echo $ACCESS_KEY_ID:$SECRET_ACCESS_KEY > .passwd-s3fs
	chmod 600 .passwd-s3fs
}
bucket_mount
