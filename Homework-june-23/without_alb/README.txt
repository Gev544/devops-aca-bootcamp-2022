Run create_myvpc_ssl.sh (this will create custom vpc, internet gateway, subnet, route table, security group, instance, s3 bucket, s3fullaccess iam user and upload nessesary files to s3 bucket).
Also script will create DNS A record in AWS Route53 Hosted Zone to redirect traffic from ipv4 to supdomain.
Also It will copy files (also there should be add one hidden file after first step) from "ec2" directroy to your aws instance home directory and run "run.sh" script inside ec2 instance which will create directory in home, mount s3 bucket to it and make nginx to read index.html file from s3 bucket.
Also it will create systemd service to refresh index.html file every 60 seconds with fresh data from rate.am(USD - AMD currency for Ameribank).
Next it will generete ssl lets encrypt certificate and create cron job for check and renew ssl certificate if it expire within 30 days.
Genereted certeficate files will be copied to s3 bucket for other use cases.
Run delete_myvpc_ssl.sh to destroy all resources created before.
