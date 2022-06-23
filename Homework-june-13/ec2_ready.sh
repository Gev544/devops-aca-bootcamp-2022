### crate vpc -------  then  automaticali will be created ---------------------- ROUTE TABLE, NETWORK ACLS AND SECURITY GROUPS ------------------


# instance parametrs name
name=test

# cheek if instance exsist and rename

describe_name=$(aws ec2 describe-instances \
	--filters "Name=tag-value,Values=$name")
sleep 15
desc_name=$(echo $describe_name | cut -d " " -f 1)
echo $desc_name

	while [[ $desc_name -eq "RESERVATIONS" ]]
	do
		num=$(echo $name | cut -c 5-)
		name1=$(echo $name | cut -c 1-4)
		
		num1=$(( $num + 1 ))
		
		name="${name1}${num1}"
		echo $name
		describe_name1=$(aws ec2 describe-instances \
        		--filters "Name=tag-value,Values=$name")
		if [[ -z $describe_name1 ]]
		then 
			break
		fi
		echo $desc_name

	done



# variables of name

vpc_name="${name}-vpc"
sub_name="${name}-sub"
getway_name="${name}-getway"
rtb_name="${name}-rtb"
acl_name="${name}-acl"
sec_group_name="${name}-sec_group"
key_pair_name="${name}"
ins_tname=${name}



### crate vpc


vpc () {
       vpc_var=$(aws ec2 create-vpc \
    		--cidr-block 10.0.0.0/16 \
    		--tag-specification 'ResourceType=vpc,Tags=[{Key=Name,Value='$vpc_name'}]' \
    		--query Vpc.VpcId \
    		--output text)    
		       echo 'vpc_var='$vpc_var > ${name}-instance_del
}

### crate subnet 


sub () {
	sub_var=$(aws ec2 create-subnet \
    		--vpc-id $vpc_var \
    		--cidr-block 10.0.0.0/24 \
    		--availability-zone us-east-1a \
    		--tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value='$sub_name'}]' \
    		--query Subnet.SubnetId --output text)
	echo 'sub_var='$sub_var >> ${name}-instance_del
}



### create-internet-gateway


internet_getway () {
	getway=$(aws ec2 create-internet-gateway \
    		--tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value='$getway_name'}]' \
    		--query InternetGateway.InternetGatewayId \
    		--output text)
	echo 'getway='$getway >> ${name}-instance_del
}



### attach-internet-gateway
attach () {
	aws ec2 attach-internet-gateway \
    		--internet-gateway-id $getway \
    		--vpc-id $vpc_var
	attach_state=$(aws ec2 describe-internet-gateways \
		--filters "Name=attachment.vpc-id,Values=$vpc_var")
}




### remove defoult route table and crate new one

route_table () {

	# describe route tabe id
        rtb_inf=$(aws ec2 describe-route-tables \
                --filters "Name=vpc-id,Values=$vpc_var")

	# defoult route table id
        rtb_old=$(echo $rtb_inf | cut -d " " -f 3)

	# defoult assosasione id
	rtbass_old=$(echo $rtb_inf | cut -d " " -f 7)


	# crate new route table
	rtb_new=$(aws ec2 create-route-table \
                --tag-specification 'ResourceType=route-table,Tags=[{Key=Name,Value='$rtb_name'}]' \
                --vpc-id $vpc_var \
                --query RouteTable.RouteTableId \
                --output text)

	# replace new assocatione of subnet to route
	rtbass_inf=$(aws ec2 replace-route-table-association \
		--association-id $rtbass_old \
		--route-table-id $rtb_new)

	rtbass_new=$(echo $rtbass_inf | cut -d " " -f 1)

        # delete defoult route table
	aws ec2 delete-route-table \
		--route-table-id $rtb_old



	# add  route internet getway
	route_new=$(aws ec2 create-route \
                --route-table-id $rtb_new \
                --destination-cidr-block 0.0.0.0/0 \
		--gateway-id $getway)
	echo 'rtb_new='$rtb_new >> ${name}-instance_del


}



### remove defoult acsses control list and crate new one

acl () {

	# describe defoult acsses control list
	acl_info=$(aws ec2 describe-network-acls \
		--filters "Name=vpc-id,Values=$vpc_var")

	# acl aclassoc
	aclassoc=$(echo $acl_info | cut -d " " -f 7)
	acl_id=$(echo $acl_info | cut -d " " -f 3)

	# crate acsses control list
#	acl3=$(aws ec2 create-network-acl \
#		--vpc-id $vpc_var \
#		--tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value='my.acl'}]')

	# find new acl id
#	acl=$(echo $acl3 | tr -s " " | cut -d " " -f 3)

	# replace associatione subnet acl
#	aws ec2 replace-network-acl-association \
#		--association-id $aclassoc \
#		--network-acl-id $acl

	aws ec2 create-network-acl-entry \
		--network-acl-id $acl_id \
		--ingress \
		--rule-number 1 \
		--protocol tcp \
		--port-range From=22,To=22 \
		--cidr-block 0.0.0.0/0 \
		--rule-action allow

	aws ec2 create-tags \
              --resources $acl_id \
              --tags 'Key=Name,Value='$acl_name''


	acl_assoc_info=$(aws ec2 describe-network-acls \
                --filters "Name=association.network-acl-id,Values=$acl_id")
	echo 'acl_id='$acl_id >> ${name}-instance_del


}



