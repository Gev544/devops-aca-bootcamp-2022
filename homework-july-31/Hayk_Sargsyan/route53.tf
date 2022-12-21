data "aws_route53_zone" "zone" {
  name = "hayk-sargsyan.acadevopscourse.xyz"
}
resource "aws_route53_record" "a_record" {
  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = "false"
  }
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "hayk-sargsyan.acadevopscourse.xyz"
  type    = "A"

}
