### notice
```
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
          creating other necessary resources, creating ec2 instance and downloading some files from s3 bucket, 
          mount s3 bucket to ec2 instance, creating a z-refresh service with systemd, wich will refresh index.html
          every 1 minut (AmeriaBank USD buy and sell rate) . Nginx will read index.html file from mounted s3 bucket! 
delete -  Deleting s3 bucket ,ec2 instance and everything that was created by -create- option !
```
### for Jenkins
```
Run -forJenkins2.sh- with create/delete argument !
It will create ec2 instance with necessary resources , s3 bucket , IAM user , some needed files and upload them to s3
bucket. It sends IAM user  credentials to created instance . You should use previously created ec2 instance as a slave 
node for master jenkins (create master jenkins server were you like) . Create a job with slave label, which will install 
nginx and s3fs, creates a directory and mount previously created s3 bucket , creates and reload  daemon for refreshing
index.html, restarning and enabling nginx and z-refresh daemons !

```
