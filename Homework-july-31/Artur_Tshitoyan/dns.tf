variable domain_name {}
 
 resource "aws_acm_certificate" "cert" {
   provider                  = aws.us-east-1
   domain_name               = var.domain_name
   validation_method         = "DNS"
   
   tags = {
     Environment = var.env_prefix
  }

   lifecycle {
     create_before_destroy = true
  }
 }

 resource "aws_acm_certificate_validation" "certvalidation" {
   provider                = aws.us-east-1
   certificate_arn         = aws_acm_certificate.cert.arn
   validation_record_fqdns = [for r in aws_route53_record.certvalidation : r.fqdn]
 }

 resource "aws_route53_record" "certvalidation" {
   for_each = {
     for d in aws_acm_certificate.cert.domain_validation_options : d.domain_name => {
       name   = d.resource_record_name
       record = d.resource_record_value
       type   = d.resource_record_type
     }
   }

   allow_overwrite = true
   name            = each.value.name
   records         = [each.value.record]
   ttl             = 60
   type            = each.value.type
   zone_id         = data.aws_route53_zone.domain.zone_id
 }

data "aws_route53_zone" "domain" {
  name = var.domain_name
}

resource "aws_route53_record" "websiteurl" {
  name    = var.domain_name
  zone_id = data.aws_route53_zone.domain.zone_id
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

