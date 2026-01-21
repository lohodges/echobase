Key update since “the old days”: AWS WAF logging can go directly to CloudWatch Logs, S3, or Kinesis Data Firehose, 
and you can associate one destination per Web ACL. Also, the destination name must start with aws-waf-logs-. 


Terraform supports this with aws_wafv2_web_acl_logging_configuration. 
Terraform Registry

Below is Lab 1C-Bonus-E (continued): WAF logging in Terraform (with toggles), plus verification commands.

1) Add variables (append to variables.tf)
variable "waf_log_destination" {
  description = "Choose ONE destination per WebACL: cloudwatch | s3 | firehose"
  type        = string
  default     = "cloudwatch"
}

variable "waf_log_retention_days" {
  description = "Retention for WAF CloudWatch log group."
  type        = number
  default     = 14
}

variable "enable_waf_sampled_requests_only" {
  description = "If true, students can optionally filter/redact fields later. (Placeholder toggle.)"
  type        = bool
  default     = false
}


2) Add file: bonus_b_waf_logging.tf (Look in Folder)

This provides three skeleton options (CloudWatch / S3 / Firehose). Students choose one via var.waf_log_destination.


3) Outputs (append to outputs.tf)
# Explanation: Coordinates for the WAF log destination—Chewbacca wants to know where the footprints landed.
output "chewbacca_waf_log_destination" {
  value = var.waf_log_destination
}

output "chewbacca_waf_cw_log_group_name" {
  value = var.waf_log_destination == "cloudwatch" ? aws_cloudwatch_log_group.chewbacca_waf_log_group01[0].name : null
}

output "chewbacca_waf_logs_s3_bucket" {
  value = var.waf_log_destination == "s3" ? aws_s3_bucket.chewbacca_waf_logs_bucket01[0].bucket : null
}

output "chewbacca_waf_firehose_name" {
  value = var.waf_log_destination == "firehose" ? aws_kinesis_firehose_delivery_stream.chewbacca_waf_firehose01[0].name : null
}


4) Student verification (CLI)
A) Confirm WAF logging is enabled (authoritative)
  aws wafv2 get-logging-configuration \
    --resource-arn <WEB_ACL_ARN>

Expected: LogDestinationConfigs contains exactly one destination.
```
1c_terrraform lhj-keepItSimple  ? ❯ aws wafv2 get-logging-configuration \
    --resource-arn arn:aws:wafv2:us-east-2:746669200167:regional/webacl/echobase-waf01/6d30d955-4af1-4b56-a685-f48adb41eb45
{
    "LoggingConfiguration": {
        "ResourceArn": "arn:aws:wafv2:us-east-2:746669200167:regional/webacl/echobase-waf01/6d30d955-4af1-4b56-a685-f48adb41eb45",
        "LogDestinationConfigs": [
            "arn:aws:logs:us-east-2:746669200167:log-group:aws-waf-logs-echobase-webacl01"
        ],
        "ManagedByFirewallManager": false,
        "LogType": "WAF_LOGS",
        "LogScope": "CUSTOMER"
    }
}
```

B) Generate traffic (hits + blocks)
  curl -I https://echobase.click/
  curl -I https://app.echobase.click/

C1) If CloudWatch Logs destination
  aws logs describe-log-streams \
  --log-group-name aws-waf-logs-<project>-webacl01 \
  --order-by LastEventTime --descending
```
1c_terrraform lhj-keepItSimple  ? ❯ aws logs describe-log-streams \
  --log-group-name aws-waf-logs-echobase-webacl01 \
  --order-by LastEventTime --descending
{
    "logStreams": [
        {
            "logStreamName": "us-east-2_echobase-waf01_0",
            "creationTime": 1769016326296,
            "firstEventTimestamp": 1769016315624,
            "lastEventTimestamp": 1769016315639,
            "lastIngestionTime": 1769016326339,
            "uploadSequenceToken": "49039859659134469437850777648971784080718550675058838869",
            "arn": "arn:aws:logs:us-east-2:746669200167:log-group:aws-waf-logs-echobase-webacl01:log-stream:us-east-2_echobase-waf01_0",
            "storedBytes": 0
        }
    ]
}
```

Then pull recent events:
  aws logs filter-log-events \
  --log-group-name aws-waf-logs-<project>-webacl01 \
  --max-items 20
