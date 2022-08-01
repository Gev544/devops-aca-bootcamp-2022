# Project Title

aws-ec2-with-terraform

## Description

Creating an ec2 instance with its all necessary resources (VPC, Subnets, Security Groups, Internet Gateway, Route Tables, etc.) in AWS with Terraform.

## Getting Started

### Executing program

* initialize terraform in repo
```
terraform init
```
![init](https://github.com/mkrtchyan-t/aws-ec2-with-terraform/blob/master/img/init.png)

* apply configurations to launch the instance
```
terraform apply
```
![apply](https://github.com/mkrtchyan-t/aws-ec2-with-terraform/blob/master/img/apply.png)

### Clean up the environment

* to destroy all Terraform environments, ensure that you're in the repo directory that you used to create the EC2 instance and run 
```
terraform destroy
```
![apply](https://github.com/mkrtchyan-t/aws-ec2-with-terraform/blob/master/img/destroy.png)

## Usefull links

Documentations, examples, etc.
* [input variables](https://www.terraform.io/language/values/variables)
* [output vlaues](https://www.terraform.io/language/values/outputs)
* [aws vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)
* [aws subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet)
* [aws security group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)
* [argument references for creating an instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
* [ingress vs egress in security groups](https://aviatrix.com/learn-center/cloud-security/egress-and-ingress/)
* [global understanding about terraform project structure](https://www.digitalocean.com/community/tutorials/how-to-structure-a-terraform-project#conclusion)