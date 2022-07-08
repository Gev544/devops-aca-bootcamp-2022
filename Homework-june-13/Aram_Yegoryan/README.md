This script is for creating EC2 Instance in AWS.

To launch the script please run aws_creating_script.sh.

At the first it creates VPC and gives the name to VPC. If there something wrong it stop working and shows what "VPC is not created".

After VPC it creates subnet and gives the name to subnet. After that it start checking. If something gone wrong it removes subnet and VPC from AWS.

If everything okay it goes to 3rd point and creates Internet gateway and gives the name to created internet gateway. After that it start checking like before. If something gone wrong it remove internet gateway, subnet and VPC from AWS. If everything gone okay it attach created gatway to VPC.

On 4th point it creates route table and start checking the working status. If something gone wrong, it remove route table, internet gateway, subnet and VPC from AWS. If everything gone without errors it gives the name to route table and associate it to subnet. After that it creates the routes.

On 5th point it creates security group and if something not working it remove thole created points which was created before. If everything works without errors it gives the name to security group and write the rules for group.

After that it starting to check the Key Pair availibility and if there is Key Pair with the name AutoKeyPair it removes that and also it checks the KeyPair.pem file availibility in directory. If its persist script will remove it. After that it creates a new Key Pair with AutoKeyPair name.

On the last point it creates instance and if there is an error it will remove whole created before. Also it get the public IP and write on terminal.

Perfect, your AWS EC2 Instance ready to launch. So please launch it and have a lot of fun.

During writing I use some Functions, If/Else, vailables. Also all IDs from created points I put in AWS.txt file which will be created on the first launch.
