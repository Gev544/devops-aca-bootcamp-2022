1. Run create_myvpc_s3.sh (this will create custom vpc, internet gateway, subnet, route table, security group, instance, s3 bucket, s3fullaccess iam user and upload nessesary files to s3 bucket)

2. Copy all files (also there should be add one hidden file after first step) from "ec2" directroy to your aws instance home directory.

3. ssh to instance and execute "run.sh" script from ubuntu user home directory. This will create directory in home, mount s3 bucket to it and make nginx to read index.html file from s3 bucket. Also it will create systemd service to refreshh index.html file every 60 seconds with fresh data from rate.am(USD - AMD currency).

4. Run delete_myvpc_s3.sh to destroy all resources created before.
