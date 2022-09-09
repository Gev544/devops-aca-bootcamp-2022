resource "aws_iam_role" "nor_role" {
  name = "eks_cluster_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
  POLICY
}

resource "aws_iam_role_policy_attachment" "nor-role-AmazonEksClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.nor_role.name
}

resource "aws_eks_cluster" "im-cluster" {
  name     = "im-cluster"
  role_arn = aws_iam_role.nor_role.arn

  vpc_config {
    # security_group_ids = [aws_security_group.my_1stsg.id]
    subnet_ids = [
      aws_subnet.public-us-east-1d.id,
      aws_subnet.public-us-east-1b.id,
      aws_subnet.public-us-east-1c.id
    ]
  }
  depends_on = [
    aws_iam_role_policy_attachment.nor-role-AmazonEksClusterPolicy
  ]
}

