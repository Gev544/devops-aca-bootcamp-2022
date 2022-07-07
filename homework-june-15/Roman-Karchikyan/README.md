#  ---- Program to create instance ---- create-instance.sh

# 1. Have aws installed & have your aws configurations
# 2. By default instace will be in 10.0.0.0/24 ip range          -- you can change it in the first code block
# 3. By default instace will get 10.0.0.0/24 subnet range        -- you can change it in the second code block
# 4. By default public subnet region will be us-east-1c          -- you can change it in the second code block
# 5. By default isntance will get 22 to 22 port for SSH
     & 80 to 80 port for HTTP                                    -- you can edit ports in the last code block
# 6. run create-instance.sh                                      --> to create an instance  
# 7. !!! Script will open a new bash session to let you 
     see variables and can use cleanup.sh separately

===================================================================================================================

#  ---- Program to create s3 bucket and copy project into the bucket ---- create-S3.sh

# 1. Have aws installed & have your aws configurations
# 2. By default s3 bucket named site-demo-451                    -- you can change variable named [ BName ]
# 3. By defailt bucket region set for us-east-1                  -- you can change cariable named [ region ]
# 4. !!!  Be sure that the project location and the script ( create-S3.sh ) are on the same lavel. 
# 5. run create-S3.sh                                            --> to create bucket and copy project into there.

===================================================================================================================

#  ---- Program for cleanup ---- cleanup.sh

# 1. Program to cleanup all data you have created OR automatically clean the data if any process gets error









