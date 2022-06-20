#!/bin/bash

delete_for_all_proccess() {

if  [[ -z $vpc ]]
then
        exit
fi

if  [[ -z $subnet1 ]]
then
        aws ec2 delete-vpc --vpc-id $vpc

elif  [[ -z $igw ]]
then
        aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc
        aws ec2 delete-subnet --subnet-id $subnet1
        aws ec2 delete-vpc --vpc-id $vpc

elif  [[ -z $gateway_from_vpc ]]
then
        aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc
        aws ec2 delete-internet-gateway --internet-gateway-id $igw
        aws ec2 delete-subnet --subnet-id $subnet1
        aws ec2 delete-vpc --vpc-id $vpc

elif  [[ -z $routeTable_for_vps ]]
then
        aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc
        aws ec2 delete-internet-gateway --internet-gateway-id $igw
        aws ec2 delete-subnet --subnet-id $subnet1
        aws ec2 delete-vpc --vpc-id $vpc

elif  [[ -z $route_for_all_trafick ]]
then
        aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc
        aws ec2 delete-route-table --route-table-id $routeTable_for_vpc
        aws ec2 delete-internet-gateway --internet-gateway-id $igw
        aws ec2 delete-subnet --subnet-id $subnet1
        aws ec2 delete-vpc --vpc-id $vpc

elif  [[ -z $SG ]]
then
        aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc
        aws ec2 delete-subnet --subnet-id $subnet1
        aws ec2 delete-internet-gateway --internet-gateway-id $igw
        aws ec2 delete-route-table --route-table-id $routeTable_for_vpc
        aws ec2 delete-vpc --vpc-id $vpc

elif  [[ -z $run_instance ]]
then
        aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc
        aws ec2 delete-subnet --subnet-id $subnet1
        aws ec2 delete-vpc --vpc-id $vpc
        aws ec2 delete-internet-gateway --internet-gateway-id $igw
        aws ec2 delete-route-table --route-table-id $routeTable_for_vpc
        aws ec2 delete-security-group --group-id $SG
fi

}

