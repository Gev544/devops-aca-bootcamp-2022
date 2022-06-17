#!/bin/bash



if [[ $1 = "create" ]]
then
	./create-aws-script.sh
	if [[ $? != 0 ]]
	then 
		./delete-aws-script.sh
		echo "!!! Something is wrong !!!"
		exit
	fi
	echo "Created Instance with Custome Resources!!!"
	
elif [[ $1 = "delete" ]]
then
	./delete-aws-script.sh
	echo "Deleted Instance and Custome Resources!!!"
else echo -e "!!! Argument not recognized !!! \n delete/create "
fi
