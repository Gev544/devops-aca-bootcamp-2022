# #!/bin/bash
        
echo "start..."

#Create a S3 Bucket
function createS3Bucket() { 
    set -e

    AWS_S3_Bucket=$(aws s3api create-bucket \
    --bucket my-first-aca-devops \
    --region us-east-1)
}

#Create HTML and Upload
function uploadFile() { 
    set -e

    echo "hello world" > index.html
   
    AWS_Upload_HTML=$(aws s3 cp index.html s3://my-first-aca-devops/)
}

# Create vpc with cidr block 10.0.0.0//16
function createVpc() { 
    set -e

    AWS_VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --query 'Vpc.{VpcId:VpcId}' \
    --output text)

    if [[ $? -ne 0 ]]; then
		cleanUp
        echo 'asdasz'
	else 
        echo "Creating Vpc..."
	fi
}

    # Create a public subnet
    function createSubnet() { 
    set -e
    
    echo "Creating subnet..."
        AWS_SUBNET_PUBLIC_ID=$(aws ec2 create-subnet \
        --vpc-id $AWS_VPC_ID --cidr-block 10.0.1.0/24 \
        --availability-zone us-east-1f --query 'Subnet.{SubnetId:SubnetId}' \
        --output text)

        if [[ $? -ne 0 ]]; then
            cleanUp
        else 
            echo "Creating subnet..."
        fi
    }

    # Create an Internet Gateway
    function createInternetGateway() { 
        set -e

        AWS_INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway \
        --query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
        --output text)

        if [[ $? -ne 0 ]]; then
            cleanUp
        else 
            echo "Creating Internet Gateway..."
        fi
    }

    # Attach Internet gateway to your VPC
    function attachGiveaway() { 
        set -e

        echo "Attach Internet Gateway to VPC..."
        aws ec2 attach-internet-gateway \
        --vpc-id $AWS_VPC_ID \
        --internet-gateway-id $AWS_INTERNET_GATEWAY_ID
    }

    # Create a route table
    function createRouteTable() { 
        set -e

        AWS_CUSTOM_ROUTE_TABLE_ID=$(aws ec2 create-route-table \
        --vpc-id $AWS_VPC_ID \
        --query 'RouteTable.{RouteTableId:RouteTableId}' \
        --output text )

        if [[ $? -ne 0 ]]; then
            cleanUp
        else 
            echo "Creating Internet Route Table..."
        fi
    }

    # Create route to Internet Gateway
    function createRouteGtw() { 
        set -e

        aws ec2 create-route \
        --route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
        --destination-cidr-block 0.0.0.0/0 \
        --gateway-id $AWS_INTERNET_GATEWAY_ID
    
        if [[ $? -ne 0 ]]; then
            cleanUp
        else 
        echo "Create route to Internet Gateway..."
        fi
    }


    # Associate the public subnet with route table
    function associateSubnet() { 
        set -e

        echo "Associate the public subnet with route table..."
        AWS_ROUTE_TABLE_ASSOID=$(aws ec2 associate-route-table  \
        --subnet-id $AWS_SUBNET_PUBLIC_ID \
        --route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
        --output text)

        if [[ $? -ne 0 ]]; then
            cleanUp
        else 
        echo "Create route to Internet Gateway..."
        fi
    }

# Associate the public subnet with route table
function createSecurityGroup() { 
    set -e

    echo "create Security Group..."
    AWS_SECURITY_GROUP=$(aws ec2 create-security-group \
    --tag-specification 'ResourceType=security-group,Tags=[{Key=Name,Value='securityGroup'}]' \
    --group-name SSH-HTTP-Access \
    --description "Security group" \
    --vpc-id $AWS_VPC_ID \
    --query GroupId \
    --output text)

    if [[ $? -ne 0 ]]; then
		cleanUp
	else 
      echo "Create route to Internet Gateway..."
	fi
}

# Open the SSH port(22)
function openSSH() { 
    set -e

    aws ec2 authorize-security-group-ingress \
    --group-id $AWS_SECURITY_GROUP \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

    if [[ $? -ne 0 ]]; then
		cleanUp
	else 
      echo "Open the SSH port(22)..."
	fi
}

#Generate Key Pair
function generateKeyPair() { 
    set -e

    AWS_KEY_PAIR=$(aws ec2 create-key-pair \
    --key-name EC2Key \
    --query "KeyMaterial" \
    --output text > EC2Key.pem && \
    chmod 400 EC2Key.pem)

    if [[ $? -ne 0 ]]; then
		cleanUp
	else 
        echo "generate Key Pair..."
	fi
}

    function nginx {
        var=$(curl --silent rate.am | grep -A 3 ameria | tail -2 | sed 's/<\/*[^>]*>//g')
        now=$(date)

        echo "<h1>show usd/amd price from rate.am for Ameria Bank </h1> <h2>$var</h2> <span>"$now" </span>" >> index.html
        echo "<meta http-equiv="refresh" content="10">" >> index.html

        
        sleep 8
    }


