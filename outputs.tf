# Explanation: Outputs are your mission report—what got built and where to find it.
output "echobase_vpc_id" {
  value = aws_vpc.echobase_vpc01.id
}

output "echobase_public_subnet_ids" {
  value = aws_subnet.echobase_public_subnets[*].id
}

output "echobase_private_subnet_ids" {
  value = aws_subnet.echobase_private_subnets[*].id
}

output "echobase_ec2_instance_id" {
  value = aws_instance.echobase_ec201.id
}

output "echobase_rds_endpoint" {
  value = aws_db_instance.echobase_rds01.address
}

output "echobase_sns_topic_arn" {
  value = aws_sns_topic.echobase_sns_topic01.arn
}

output "echobase_log_group_name" {
  value = aws_cloudwatch_log_group.echobase_log_group01.name
}

# added by Lonnie Hodges
#Bonus-A outputs (append to outputs.tf)
# Explanation: These outputs prove echobase built private hyperspace lanes (endpoints) instead of public chaos.
# output "echobase_vpce_ssm_id" {
#   value = aws_vpc_endpoint.echobase_vpce_ssm01.id
# }

# output "echobase_vpce_logs_id" {
#   value = aws_vpc_endpoint.echobase_vpce_logs01.id
# }

# output "echobase_vpce_secrets_id" {
#   value = aws_vpc_endpoint.echobase_vpce_secrets01.id
# }

# output "echobase_vpce_s3_id" {
#   value = aws_vpc_endpoint.echobase_vpce_s3_gw01.id
# }

output "echobase_private_ec2_instance_id_bonus" {
  value = aws_instance.echobase_ec201_private_bonus.id
}

# # added by Lonnie Hodges
# #Bonus-B outputs (append to outputs.tf)
# # Explanation: Outputs are the mission coordinates — where to point your browser and your blasters.
# output "echobase_alb_dns_name" {
#   value = aws_lb.echobase_alb01.dns_name
# }

# output "echobase_app_fqdn" {
#   value = "${var.app_subdomain}.${var.domain_name}"
# }

# output "echobase_target_group_arn" {
#   value = aws_lb_target_group.echobase_tg01.arn
# }

# output "echobase_acm_cert_arn" {
#   value = aws_acm_certificate.echobase_acm_cert01.arn
# }

# output "echobase_waf_arn" {
#   value = var.enable_waf ? aws_wafv2_web_acl.echobase_waf01[0].arn : null
# }

# output "echobase_dashboard_name" {
#   value = aws_cloudwatch_dashboard.echobase_dashboard01.dashboard_name
# }