```
1c_terrraform lhj-keepItSimple  ? ❯ aws logs filter-log-events   --log-group-name aws-waf-logs-echobase-webacl01   --max-items 20
{
    "events": [
        {
            "logStreamName": "us-east-2_echobase-waf01_0",
            "timestamp": 1769016315624,
            "message": "{\"timestamp\":1769016315624,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:us-east-2:746669200167:regional/webacl/echobase-waf01/6d30d955-4af1-4b56-a685-f48adb41eb45\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"746669200167-app/echobase-alb01/bbd9644dc8c8528e\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"154.28.229.142\",\"country\":\"US\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.echobase.click\"},{\"name\":\"accept\",\"value\":\"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7\"},{\"name\":\"Connection\",\"value\":\"keep-alive\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36\"},{\"name\":\"sec-ch-ua\",\"value\":\"Google Chrome\\\";v=\\\"111\\\", \\\"Not(A:Brand\\\";v=\\\"8\\\", \\\"Chromium\\\";v=\\\"111\"},{\"name\":\"accept-encoding\",\"value\":\"gzip, deflate, br\"},{\"name\":\"accept-language\",\"value\":\"en-US,en;q=0.9\"},{\"name\":\"sec-fetch-mode\",\"value\":\"navigate\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"GET\",\"requestId\":\"1-69710bfb-390932ff414c473104ed6f18\",\"fragment\":\"\",\"scheme\":\"https\",\"host\":\"app.echobase.click\"},\"ja3Fingerprint\":\"25b8751f47d0201ac34951cb90bff78e\",\"ja4Fingerprint\":\"t13d3613h1_bcee18a5b459_ecd0401ec68b\"}",
            "ingestionTime": 1769016330712,
            "eventId": "39450382106774251370514958137394560376606633318715949056"
        },
        {
            "logStreamName": "us-east-2_echobase-waf01_0",
            "timestamp": 1769016315639,
            "message": "{\"timestamp\":1769016315639,\"formatVersion\":1,\"webaclId\":\"arn:aws:wafv2:us-east-2:746669200167:regional/webacl/echobase-waf01/6d30d955-4af1-4b56-a685-f48adb41eb45\",\"terminatingRuleId\":\"Default_Action\",\"terminatingRuleType\":\"REGULAR\",\"action\":\"ALLOW\",\"terminatingRuleMatchDetails\":[],\"httpSourceName\":\"ALB\",\"httpSourceId\":\"746669200167-app/echobase-alb01/bbd9644dc8c8528e\",\"ruleGroupList\":[{\"ruleGroupId\":\"AWS#AWSManagedRulesCommonRuleSet\",\"terminatingRule\":null,\"nonTerminatingMatchingRules\":[],\"excludedRules\":null,\"customerConfig\":null}],\"rateBasedRuleList\":[],\"nonTerminatingMatchingRules\":[],\"requestHeadersInserted\":null,\"responseCodeSent\":null,\"httpRequest\":{\"clientIp\":\"103.4.250.81\",\"country\":\"US\",\"headers\":[{\"name\":\"Host\",\"value\":\"app.echobase.click\"},{\"name\":\"accept\",\"value\":\"text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7\"},{\"name\":\"Connection\",\"value\":\"keep-alive\"},{\"name\":\"User-Agent\",\"value\":\"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36\"},{\"name\":\"sec-ch-ua\",\"value\":\"Google Chrome\\\";v=\\\"111\\\", \\\"Not(A:Brand\\\";v=\\\"8\\\", \\\"Chromium\\\";v=\\\"111\"},{\"name\":\"accept-encoding\",\"value\":\"gzip, deflate, br\"},{\"name\":\"accept-language\",\"value\":\"en-US,en;q=0.9\"},{\"name\":\"sec-fetch-mode\",\"value\":\"navigate\"}],\"uri\":\"/\",\"args\":\"\",\"httpVersion\":\"HTTP/1.1\",\"httpMethod\":\"GET\",\"requestId\":\"1-69710bfb-78f858f0376a8dd9062155fe\",\"fragment\":\"\",\"scheme\":\"https\",\"host\":\"app.echobase.click\"},\"ja3Fingerprint\":\"25b8751f47d0201ac34951cb90bff78e\",\"ja4Fingerprint\":\"t13d3613h1_bcee18a5b459_ecd0401ec68b\"}",
            "ingestionTime": 1769016326339,
            "eventId": "39450382107108762548492917479231103106496540557972537344"
        },
```

C2) If S3 destination
  aws s3 ls s3://aws-waf-logs-<project>-<account_id>/ --recursive | head
aws s3 ls s3://aws-waf-logs-echobase-746669200167/ --recursive | head
```
1c_terrraform lhj-keepItSimple  ? ❯ aws s3 ls s3://aws-waf-logs-echobase-746669200167/ --recursive | head
2026-01-21 12:42:26          0 AWSLogs/746669200167/
2026-01-21 12:47:50       1224 AWSLogs/746669200167/WAFLogs/us-east-2/echobase-waf01/2026/01/21/17/40/746669200167_waflogs_us-east-2_echobase-waf01_20260121T1740Z_10d05588.log.gz
2026-01-21 12:47:50        810 AWSLogs/746669200167/WAFLogs/us-east-2/echobase-waf01/2026/01/21/17/45/746669200167_waflogs_us-east-2_echobase-waf01_20260121T1745Z_74891f28.log.gz
```

C3) If Firehose destination
  aws firehose describe-delivery-stream \
  --delivery-stream-name aws-waf-logs-<project>-firehose01 \
  --query "DeliveryStreamDescription.DeliveryStreamStatus"
```
1c_terrraform lhj-keepItSimple  ? ❯ aws firehose describe-delivery-stream \
  --delivery-stream-name aws-waf-logs-echobase-firehose01 \
  --query "DeliveryStreamDescription.DeliveryStreamStatus"
"ACTIVE"
```

And confirm objects land:
  aws s3 ls s3://<firehose_dest_bucket>/waf-logs/ --recursive | head
```
1c_terrraform lhj-keepItSimple  ? ❯ aws s3 ls s3://echobase-waf-firehose-dest-746669200167 --recursive | head
2026-01-21 13:05:43      14777 waf-logs/2026/01/21/18/aws-waf-logs-echobase-firehose01-1-2026-01-21-18-00-42-a74136fe-bdfa-4fee-bccf-f5ec568475d9
```
  

5) Why this makes incident response “real”
Now you can answer questions like:
  “Are 5xx caused by attackers or backend failure?”
  “Do we see WAF blocks spike before ALB 5xx?”
  “What paths / IPs are hammering the app?”
  “Is it one client, one ASN, one country, or broad?”
  “Did WAF mitigate, or are we failing downstream?”

This is precisely why WAF logging destinations include CloudWatch Logs (fast search) and S3/Firehose (archive/SIEM pipeline)












