#!/bin/bash



user=Admin
group=Administrators
password=My!User1Login8P@ssword
#ADMIN POLICY

policy=arn:aws:iam::aws:policy/AWSMarketplaceFullAccess

   aws iam create-user \
  --user-name $user   
  
   aws iam get-user \
  --user-name $user \
  --output yaml >> Iam_user.txt
 
   aws iam create-group \
  --group-name $group \
  --output yaml >> Iam_user.txt   
  
  aws iam add-user-to-group \
  --user-name $user \
  --group-name $group
  
  aws iam create-login-profile \
  --user-name=$user \
  --password=$password \
  --password-reset-required 
  
  aws iam attach-user-policy \
  --user-name $user \
  --policy-arn $policy  
  
  aws iam list-attached-user-policies \
  --user-name $user 
  
  aws iam create-access-key \
  --user-name $user \
  --output yaml >> Iam_user.txt

 echo "user is $user" 
 echo "group is $group"
 echo "pasword is $password"
 echo $password >> Iam_user.txt
 echo "you must change this password at login" 
 echo "DONE"

