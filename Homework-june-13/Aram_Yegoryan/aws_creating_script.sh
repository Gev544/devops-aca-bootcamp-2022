#!/bin/bash

#if error persist remove whole created 

#removing security group
delete_security_group () { aws ec2 delete-security-group \
        --group-id $security_group 
}

 #removing subnet
 delete_subnet () { aws ec2 delete-subnet \
         --subnet-id $subnet 
 }        

  #removing route table
  delete_route_table () { aws ec2 delete-route-table \
          --route-table-id $route_table 
  }         

   #detaching internet gateway from VPC
   detach_gateway () {  aws ec2 detach-internet-gateway \
           --internet-gateway-id $gateway \
           --vpc-id $vpc 
   }

    #removing internet gateway
    delete_gateway () { aws ec2 delete-internet-gateway \
            --internet-gateway-id $gateway
    }

     #removing VPC
     delete_vpc () { aws ec2 delete-vpc \
	     --vpc-id $vpc
     }

      #removing Key Pair
      delete_KeyPair () { aws ec2 delete-key-pair \
             --key-name autoKeyPair
             rm -f KeyPair.pem
      }

#creating vpc
vpc=$(aws ec2 create-vpc \
	--cidr-block 10.0.0.0/16 \
	--query Vpc.VpcId \
	--output text)

if 
	[ -s $vpc ]
then
	echo "VPC is not created"
	exit
else

#giving name to created vpc
aws ec2 create-tags \
	--resources $vpc \
	--tags Key=Name,Value=autoVPC
echo $vpc > AWS.txt
echo "VPC is created. Your VPC is $vpc"
fi


 #creating subnet
 subnet=$(aws ec2 create-subnet \
	 --vpc-id $vpc \
	 --cidr-block 10.0.0.0/24 \
	 --query Subnet.SubnetId \
	 --output text)

 if 
	 [ -s $subnet ]
 then
	 echo "Subnet is not created" 
	 delete_vpc
	 echo "VPC removed"
	 exit
 else

 #giving name to created subnet
 aws ec2 create-tags \
	 --resources $subnet \
	 --tags Key=Name,Value=autoSubnet 
 echo $subnet >> AWS.txt
 echo "Subnet is created. Your Subnet is $subnet"
 fi


  #creating internet gateway
  gateway=$(aws ec2 create-internet-gateway \
	  --query InternetGateway.InternetGatewayId \
	  --output text)

  if 
	  [ -s $gateway ]
  then
	  echo "Internet Gateway is not created"
          delete_subnet
          delete_vpc
	  echo "VPC and subnet are removed"
	  exit
  else

  #giving name to created internet gateway
  aws ec2 create-tags \
	  --resources $gateway \
	  --tags Key=Name,Value=autoGateway
  echo $gateway >> AWS.txt
  echo "Internet gateway is created. Your internet gateway is $gateway"
  fi

  #attaching gateway to created VPC
  aws ec2 attach-internet-gateway \
	  --vpc-id $vpc \
	  --internet-gateway-id $gateway


   #creating route table
   route_table=$(aws ec2 create-route-table \
	   --vpc-id $vpc \
	   --query RouteTable.RouteTableId \
	   --output text)

   if 
	   [ -s $route_table ]
   then
          echo "Route table is not created"
          detach_gateway
          delete_gateway
          delete_subnet
	  delete_vpc
	  echo "VPC, subnet and gateway are removed"
	  exit 
   else

   #giving name to created route table
   aws ec2 create-tags \
	   --resources $route_table \
	   --tags Key=Name,Value=autoRouteTable
   echo $route_table >> AWS.txt
   echo "Route table is created. Your route table is $route_table"
   fi

   #associating route table to subnet
   associate=$(aws ec2 associate-route-table \
	   --subnet-id $subnet \
           --route-table-id $route_table \
	   --query AssociationId \
	   --output text)  
	   echo $associate >> AWS.txt
	   echo "Route table is associated to Subnet. Association ID is $associate"

   #creating routes
   aws ec2 create-route \
 	   --route-table-id $route_table \
 	   --destination-cidr-block 0.0.0.0/0 \
 	   --gateway-id $gateway 1>/dev/null
   

    #creating security group
    security_group=$(aws ec2 create-security-group \
	    --group-name autoSSH \
	    --description "Security group for automatic created SSH" \
	    --vpc-id $vpc \
	    --query GroupId \
	    --output text)

    if 
	    [ -s $security_group ]
    then
	    echo "Security group is not created"
	    detach_gateway
            delete_gateway
	    delete_subnet
	    delete_route_table
	    delete_vpc
	    echo "VPC, subnet, gateway and route table are removed"
	    exit 
    else

    #giving name to security group
    aws ec2 create-tags \
	    --resources $security_group \
	    --tags Key=Name,Value=autoSG
  
    echo $security_group >> AWS.txt
    echo "Security group is created. Your security group is $security_group"
    fi

    #writing rules for security group
    aws ec2 authorize-security-group-ingress \
	    --group-id $security_group \
	    --protocol tcp \
	    --port 22 \
	    --cidr 0.0.0.0/0 1>/dev/null


     #checking the key name availibility, if exists remove it
     describe () { aws ec2 describe-key-pairs \
	     --key-name autoKeyPair 2>/dev/null  
     }
     if
	     [ ! -s describe ]
     then
	     aws ec2 delete-key-pair \
		     --key-name autoKeyPair
     else
	     echo "There is no Key Pair"
     fi

      if
	     [ -f KeyPair.pem ]
      then
	     rm -f KeyPair.pem
      fi

     #creating key pair
     aws ec2 create-key-pair \
	     --key-name autoKeyPair \
	     --query "KeyMaterial" \
	     --output text > KeyPair.pem
	     chmod 400 KeyPair.pem
	     echo "Key Pair is created"

      #creating ec2 instance
      instance=$(aws ec2 run-instances \
	      --image-id ami-08d4ac5b634553e16 \
	      --count 1 \
	      --instance-type t2.micro \
	      --key-name autoKeyPair \
	      --security-group-ids $security_group \
	      --subnet-id $subnet \
	      --associate-public-ip-address \
	      --output text | grep INSTANCES | grep -o "\bi-0\w*")
		      
      if 
	      [ -s $instance ]
      then
	      echo "Instance is not created"
	      detach_gateway  
              delete_gateway 
	      delete_subnet
	      delete_route_table 
	      delete_security_group
	      delete_vpc
	      delete_KeyPair
	      echo "VPC, subnet. gateway, route table, security group and Key Pair are removed"
	      exit 
       else
       
       #giving name to created instance
       aws ec2 create-tags \
	       --resources $instance \
	       --tags Key=Name,Value=autoInstance

       echo $instance >> AWS.txt
       echo "Instance is created. Your instance is $instance"
       fi


       #getting public IP address
       publicIP=$(aws ec2 describe-instances \
	       --instance-ids $instance \
	       --query Reservations[*].Instances[*].PublicIpAddress \
	       --output text)

echo "Success. Your Instance IP Address is $publicIP"
echo "Have a lot of fun"
echo $publicIP >> AWS.txt
