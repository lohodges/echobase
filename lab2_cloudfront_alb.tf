# Explanation: CloudFront is the only public doorway — echobase stands behind it with private infrastructure.
resource "aws_cloudfront_distribution" "echobase_cf01" {
  depends_on      = [aws_acm_certificate_validation.echobase_cf_acm_validation01]
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name}-cf01"

  origin {
    origin_id   = "${var.project_name}-alb-origin01"
    domain_name = aws_lb.echobase_alb01.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    # Explanation: CloudFront whispers the secret growl — the ALB only trusts this.
    custom_header {
      name  = "X-echobase-Growl"
      value = random_password.echobase_origin_header_value01.result
    }
  }

  default_cache_behavior {
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    # TODO: students choose cache policy / origin request policy for their app type
    # For APIs, typically forward all headers/cookies/querystrings.
    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies { forward = "all" }
    }
  }

  # Explanation: Attach WAF at the edge — now WAF moved to CloudFront.
  web_acl_id = aws_wafv2_web_acl.echobase_cf_waf01.arn

  # TODO: students set aliases for echobase-growl.com and app.echobase-growl.com
  aliases = [
    var.domain_name,
    "${var.app_subdomain}.${var.domain_name}"
  ]

  # TODO: students must use ACM cert in us-east-1 for CloudFront
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.echobase_cf_acm_validation01.certificate_arn
    #acm_certificate_arn      = var.cloudfront_acm_cert_arn
    #acm_certificate_arn      = local.echobase_acm_cert
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# You’ll need this variable:
# variable "cloudfront_acm_cert_arn" {
#   description = "ACM certificate ARN in us-east-1 for CloudFront (covers echobase-growl.com and app.echobase-growl.com)."
#   type        = string
#   default     = "arn:aws:acm:us-east-1:746669200167:certificate/348e20c8-8fdb-4c5d-a4ea-7dcf37b00db2"
# }
