resource "aws_subnet" "private-us-east-1e" {
  vpc_id            = aws_vpc.virtual_anhatakan_amp.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-east-1e"

  tags = {
    "Name"                             = "private-us-east-1e"
    "kubernetes.io/cluster/im-cluster" = "owned"
    "kubernetes.io/role/internal-elb"  = 1
  }
}

resource "aws_subnet" "private-us-east-1f" {
  vpc_id            = aws_vpc.virtual_anhatakan_amp.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-east-1f"

  tags = {
    "Name"                             = "private-us-east-1f"
    "kubernetes.io/cluster/im-cluster" = "owned"
    "kubernetes.io/role/internal-elb"  = 1
  }
}

resource "aws_subnet" "public-us-east-1a" {
  vpc_id                  = aws_vpc.virtual_anhatakan_amp.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name"                             = "public-us-east-1a"
    "kubernetes.io/cluster/im-cluster" = "owned"
    "kubernetes.io/role/elb"           = 1
  }
}

resource "aws_subnet" "public-us-east-1b" {
  vpc_id                  = aws_vpc.virtual_anhatakan_amp.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    "Name"                             = "public-us-east-1b"
    "kubernetes.io/cluster/im-cluster" = "owned"
    "kubernetes.io/role/elb"           = 1
  }
}

resource "aws_subnet" "public-us-east-1c" {
  vpc_id                  = aws_vpc.virtual_anhatakan_amp.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    "Name"                             = "public-us-east-1c"
    "kubernetes.io/cluster/im-cluster" = "owned"
    "kubernetes.io/role/elb"           = 1
  }
}

resource "aws_subnet" "public-us-east-1d" {
  vpc_id                  = aws_vpc.virtual_anhatakan_amp.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1d"
  map_public_ip_on_launch = true

  tags = {
    "Name"                             = "public-us-east-1d"
    "kubernetes.io/cluster/im-cluster" = "owned"
    "kubernetes.io/role/elb"           = 1
  }
}