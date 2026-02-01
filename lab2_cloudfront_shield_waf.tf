# Explanation: The shield generator moves to the edge — CloudFront WAF blocks nonsense before it hits your VPC.
resource "aws_wafv2_web_acl" "echobase_cf_waf01" {
  provider = aws.acm_useast1
  name     = "${var.project_name}-cf-waf01"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-cf-waf01"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-cf-waf-common"
      sampled_requests_enabled   = true
    }
  }

  # added by Lonnie Hodges on 2026-02-01
  # Block all traffic except from allowed IPs
  rule {
    name     = "AllowOnlyMyIP"
    priority = 0

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.echobase_allowed_ips01.arn
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-allow-only-my-ip"
      sampled_requests_enabled   = true
    }
  }
  # ^^^ added by Lonnie Hodges on 2026-02-01

  tags = {
    Name = "${var.project_name}-cf-waf01"
  }
}

# IP Set containing allowed IPs (your IP address)
resource "aws_wafv2_ip_set" "echobase_allowed_ips01" {
  provider           = aws.acm_useast1
  name               = "${var.project_name}-allowed-ips01"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"

  # Replace with your IP address (use /32 for a single IP)
  addresses = var.allowed_ip_cidrs

  tags = {
    Name = "${var.project_name}-allowed-ips01"
  }
}