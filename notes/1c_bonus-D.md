Ready to Suffer? —here’s the next realism bump for Lab 1C-Bonus-D:
  1) Zone apex (chewbacca-growl.com) ALIAS → ALB
  2) ALB access logs → S3 bucket (with the required bucket policy)
  3) A couple of verification commands students can run to prove it’s working

Add this as bonus_b_logging_route53_apex.tf (or append to your existing Route53/logging file).

Add variables (append to variables.tf)
variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3."
  type        = bool
  default     = true
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs."
  type        = string
  default     = "alb-access-logs"
}

Add file: bonus_b_logging_route53_apex.tf (go to Folder)

Patch reminder (students must modify the existing ALB resource)
Terraform can’t “append” nested blocks, so they must edit:
In bonus_b.tf, inside resource "aws_lb" "chewbacca_alb01" { ... } add:

  # Explanation: Chewbacca keeps flight logs—ALB access logs go to S3 for audits and incident response.
  access_logs {
    bucket  = aws_s3_bucket.chewbacca_alb_logs_bucket01[0].bucket
    prefix  = var.alb_access_logs_prefix
    enabled = var.enable_alb_access_logs
  }

Outputs (append to outputs.tf)

# Explanation: The apex URL is the front gate—humans type this when they forget subdomains.
output "chewbacca_apex_url_https" {
  value = "https://${var.domain_name}"
}

# Explanation: Log bucket name is where the footprints live—useful when hunting 5xx or WAF blocks.
output "chewbacca_alb_logs_bucket_name" {
  value = var.enable_alb_access_logs ? aws_s3_bucket.chewbacca_alb_logs_bucket01[0].bucket : null
}

Student verification (CLI) — DNS + Logs
1) Verify apex record exists
  aws route53 list-resource-record-sets \
    --hosted-zone-id <ZONE_ID> \
    --query "ResourceRecordSets[?Name=='echobase.click.']"
```
1c_terrraform lhj-keepItSimple  ? ❯ aws route53 list-resource-record-sets \
    --hosted-zone-id Z0828030PI6PCZKRD9SW \
    --query "ResourceRecordSets[?Name=='echobase.click.']"
[
    {
        "Name": "echobase.click.",
        "Type": "NS",
        "TTL": 172800,
        "ResourceRecords": [
            {
                "Value": "ns-1815.awsdns-34.co.uk."
            },
            {
                "Value": "ns-499.awsdns-62.com."
            },
            {
                "Value": "ns-867.awsdns-44.net."
            },
            {
                "Value": "ns-1510.awsdns-60.org."
            }
        ]
    },
    {
        "Name": "echobase.click.",
        "Type": "SOA",
        "TTL": 900,
        "ResourceRecords": [
            {
                "Value": "ns-1815.awsdns-34.co.uk. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"
            }
        ]
    }
]
```

2) Verify ALB logging is enabled
  aws elbv2 describe-load-balancers \
    --names echobase-alb01 \
    --query "LoadBalancers[0].LoadBalancerArn"

Then:
  aws elbv2 describe-load-balancer-attributes \
  --load-balancer-arn <ALB_ARN>

  Expected attributes include:
  access_logs.s3.enabled = true
  access_logs.s3.bucket = your bucket
  access_logs.s3.prefix = your prefix
```
{
    "Attributes": [
        {
            "Key": "access_logs.s3.enabled",
            "Value": "true"
        },
        {
            "Key": "access_logs.s3.bucket",
            "Value": "echobase-alb-logs-746669200167"
        },
        {
            "Key": "access_logs.s3.prefix",
            "Value": "alb-access-logs"
        },
<...truncated...>
    ]
}
```

3) Generate some traffic
  curl -I https://echobase.click
  curl -I https://app.echobase.click

4) Verify logs arrived in S3 (may take a few minutes)
  aws s3 ls s3://<BUCKET_NAME>/<PREFIX>/AWSLogs/<ACCOUNT_ID>/elasticloadbalancing/ --recursive | head
```
1c_terrraform lhj-keepItSimple  ? ❯ aws s3 ls s3://echobase-alb-logs-746669200167/alb-access-logs/AWSLogs/746669200167/elasticloadbalancing/ --recursive | head
2026-01-20 20:45:03       1653 alb-access-logs/AWSLogs/746669200167/elasticloadbalancing/us-east-2/2026/01/21/746669200167_elasticloadbalancing_us-east-2_app.echobase-alb01.167ccd6c60f0d88e_20260121T0145Z_3.135.123.190_kwmgqcfn.log.gz
2026-01-20 20:45:03       1307 alb-access-logs/AWSLogs/746669200167/elasticloadbalancing/us-east-2/2026/01/21/746669200167_elasticloadbalancing_us-east-2_app.echobase-alb01.167ccd6c60f0d88e_20260121T0145Z_3.137.74.104_3vn8dxmc.log.gz
2026-01-20 20:50:03        230 alb-access-logs/AWSLogs/746669200167/elasticloadbalancing/us-east-2/2026/01/21/746669200167_elasticloadbalancing_us-east-2_app.echobase-alb01.167ccd6c60f0d88e_20260121T0150Z_3.137.74.104_1jcpkd15.log.gz
```

Why this matters to YOU (career-critical point)
This is incident response fuel:
  Access logs tell you:
    client IPs
    paths
    response codes
    target behavior
    latency

Combined with WAF logs/metrics and ALB 5xx alarms, you can do real triage:
  “Is it attackers, misroutes, or downstream failure?”










