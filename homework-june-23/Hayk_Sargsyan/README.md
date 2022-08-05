### notice
```
You should upload your ssl certificate to AWS Certificate Manager
Install aws cli on your ubuntu and login with your aws user credentials !
You should have aws user with turned off -Block Public Access settings for this account- !
```

### usage
```
./start.sh [argument]
```
### arguments:
```
create -  Creating bucket, uploading files, creating AWS IAM user, creating vpc, subnets with internet access,
          creating other necessary resources, creating 2 ec2 instances and downloading some files from s3 bucket, 
          mount s3 bucket to 2 ec2 instance, creating a z-refresh service with systemd, wich will refresh index.html
          every 1 minut (AmeriaBank USD buy and sell rate) . Nginx will read index.html file from mounted s3 bucket! 
          Creates Load Balancer and DNS A record !
delete -  Deleting s3 bucket ,ec2 instance and everything that was created by -create- option !
```
