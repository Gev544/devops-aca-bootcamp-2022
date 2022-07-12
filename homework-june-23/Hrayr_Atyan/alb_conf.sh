#/bin/bash

instance_id1=$(cat ids | tail -3 | head -1)
instance_id2=$(cat ids | tail -2 | head -1)
subnet1=$(cat ids | head -2 | tail -1)
subnet2=$(cat ids | head -3 | tail -1)
sg_id=$(cat ids | head -4 | tail -1)
vpc_id=$(cat ids | head -1)
target_name=default
domain=$1
certificate_ARN=$2


zone_id=$(aws route53 list-hosted-zones-by-name  \
            --dns-name $domain \
            --output text \
            --query HostedZones[0].Id | grep -o "Z\w*")


#Creating ALB
ALB_ARN=$(aws elbv2 create-load-balancer \
--name First-ALB  \
--subnets $subnet1 $subnet2 \
--security-groups $sg_id \
--query 'LoadBalancers[0].LoadBalancerArn' \
--output text) && \
echo "Created ALB"

#Getting its Domain 
ALB_DNS=$(aws elbv2 describe-load-balancers \
--load-balancer-arns $ALB_ARN \
--query 'LoadBalancers[0].DNSName' \
--output text) 

#Creating Target group
TG_ARN=$(aws elbv2 create-target-group \
--name rate-servers \
--protocol HTTPS --port 443 \
--vpc-id $vpc_id \
--query 'TargetGroups[0].TargetGroupArn' \
--output text) && \
echo "Created Target Group"

#Registering instances in Target Group
aws elbv2 register-targets --target-group-arn $TG_ARN  \
--targets Id=$instance_id1 Id=$instance_id2 && \
echo "Targets registered"

#Creating Listener for HTTP port 80
HTTP_LISTENER_ARN=$(aws elbv2 create-listener --load-balancer-arn $ALB_ARN \
--protocol HTTP --port 80  \
--default-actions Type=forward,TargetGroupArn=$TG_ARN \
--query 'Listeners[0].ListenerArn' \
--output text)

#Creating Listener for HTTPS port 443
aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTPS \
    --port 443 \
    --certificates CertificateArn=$certificate_ARN \
    --ssl-policy ELBSecurityPolicy-2016-08 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN 1>/dev/null

#Redirecting HTTP traffic to HTTPS
aws elbv2 modify-listener --listener-arn $HTTP_LISTENER_ARN --default-actions \
 '[{"Type": "redirect", 
    "RedirectConfig": {
        "Protocol": "HTTPS", 
        "Port": "443", 
        "Host": "#{host}", 
        "Query": "#{query}", 
        "Path": "/#{path}", 
        "StatusCode": "HTTP_301"}}]'

#Gettind Hosted Zone Id of ALB
ALB_ZONE_ID=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns $ALB_ARN \
    --query LoadBalancers[0].CanonicalHostedZoneId \
    --output text)

#Creating json file to update dns zone
echo    '{
                "Comment": "Domain for our web page",
                "Changes": [ {
                             "Action": "UPSERT",
                            "ResourceRecordSet": {
                                "Name": "'$domain'",
                                "Type": "A",
                                "AliasTarget":{
                                    "HostedZoneId": "'$ALB_ZONE_ID'",
                                    "DNSName": "dualstack.'$ALB_DNS'",
                                    "EvaluateTargetHealth": false
                                }
                            }
                }]
}' > dns_conf.json

#Updating the zone
aws route53 change-resource-record-sets \
    --hosted-zone-id $zone_id \
    --change-batch file://dns_conf.json 1>/dev/null && \
    echo "DNS Record is set"

#deleting that file
rm -f dns_conf.json