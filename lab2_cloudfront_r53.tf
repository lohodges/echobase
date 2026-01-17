# Explanation: DNS now points to CloudFront — nobody should ever see the ALB again.
resource "aws_route53_record" "echobase_apex_to_cf01" {
  zone_id = local.echobase_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.echobase_cf01.domain_name
    zone_id                = aws_cloudfront_distribution.echobase_cf01.hosted_zone_id
    evaluate_target_health = false
  }
}

# Explanation: app.passportog.com also points to CloudFront — same doorway, different sign.
resource "aws_route53_record" "echobase_app_to_cf01" {
  zone_id = local.echobase_zone_id
  name    = "${var.app_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.echobase_cf01.domain_name
    zone_id                = aws_cloudfront_distribution.echobase_cf01.hosted_zone_id
    evaluate_target_health = false
  }
}
