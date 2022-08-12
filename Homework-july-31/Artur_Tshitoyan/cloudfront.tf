locals {
  s3_origin_id = "myvpc-s3.s3.amazonaws.com"
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "oai for my cloudfront"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.b.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.b.bucket_regional_domain_name
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "My Cloudfront"
  default_root_object = "index.html"

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

    viewer_protocol_policy = "redirect-to-https"
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
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
     geo_restriction {
       restriction_type = "none"
     }
   }

  tags = {
    Environment = "${var.env_prefix}"
  }

  aliases = ["at.mouradyan.xyz"]

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
    cloudfront_default_certificate = true
  }

  custom_error_response {
    error_code = 403
    response_page_path = "/index.html"
    response_code = 200
  }
  custom_error_response {
    error_code = 404
    response_page_path = "/index.html"
    response_code = 200
  }
}

output "domain" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}