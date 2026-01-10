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