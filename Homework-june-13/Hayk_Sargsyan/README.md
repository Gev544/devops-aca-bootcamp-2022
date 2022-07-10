When you run the script with -create- option ,it creates 1 EC2 instance (ubuntu) with all necessary resources (it's not using default resources , its create his own ones) . You can use one of two scripts (-run-aws.sh- and -function-BONUS-mode.sh-). 
When you run the script with -delete- options , it delete instance and all resources.
run-aws.sh - is working with -create-aws-script.sh- and -delete-aws-script.sh- and when instance is created, its creating a text file with resources ids !
function-BONUS-mode.sh - is doing a same thing but its working with functions !

usage
```
./run-aws.sh [option] 
or 
./function-BONUS-mode.sh [option]
```
options:

create - Creating ec2 instance with all necessary resources

delete - Deleting ec2 instance and all resources that created by -create- option