#create ec2 instance
function createAwsEc2Instance() { 
 
    AWS_Instance=$(aws ec2 run-instances \
        --tag-specification 'ResourceType=instance,Tags=[{Key=Name,Value='ec2'}]' \
        --image-id ami-08d4ac5b634553e16 \
        --count 1 \
        --instance-type t2.micro \
        --key-name EC2Key \
        --security-group-ids $AWS_SECURITY_GROUP \
        --subnet-id $AWS_SUBNET_PUBLIC_ID \
        --associate-public-ip-address | grep "InstanceId" | cut -d '"' -f 4) && \
	instancePublicIp=$(aws ec2 describe-instances \
		--instance-id $AWS_Instance | \
		grep "PublicIpAddress" | \
		cut -d '"' -f 4)


        if [[ $? -ne 0 ]]; then
            cleanUp
        else 
			echo "create instance..."
        fi
           	
	#download file on ec2 instance
    ssh -i EC2Key.pem ubuntu@$instancePublicIp "sudo chown ubuntu:ubuntu /var/www/html"
	scp -i EC2Key.pem index.html ubuntu@$instancePublicIp:/var/www/html/index.html
    ssh -i EC2Key.pem ubuntu@$instancePublicIp "sudo apt update && sudo apt install nginx && sudo mv nginx.conf /etc/nginx/sites-enabled/" 

	echo "$instancePublicIp"
    }

    function systemd () {
      ssh -i EC2Key.pem ubuntu@$instancePublicIp "sudo chown ubuntu:ubuntu /usr/bin"
      ssh -i EC2Key.pem ubuntu@$instancePublicIp "sudo chown ubuntu:ubuntu /etc/systemd/system/"
      scp -i EC2Key.pem rateInfo.sh ubuntu@$instancePublicIp:/usr/bin
      scp -i EC2Key.pem rateInfo.service ubuntu@$instancePublicIp:/etc/systemd/system/

      ssh -i EC2Key.pem ubuntu@$instancePublicIp "sudo systemctl daemon-reload && sudo systemctl start rateInfo.service && sudo systemctl status rateInfo.service"
    }

    # create IAM
    function createIAM () {

        AWS_Create_IAM=$(aws iam create-user \
            --user-name aca-devops \
            --permissions-boundary arn:aws:iam::aws:policy/AmazonS3FullAccess \
            --output text)

      AWS_IAM_Access_Key=$(aws iam create-access-key \
      --user-name aca-devops > iam_user)

        AWS_IAM_User_Id=$(cat iam_user | grep AccessKeyId | awk '{print $2 }' | tr -d "," | tr -d '"')
        AWS_IAM_User_Secret_Access_Key=$(cat iam_user | grep SecretAccessKey | awk '{print $2 }' | tr -d "," | tr -d '"')

}

    #mount s3 bucket to ec2 instance
    function mount () {
        ssh -i EC2Key.pem ubuntu@34.239.180.81 "sudo apt update  && \
        sudo apt-get install s3fs && \
        sudo touch /etc/passwd-s3fs
        sudo chown ubuntu:ubuntu /etc/passwd-s3fs && \
        sudo echo $AWS_IAM_User_Id:$AWS_IAM_User_Secret_Access_Key > /etc/passwd-s3fs && \
        sudo chown 600 /etc/passwd_s3fs  && \
        sudo mkdir -p /var/www/aca_devops_bootcamp && \
        sudo chown -R ubuntu:ubuntu /var/www/aca_devops_bootcamp && \
        sudo cp /etc/passwd-s3fs ~/.passwd_s3fs && \
        sudo chmod 640 ~/.passwd_s3fs && \
        sudo chmod 640 /etc/passwd_s3fs && \
        s3fs bucket-devops-aca.s3 /home/ubuntu/emtyDirectory -o passwd_file=${HOME}/.passwd_s3fs  -o use_path_request_style"
     }

function start () {
	createS3Bucket
	uploadFile
    createVpc
    createSubnet
    createInternetGateway
    createInternetGateway
    attachGiveaway
    createRouteTable
    createRouteGtw
    associateSubnet
    createSecurityGroup
    openSSH
    generateKeyPair
    reateAwsEc2Instance
    nginx
    mount
}

start

function cleanUp () {
    ## Delete custom security group
    aws ec2 delete-security-group \
    --group-id $AWS_SECURITY_GROUP
    
    ## Delete internet gateway
    aws ec2 detach-internet-gateway \
    --internet-gateway-id $AWS_INTERNET_GATEWAY_ID \
    --vpc-id $AWS_VPC_ID &&
    aws ec2 delete-internet-gateway \
    --internet-gateway-id $AWS_INTERNET_GATEWAY_ID
    
    ## Delete the custom route table
    aws ec2 disassociate-route-table \
    --association-id $AWS_ROUTE_TABLE_ASSOID &&
    aws ec2 delete-route-table \
    --route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID
    
    ## Delete the public subnet
    aws ec2 delete-subnet \
    --subnet-id $AWS_SUBNET_PUBLIC_ID
    
    ## Delete the vpc
    aws ec2 delete-vpc \
}


echo "succesfull..."