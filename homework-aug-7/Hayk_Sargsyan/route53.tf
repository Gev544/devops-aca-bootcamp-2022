data "aws_route53_zone" "zone" {
  name = "hayk-sargsyan.acadevopscourse.xyz"
}
resource "aws_route53_record" "a_record" {
  alias {
    name                   = aws_cloudfront_distribution.nlb_distrib.domain_name
    zone_id                = aws_cloudfront_distribution.nlb_distrib.hosted_zone_id
    evaluate_target_health = "false"
  }
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "hayk-sargsyan.acadevopscourse.xyz"
  type    = "A"

}

# creating record for RDS
resource "aws_route53_record" "rds_cname" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "djangoproject-db.hayk-sargsyan.acadevopscourse.xyz"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.db_inst.address]
}