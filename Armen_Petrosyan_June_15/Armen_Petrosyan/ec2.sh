#!/bin/bash +x




aws ec2 run-instances --image-id ami-09d56f8956ab235b3 --count 1 --instance-type t2.micro --key-name 1st --security-group-ids $Sec_GrId --subnet-id $Pub_SubId --user-data file://nginx_install.sh --associate-public-ip-address 

read -p "   Enter instance_id: " instance_id



echo "   "


if [ -z "$instance_id" ]

then

    echo "   Exiting from script. Please enter instance id."

    aws ec2 terminate-instances --instance-ids $instance_id

    exit -1

else

    echo "  --> Fetching Instance $instance_id status."

fi



instance_state=$(aws ec2 describe-instance-status --instance-id $instance_id --query 'InstanceStatuses[*].InstanceState.Name' --output text)

size=${#instance_state}

if [ -z "$instance_state" ]

then
echo "  --> Instance $instance_id is not in running state. Starting the instance"



instance_start_invoke=$(aws ec2 start-instances --instance-ids $instance_id --query 'StartingInstances[*].CurrentState.Name' --output text)


echo "  --> start instance command execution result : $instance_start_invoke"


if [ "$instance_start_invoke" = "pending" ]

    then

        fetch_instance_start=$instance_start_invoke


while [ "$fetch_instance_start" = "pending" ]

    do

        fetch_instance_start=$(aws ec2 start-instances --instance-ids $instance_id --query 'StartingInstances[*].CurrentState.Name' --output text)

        echo "  --> Instance state : $fetch_instance_start"

sleep 5

done

echo "  --> -------------------------------------------"


echo "  --> Instance state : $fetch_instance_start"


echo "  --> Checking Instance Health status"


fetch_instance_health="initializing"


while [ "$fetch_instance_health" = "initializing" ]
    do
        fetch_instance_health=$(aws ec2 describe-instance-status --instance-id $instance_id --query 'InstanceStatuses[*].InstanceStatus.Status' --output text)
echo "  --> Instance health check : $fetch_instance_health"

sleep 10

done

echo "  --> -------------------------------------------"



echo "  --> Instance health : $fetch_instance_health"


echo "Fetching Instance Ip"


instance_ip=$(aws ec2 describe-instances --instance-id $instance_id --query 'Reservations[*].Instances[*].PublicIpAddress' --output=text)



echo "  --> Launching Instance $instance_id with instances public IP $instance_ip"

file_path=~/Downloads/1st.pem

echo "Launch Instance using command : ssh -i $file_path ubuntu@$instance_ip"

fi

else

if [ "$instance_state" = "running" ]
    then
        instnace_stop_invoke=$(aws ec2 stop-instances --instance-ids $instance_id --query 'StoppingInstances[*].CurrentState.Name' --output text)
        echo "  --> Instance state : $instnace_stop_invoke"
        echo "  --> Instance will be stopped after sometime."

fi

fi

#connect to instance via ssh

ssh -i $file_path ubuntu@$instance_ip


