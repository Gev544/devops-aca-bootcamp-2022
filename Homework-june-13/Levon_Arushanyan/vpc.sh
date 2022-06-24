#!/bin/bash 


#for custom parameters

VPC_cidr=10.0.0.0/16
VPC_name=MYvpc
Subnet_name=MYsubnet
Subnet_cidr=10.0.0.0/24
Igw_name=MYgateway
Rtb_name=MYroute_table
Sec_gr_name=MYsecuryt_group
Sec_gr_descr=AMI_users
Instance_name=Ubuntu
ami=ami-052efd3df9dad4825
count=1
t2=t2.micro
key=key

#if any error checked, start removing functions

delete_security_group() { aws ec2 delete-security-group \
        --group-id $SG_ID
}

#removing subnet

delete_subnet() { aws ec2 delete-subnet \
         --subnet-id $Subnet_ID 
}


#removing route table

delete_route_table() { aws ec2 delete-route-table \
          --route-table-id $RTB_ID
}



#deataching internet gateway from VPC
   
detach_gateway() { aws ec2 detach-internet-gateway \
           --internet-gateway-id $IGW_ID \
           --vpc-id $VPC_ID
}

#removing internet gateway
delete_gateway() { aws ec2 delete-internet-gateway \
            --internet-gateway-id $IGW_ID
}


#removing VPC
delete_vpc() { aws ec2 delete-vpc \
	     --vpc-id $VPC_ID
}





#removing Key Pair
#delete_KeyPair() { aws ec2 delete-key-pair \
	     # --key-name sshkey
             # rm -f key.pem


#Creating VPC 

VPC_ID=$(aws ec2 create-vpc \
	--cidr-block $VPC_cidr \
	--query Vpc.VpcId \
	--output text)

if [ ! $? = 0 ]

then 
	echo "something wrong with vpc"
        echo "------------------------------"


else       
	aws ec2 create-tags \
         --resources $VPC_ID \
         --tags Key=Name,Value=$VPC_name

echo "VPC is created. VPC ID is $VPC_ID"
fi

#Creating Subnet 

Subnet_ID=$(aws ec2 create-subnet \
	--vpc-id $VPC_ID \
	--cidr-block $Subnet_cidr \
	--query Subnet.SubnetId \
	--output text)

if [ ! $? = 0 ]

then 	
     echo "something wrong with subnet"
     delete_vpc
     echo "------------------------------"

    

else  
        aws ec2 create-tags \
        --resources $Subnet_ID \
        --tags Key=Name,Value=$Subnet_name
echo "Subnet is created. Subnet ID is $Subnet_ID"
fi

#Creating Internet Gateway for VPC

IGW_ID=$(aws ec2 create-internet-gateway \
	--query InternetGateway.InternetGatewayId \
	--output text)

if [ ! $? = 0 ]


then
       	echo "something wrong with gateway"
        delete_subnet
	delete_vpc
	echo "------------------------------"

	
else
	aws ec2 create-tags \
        --resources $IGW_ID \
        --tags Key=Name,Value=$Igw_name

echo "Gateway is created. Gateway ID is $IGW_ID"
fi


#Attach gateway to VPC
        
        aws ec2 attach-internet-gateway \
	--vpc-id $VPC_ID \
	--internet-gateway-id $IGW_ID

#creating route table

RTB_ID=$(aws ec2 create-route-table \
	--vpc-id $VPC_ID \
	--query RouteTable.RouteTableId \
	--output text)

if [ ! $? = 0 ]        
       
then 
	echo "something wrong with routing table"
        detach_gateway
        delete_gateway	
	delete_subnet
	delete_vpc
	
	echo "------------------------------"


else
	
	aws ec2 create-tags \
        --resources $RTB_ID \
        --tags Key=Name,Value=$Rtb_name

echo "Route table is created. Route table ID is $RTB_ID"
fi

#associate route tabe to subnet

Asociate=$(aws ec2 associate-route-table \
	   --subnet-id $Subnet_ID \
           --route-table-id $RTB_ID \
	   --output text)
	  
echo "Route table is associated to Subnet"


##Creating default route to gateway

        aws ec2 create-route \
	--route-table-id $RTB_ID \
	--destination-cidr-block 0.0.0.0/0 \
	--gateway-id $IGW_ID 

#Creating Security Group

SG_ID=$(aws ec2 create-security-group \
	--vpc-id $VPC_ID \
	--group-name $Sec_gr_name \
	--description $Sec_gr_descr \
	--query GroupId \
	--output text)

if [ ! $? = 0 ]

then 
	echo "something wrong with security group"
	detach_gateway
	delete_gateway
        delete_subnet
	delete_route_table
	delete_vpc
	
	echo "------------------------------"


fi 


#Creating remote SSH connection rules for created security group
        
       aws ec2 authorize-security-group-ingress \
	--group-id $SG_ID \
	--protocol tcp \
	--port 22 \
	--cidr 0.0.0.0/0 

#checking for key duplicate, if exists remove it
# describe () { aws ec2 describe-key-pairs \
             #--key-name key
     #}

#if
            # [ ! -s describe ]
   # then     
	   # aws ec2 delete-key-pair \
           #--key-name Key

#echo "There is no Key to pair"
             
#fi

#if
            # [ -f AWS_key.pem ]
     # then
            # rm -f AWS_key.pem
      #fi

#Creating SSH key 

	aws ec2 create-key-pair \
	--key-name key \
	--query "KeyMaterial" \
	--output text > key.pem
         chmod 400 key.pem        
       	


#Running EC2 Instance with public address association

Instance_ID=$(aws ec2 run-instances \
	--image-id $ami \
	--count $count \
	--instance-type $t2 \
	--key-name key \
	--security-group-ids $SG_ID \
	--subnet-id $Subnet_ID \
        --associate-public-ip-address \
	--output text | grep INSTANCES | grep -o "\bi-0\w*")

if [ ! $? = 0 ]

then 
	 echo "something wrong with instance"
	       detach_gateway
               delete_gateway
               delete_subnet
               delete_route_table
               delete_vpc
               
             
	       echo "------------------------------"
	       
else     
       	aws ec2 create-tags \
        --resources $Instance_ID \
        --tags Key=Name,Value=Test_ubuntu     

fi 	


#Checking created Instance public ip address	

Public_IP=$(aws ec2 describe-instances \
	--instance-ids $Instance_Id \
	--query Reservations[*].Instances[*].PublicIpAddress \
	--output text)

echo $VPC_ID >> CATCH_ALL_ID
echo $Subnet_ID >> CATCH_ALL_ID
echo $Asociate >> CATCH_ALL_ID
echo $RTB_ID >> CATCH_ALL_ID
echo $IGW_ID >> CATCH_ALL_ID
echo $SG_ID >> CATCH_ALL_ID
echo $Instance_ID >> INSTANCE_ID
echo $Public_IP >> INSTANCE_IP
echo "DONE"
echo "INSTANCE IP Address IS $Public_IP"