sec_group () {

	# describe defoult security_group informatione
	sec_group_info=$(aws ec2 describe-security-groups \
		--filters "Name=vpc-id,Values=$vpc_var")

	# filter secutity_group id
	sec_group_id=$(echo $sec_group_info | cut -d " " -f 6)
	echo 'sec_group_id='$sec_group_id >> ${name}-instance_del

	aws ec2 create-tags \
              --resources $sec_group_id \
              --tags 'Key=Name,Value='$sec_group_name''


	# authorize-security-group-ingress
	ssh_add=$(aws ec2 authorize-security-group-ingress \
		--group-id $sec_group_id \
		--protocol tcp \
		--port 22 \
		--cidr 0.0.0.0/0 \
		--output text) 
	
	http_add=$(aws ec2 authorize-security-group-ingress \
		--group-id $sec_group_id \
		--protocol tcp \
		--port 80 \
		--cidr 0.0.0.0/0 \
		--output text) 

	https_add=$(aws ec2 authorize-security-group-ingress \
                --group-id $sec_group_id \
                --protocol tcp \
                --port 443 \
                --cidr 0.0.0.0/0 \
		--output text)


}


key_pair () {

	#crate key_pair
	priv=$(aws ec2 create-key-pair \
                --key-name $key_pair_name \
		--query 'KeyMaterial' --output text | tee $key_pair_name.pem)

	### change permitione key pair
        chmod 400 $key_pair_name.pem
	echo 'key_pair_name='$key_pair_name >> ${name}-instance_del

}


run_instance() {

        ### install ec2
        ###               ami-0c4f7023847b90238 (64-bit (x86)) ubuntu 20.04 free
        ###               ami-09d56f8956ab235b3 (64-bit (x86)) ubuntu 22.04 free
        ###               ami-0193dcf9aa4f5654e (64-bit (x86)  windows server 2019 free
        inst_inf=$(aws ec2 run-instances \
                --image-id ami-0c4f7023847b90238 \
                --instance-type t2.micro \
                --subnet-id $sub_var \
                --security-group-ids $sec_group_id \
                --associate-public-ip-address \
                --key-name $key_pair_name \
		--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$ins_tname'}]' | tee ${name}-Instans_configurationes)
	inst_id=$(echo $inst_inf | cut -d " " -f 11)
	echo 'inst_id='$inst_id >> ${name}-instance_del
#	aws ec2 describe-instances \
  #  		--filters "Name=instance-type,Values=t2.micro" \
 #   		--query "Reservations[*].Instances[*].[InstanceId]" \
#    		--output text

                }



