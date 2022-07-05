#  ---- Program to create instance ---- create-instance.sh

# 1. Have aws installed & have your aws configurations
# 2. By default instace will be in 10.0.0.0/24 ip range          -- you can change it in the first code block
# 3. By default instace will get 10.0.0.0/24 subnet range        -- you can change it in the second code block
# 4. By default public subnet region will be us-east-1c          -- you can change it in the second code block
# 5. By default isntance will get 22 to 22 port for SSH
#    & 80 to 80 port for HTTP                                    -- you can edit ports in the last code block
# 6. run create-instance.sh                                      --> to create an instance  
# 7. !!! Script will open a new bash session to let you 
#    see variables and can use cleanup.sh separately
# 8. By default s3 bucket named site-demo-1                      -- you can change variable named [ BName ]
# 9. By defailt bucket region set for us-east-1                  -- you can change cariable named [ region ]
# 10. Bukcket mounts in the /myS3Bucket directory
===================================================================================================================

#  ---- Program for cleanup ---- cleanup.sh

# 1. Program to cleanup all data you have created OR automatically clean the data if any process gets error

===================================================================================================================

#  ---- Program for creating nginx server and configure ---- nginx.sh

Program is
   # 1. Executing on the remote host
   # 2. Installing nginx
   # 3. Making configures
   # 4. Creating systemd service that parses the rate for usd/amd (ameriabank)

# 5. service restarts too if instance does
    







