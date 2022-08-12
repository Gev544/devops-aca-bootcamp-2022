resource "aws_s3_bucket" "s3b" {
  bucket = "s3b09-08-22"

  tags = {
    Name = "My 1stterrbucket"
  }
}

resource "aws_s3_bucket_acl" "s3b_acl" {
  bucket = aws_s3_bucket.s3b.id
  acl    = "public-read"
}

#aws_s3_bucket_object ------- chdnel , Worning e talis
resource "aws_s3_object" "s3index" {
  bucket       = aws_s3_bucket.s3b.id
  key          = "index.html"
  acl          = "public-read"
  source       = "./files/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "s3error" {
  bucket       = aws_s3_bucket.s3b.id
  key          = "error.html"
  acl          = "public-read"
  source       = "./files/error.html"
  content_type = "text/html"
}


# resource "aws_s3_bucket_website_configuration" "my_sw" {
#   bucket = aws_s3_bucket.s3b.id
#   index_document {
#     suffix = "index.html"
#   }
#   error_document {
#     key = "error.html"
#   }
# }

