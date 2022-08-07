#create vpc
resource "aws_vpc" "hw_aca_vpc" {
  cidr_block = "${var.cidr-block-vpc}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name= "hw_aca_vpc"
  }
}
 
#create public subnet
resource "aws_subnet" "hw_aca_subnet" {
  vpc_id     = aws_vpc.hw_aca_vpc.id
  cidr_block = "${var.cidr-block-pb-subnet}"

  tags = {
    Name = "hw_aca_pb_subnet"
  }
}

#create gateway
resource "aws_internet_gateway" "hw_aca_gw" {
  vpc_id = aws_vpc.hw_aca_vpc.id

  tags = {
    Name = "hw_aca_gw"
  }
}

#create route table
resource "aws_route_table" "hw_aca_route_table" {
  vpc_id = aws_vpc.hw_aca_vpc.id

  route {
    cidr_block = "${var.cidr-block-route_tb}"
    gateway_id = aws_internet_gateway.hw_aca_gw.id
  }

  tags = {
    Name = "hw_aca_route_table"
  }
}

#route table association with public subnet
resource "aws_route_table_association" "hw_aca_association" {
  subnet_id      = aws_subnet.hw_aca_subnet.id
  route_table_id = aws_route_table.hw_aca_route_table.id
} 

#create security group
resource "aws_security_group" "hw_aca_security_group" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.hw_aca_vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.cidr-block-route_tb]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [var.cidr-block-route_tb]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.cidr-block-route_tb]
  }

  tags = {
    Name = "hw_aca_security_group"
  }
}

# create ssh key
resource "tls_private_key" "hw_create_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "hw_aca_key" {
  key_name   = "hw_aca_key"
  public_key = tls_private_key.hw_create_key.public_key_openssh
  
 tags = {
    Name = "hw_aca_key"
  }

 # create a "terraform-key.pem" to your computer!!
  provisioner "local-exec" {
    command = "echo '${tls_private_key.hw_create_key.private_key_pem}' > ./terraform-key.pem"
  }
}

#create ec2 instance
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  key_name               = aws_key_pair.hw_aca_key.id
  subnet_id              = aws_subnet.hw_aca_subnet.id
  iam_instance_profile   = "${aws_iam_instance_profile.ec2_profile.name}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.hw_aca_security_group.id]

  tags = {
    Name = "hw_aca_terraform"
  }
}

#create s3 bucket
resource "aws_s3_bucket" "hw_aca_bucket_july_31" {
  bucket = "hw-aca-bucket-july-31"


website {
    index_document = "index.html"
    error_document = "index.html"

    routing_rules = <<EOF
[{
    "Condition": {
        "KeyPrefixEquals": "docs/"
    },
    "Redirect": {
        "ReplaceKeyPrefixWith": "documents/"
    }
}]
EOF
  }

  tags = {
    Name        = "hw-aca-bucket-july-31"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "hw_aca_bucket_acl" {
  bucket = aws_s3_bucket.hw_aca_bucket_july_31.id
  acl    = "private"
}


#bucket policy
resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.hw_aca_bucket_july_31.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}


resource "aws_cloudfront_origin_access_identity" "example" {
  comment = "Some comment"
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    actions = [
      "s3:*",
    ]

    resources = ["${aws_s3_bucket.hw_aca_bucket_july_31.arn}/*"]
      
      principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.example.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.hw_aca_bucket_july_31.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

#create iam policy
resource "aws_iam_role_policy" "hw_ec2_policy" {
  name = "hw_ec2_policy"
  role = aws_iam_role.hw_iam_ec2_role.id

  policy = "${file("ec2-policy.json")}"
}

#attach it to role
resource "aws_iam_role" "hw_iam_ec2_role" {
  name = "hw_iam_ec2_role"

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
}

#attach it to ec2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.hw_iam_ec2_role.name
}


#cloudfront
locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.hw_aca_bucket_july_31.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.example.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.hw_aca_bucket_july_31.bucket_regional_domain_name
    prefix = "logs/"
  }

 custom_error_response {
        error_caching_min_ttl = 86400
        error_code = 404
        response_code = 200
        response_page_path = "/index.html"
 }

  custom_error_response {
        error_caching_min_ttl = 86400
        error_code = 403
        response_code = 200
        response_page_path = "/index.html"
 }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