error_hendaling () {

	if [[ $1 == 1 ]] 
	then
		echo "vpc was not created"
		echo "all clear"
		exit
	elif [[ $1 == 2 ]]
	then
		echo "subnet was not created"
                aws ec2 delete-vpc \
                        --vpc-id $vpc_var
		echo "all cleard"
		exit
	elif [[ $1 == 3 ]]
	then
		echo "internet getway was not created"
		aws ec2 delete-subnet \
		       	--subnet-id $sub_var
                aws ec2 delete-vpc \
			--vpc-id $vpc_var
		echo "all cleard"
		exit
	elif [[ $1 == 4 ]]
        then
                echo "getway was not been attached to vpc"
		aws ec2 delete-internet-gateway \
			--internet-gateway-id $getway
                aws ec2 delete-subnet \
                        --subnet-id $sub_var
                aws ec2 delete-vpc \
                        --vpc-id $vpc_var
		echo "all cleard"
                exit
	elif [[ $1 == 5 ]]
	then
                echo "route table was not been changed corectly"
                aws ec2 detach-internet-gateway \
			--internet-gateway-id $getway \
			--vpc-id $vpc_var
                aws ec2 delete-internet-gateway \
                        --internet-gateway-id $getway
                aws ec2 delete-subnet \
                        --subnet-id $sub_var
                aws ec2 delete-vpc \
                        --vpc-id $vpc_var
		echo "all cleard"
                exit
	elif [[ $1 == 6 ]]
        then
                echo "new route was not been created"
                aws ec2 detach-internet-gateway \
                        --internet-gateway-id $getway \
                        --vpc-id $vpc_var
                aws ec2 delete-internet-gateway \
                        --internet-gateway-id $getway
                aws ec2 delete-subnet \
                        --subnet-id $sub_var
                aws ec2 delete-vpc \
                        --vpc-id $vpc_var
                echo "all cleard"
                exit

	elif [[ $1 == 7 ]]
        then
                echo "for ssh high prevereligition was not been add"
                aws ec2 detach-internet-gateway \
                        --internet-gateway-id $getway \
                        --vpc-id $vpc_var
                aws ec2 delete-internet-gateway \
                        --internet-gateway-id $getway
                aws ec2 delete-subnet \
                        --subnet-id $sub_var
                aws ec2 delete-vpc \
                        --vpc-id $vpc_var
                echo "all cleard"
                exit

	elif [[ $1 == 8 ]]
        then
                echo "ssh or http or https not allowed"
                aws ec2 detach-internet-gateway \
                        --internet-gateway-id $getway \
                        --vpc-id $vpc_var
                aws ec2 delete-internet-gateway \
                        --internet-gateway-id $getway
                aws ec2 delete-subnet \
                        --subnet-id $sub_var
                aws ec2 delete-vpc \
                        --vpc-id $vpc_var
                echo "all cleard"
                exit

	elif [[ $1 == 9 ]]
        then
                echo "key_pair was not created"
		aws ec2 delete-key-pair \
                	--key-name $key_pair_name
                aws ec2 detach-internet-gateway \
                        --internet-gateway-id $getway \
                        --vpc-id $vpc_var
                aws ec2 delete-internet-gateway \
                        --internet-gateway-id $getway
                aws ec2 delete-subnet \
                        --subnet-id $sub_var
                aws ec2 delete-vpc \
                        --vpc-id $vpc_var
		rm -rf $key_pair_name.pem
                echo "all cleard"
                exit




	else
		echo "something vent wrong"
                aws ec2 disassociate-route-table \
                        --association-id $rtbass_new
                aws ec2 detach-internet-gateway \
                        --internet-gateway-id $getway
                aws ec2 delete-internet-gateway \
                        --internet-gateway-id $rtb_new
                aws ec2 delete-subnet \
                        --subnet-id $sub_var
                aws ec2 delete-vpc \
                        --vpc-id $vpc_var
                exit
	fi


}






		mkdir my_aws_pool
		cd my_aws_pool
		vpc
		if [[ -n $vpc_var ]]
		then 
			echo "created vpc by id" $vpc_var
        		sub
		else
			error_hendaling 1
		fi


		if [[ -n $sub_var ]]
		then
			echo "created subnet by id $sub_var"
		        internet_getway
		else
			error_hendaling 2
		fi


		if [[ -n $getway ]]
		then
			echo "created internet getway by id $getway"
			attach
		else
			error_hendaling 3
		fi


		if [[ -n $attach_state ]]
		then
		        echo "vpc :$vpc_var attached internet_getway :$getway"
		        route_table
		else
		        error_hendaling 4
		fi


		if [[ -n $rtb_new ]]
		then
		        echo "route table was changed and id = $rtb_new"
		else
			error_hendaling 5
		fi


		if [[ -n $route_new ]]
		then
		        echo "crate new route allo all"
			acl
		else
		        error_hendaling 6
		fi


		if [[ -n $acl_assoc_info ]]
		then
		        echo "for ssh high prevereligition add"
			sec_group
		else
		        error_hendaling 7
		fi


		if [[ -n $ssh_add && $https_add && $http_add ]]
		then
		        echo "security group allo ssh http https"
			key_pair
		else
		        error_hendaling 8
		fi


		if [[ -n $priv ]]
		then
		        echo "key_pair created"
		        run_instance
		else
		        error_hendaling 9
		fi


		if [[ -n $inst_inf ]]
		then
		        echo "instance created"
		else
		        error_hendaling 9
		fi


	
echo "aws ec2 terminate-instances --instance-ids $inst_id
        sleep 20
        aws ec2 delete-key-pair \
                        --key-name $key_pair_name
                aws ec2 detach-internet-gateway \
                        --internet-gateway-id $getway \
                        --vpc-id $vpc_var
                aws ec2 delete-internet-gateway \
                        --internet-gateway-id $getway
                aws ec2 delete-subnet \
                        --subnet-id $sub_var
                aws ec2 delete-vpc \
                        --vpc-id $vpc_var
                rm -rf $key_pair_name.pem
		rm -rf Instans_configurationes
		rm -rf ${name}-instance_inf" >> ${name}-instance_del




ssh_conect () {

	inst_id=$(echo $inst_inf | cut -d " " -f 11)
	echo $inst_id

	instance_ip=$(aws ec2 describe-instances \
		--instance-ids $inst_id \
		--query "Reservations[*].Instances[*].PublicIpAddress" \
		--output=text)
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i "test.pem" ubuntu@$instance_ip
sudo mkdir hi
exit

}








