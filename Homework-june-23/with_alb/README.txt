Run create_myvpc_alb.sh.
This will create custom vpc, internet gateway, subnet, route table, security group, 2 identical instances, s3 bucket, s3fullaccess iam user and upload nessesary files to s3 bucket, aplication load balancer with http and https target group and listeners and register previosly created instances to it.
Also script will create DNS A record in AWS Route53 Hosted Zone to redirect web traffic to Aplication Load Balanser.
Next it will copy files (also there should be add one hidden file) from "ec2" directroy to instances home directory and run "run.sh" script inside ec2 instances which will create directory in home directory, mount s3 bucket to it and make nginx to read index.html file from s3 bucket.
Also it will create systemd service to refresh index.html file every 60 seconds with fresh data from rate.am(USD - AMD currency for Ameribank).
Run delete_myvpc_alb.sh to destroy all resources created before.
