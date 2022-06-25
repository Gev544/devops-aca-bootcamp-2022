

At first check your AWS cli exist, typing  "aws --version"
--------------------------------------------------------

This vpc.sh scrypt creates AWS instance with custom configurationes.
You can change instance, and more parameteres every time before running this scrypt.
The scrypt have a error checking ability.
After running the scrypt addes status informaition in CATCH_ALL_ID,INSTANCE_ID,INSTANCE_IP, and key.pem files.

If everything is ok while creating, you will see "Done" INSTANCE IP Address IS ......"  in end of line.

Now you can connect to your instance with ssh, typing "ssh -i key.pem ubuntu@"receaved ip address" 

--------------------------------------------------------------------------------------------------------------

Use IAM.sh scrypt to add IAM user to "Administrators" group with "Admin" username.
You can change all parameters of IAM user with created variables in scrypt.
After running script all necesery information for login with Admin user have been created in "Iam_user.txt" file. 
Aws required to reset your password at login.
