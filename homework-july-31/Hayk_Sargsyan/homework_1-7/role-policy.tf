#Create a Policy
data "aws_iam_policy" "policy" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

#Create a Role
resource "aws_iam_role" "role" {
  name = "1st-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

#Attach a Role to Policy
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.role.id
  policy_arn = data.aws_iam_policy.policy.arn
}

#Attach Role to Instance Profile
resource "aws_iam_instance_profile" "my-1stprofile" {
  name = "my-1stprofile"
  role = aws_iam_role.role.id
}