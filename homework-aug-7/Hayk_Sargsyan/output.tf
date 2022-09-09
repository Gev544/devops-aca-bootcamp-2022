output "eks-ng-asg" {
  value = aws_eks_node_group.public-noder.resources[0].autoscaling_groups[0].name
}

output "theID" {
  value = aws_instance.my-1stec2[*].id
}

output "instance_public_ip" {
  value = aws_instance.my-1stec2[*].public_ip
}
