Apply complete! Resources: 85 added, 0 changed, 0 destroyed.

Outputs:

echobase_acm_cert_arn = "arn:aws:acm:us-east-2:746669200167:certificate/76b94d2b-f4ca-47e8-a99a-b269a9ce9cde"
echobase_alb_dns_name = "echobase-alb01-1915492072.us-east-2.elb.amazonaws.com"
echobase_alb_logs_bucket_name = "echobase-alb-logs-746669200167"
echobase_apex_url_https = "https://echobase.click"
echobase_app_fqdn = "app.echobase.click"
echobase_dashboard_name = "echobase-dashboard01"
echobase_ec2_instance_id = "i-0531b6e72adf43ece"
echobase_log_group_name = "/aws/ec2/echobase-rds-app"
echobase_private_ec2_instance_id_bonus = "i-0b24979a310b0b39a"
echobase_private_subnet_ids = [
  "subnet-07cf642a093faa23f",
  "subnet-0baba3cbe2b159c5b",
]
echobase_public_subnet_ids = [
  "subnet-0a2af28023cf32fc4",
  "subnet-07dc5779b6ac9faf2",
]
echobase_rds_endpoint = "echobase-rds01.cxo22gqsc8z4.us-east-2.rds.amazonaws.com"
echobase_sns_topic_arn = "arn:aws:sns:us-east-2:746669200167:echobase-db-incidents"
echobase_target_group_arn = "arn:aws:elasticloadbalancing:us-east-2:746669200167:targetgroup/echobase-tg01/a0de8c09a041e9a3"
echobase_vpc_id = "vpc-01d7e6555efc35145"
echobase_vpce_logs_id = "vpce-0aad64baee0662ca8"
echobase_vpce_s3_id = "vpce-0d63fac681949ba1d"
echobase_vpce_secrets_id = "vpce-0984f8b1e35d405c1"
echobase_vpce_ssm_id = "vpce-05d965749a7d31043"
echobase_waf_arn = "arn:aws:wafv2:us-east-2:746669200167:regional/webacl/echobase-waf01/90bff02a-a34f-4002-a80f-f49b52bc31cd"
echobase_waf_cw_log_group_name = "aws-waf-logs-echobase-webacl01"
echobase_waf_log_destination = "cloudwatch"


aws sns unsubscribe --subscription-arn "arn:aws:sns:us-east-2:746669200167:echobase-db-incidents:PendingConfirmation"