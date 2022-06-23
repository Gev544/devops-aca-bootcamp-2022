#
Bucket_name=bucket.aca

#checking if there is old key
if [ -f MyKeyPair.pem ]
then
	rm -f MyKeyPair.pem
fi

#creating instance
echo Launching an instance and a bucket...
./aws_conf.sh

if [ ! $? -eq 0 ]
then
	exit
fi

#creating index.html file 

echo \
'   <Html>    
    <Head>  
    <title>  
    	Rate 
    </title>  
    </Head>  
    <Body>
		<h4 style="text-align: center;"><strong>USD/AMD rate From Ameria bank</strong></h4>
		<p style="text-align: center;">1USD/100AMD</p>
    </Body>  
    </Html>  ' > index.html
#copying it to bucket
aws s3 cp index.html s3://$Bucket_name

#making it public readable
aws s3api put-object-acl --bucket $Bucket_name --key index.html --acl public-read

#getting it's IP address to connect 
IP_Address=$(tail -1 ids)

#Copying files to instance and runnig them
scp -oStrictHostKeyChecking=accept-new -i MyKeyPair.pem  web/* web/.passwd-s3fs ubuntu@$IP_Address:. && \
ssh -i MyKeyPair.pem  ubuntu@$IP_Address  "sudo ./run.sh $Bucket_name"

#Deleting extra files
rm -f web/.passwd-s3fs
rm -f index.html 