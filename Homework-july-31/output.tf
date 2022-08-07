output "instance_ip_addr" {
  value = "http://${aws_cloudfront_distribution.s3_distribution.domain_name}/"
}
