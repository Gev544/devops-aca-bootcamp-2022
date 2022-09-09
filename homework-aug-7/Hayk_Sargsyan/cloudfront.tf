
resource "aws_cloudfront_distribution" "nlb_distrib" {
  aliases = ["hayk-sargsyan.acadevopscourse.xyz"]
  origin {
    domain_name = aws_lb.nlb.dns_name
    origin_id   = aws_lb.nlb.dns_name
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  enabled = true
  comment = "My nlb"


  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_lb.nlb.dns_name #aws_s3_bucket.s3b.bucket
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      headers      = []
      query_string = true
      cookies {
        forward = "all"
      }
    }
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
    compress    = "true"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  retain_on_delete = "false"

  viewer_certificate {
    acm_certificate_arn            = "arn:aws:acm:us-east-1:804969638232:certificate/a0eaccf3-70e2-4322-b0a7-c96b11d0ac03"
    cloudfront_default_certificate = "false"
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }

  #   custom_error_response {
  #     error_code = 403
  #     response_page_path = "/error.html"
  #     response_code = 200
  #   }
  #   custom_error_response {
  #     error_code = 404
  #     response_page_path = "/error.html"
  #     response_code = 200
  #   }

}