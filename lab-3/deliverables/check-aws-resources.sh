#!/usr/bin/env bash
#
# Checks for any active AWS resources from the lab-3 Terraform project.
# Covers tokyo/ (shinjuku), saopaolo/ (liberdade), and interlink/.
#
set -euo pipefail

REGIONS=("ap-northeast-1" "sa-east-1")
GLOBAL_REGION="us-east-1"
HOSTED_ZONE_ID="Z0828030PI6PCZKRD9SW"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

found_resources=0

check() {
  local label="$1"
  local count="$2"
  if [[ "$count" -gt 0 ]]; then
    echo -e "  ${RED}FOUND${NC}  $label ($count)"
    found_resources=$((found_resources + count))
  else
    echo -e "  ${GREEN}clear${NC}  $label"
  fi
}

echo -e "${BOLD}=== Lab-3 AWS Resource Audit ===${NC}"
echo ""

for region in "${REGIONS[@]}"; do
  echo -e "${BOLD}--- Region: $region ---${NC}"

  # VPCs (non-default)
  count=$(aws ec2 describe-vpcs --region "$region" \
    --filters "Name=isDefault,Values=false" \
    --query 'length(Vpcs)' --output text 2>/dev/null)
  check "Custom VPCs" "$count"

  # Internet Gateways (only those attached to non-default VPCs, or detached)
  count=$(aws ec2 describe-internet-gateways --region "$region" \
    --query 'length(InternetGateways[?length(Attachments)==`0` || Attachments[?VpcId!=`null`]])' \
    --output text 2>/dev/null)
  # Filter to only project IGWs by tag
  count=$(aws ec2 describe-internet-gateways --region "$region" \
    --filters "Name=tag-key,Values=Name" \
    --query 'length(InternetGateways[?Tags[?Key==`Name` && (contains(Value,`shinjuku`) || contains(Value,`liberdade`))]])' \
    --output text 2>/dev/null)
  check "Internet Gateways (project-tagged)" "$count"

  # NAT Gateways
  count=$(aws ec2 describe-nat-gateways --region "$region" \
    --filter "Name=state,Values=available,pending" \
    --query 'length(NatGateways)' --output text 2>/dev/null)
  check "NAT Gateways" "$count"

  # Elastic IPs
  count=$(aws ec2 describe-addresses --region "$region" \
    --query 'length(Addresses)' --output text 2>/dev/null)
  check "Elastic IPs" "$count"

  # EC2 Instances (non-terminated)
  count=$(aws ec2 describe-instances --region "$region" \
    --filters "Name=instance-state-name,Values=running,stopped,pending,stopping" \
    --query 'length(Reservations[].Instances[])' --output text 2>/dev/null)
  check "EC2 Instances" "$count"

  # RDS Instances
  count=$(aws rds describe-db-instances --region "$region" \
    --query 'length(DBInstances)' --output text 2>/dev/null)
  check "RDS Instances" "$count"

  # RDS Subnet Groups (non-default)
  count=$(aws rds describe-db-subnet-groups --region "$region" \
    --query 'length(DBSubnetGroups[?DBSubnetGroupName!=`default`])' --output text 2>/dev/null)
  check "RDS Subnet Groups (non-default)" "$count"

  # ALBs / Load Balancers
  count=$(aws elbv2 describe-load-balancers --region "$region" \
    --query 'length(LoadBalancers)' --output text 2>/dev/null)
  check "Load Balancers" "$count"

  # Target Groups
  count=$(aws elbv2 describe-target-groups --region "$region" \
    --query 'length(TargetGroups)' --output text 2>/dev/null)
  check "Target Groups" "$count"

  # Transit Gateways
  count=$(aws ec2 describe-transit-gateways --region "$region" \
    --query 'length(TransitGateways[?State!=`deleted`])' --output text 2>/dev/null)
  check "Transit Gateways" "$count"

  # TGW Peering Attachments
  count=$(aws ec2 describe-transit-gateway-peering-attachments --region "$region" \
    --query 'length(TransitGatewayPeeringAttachments[?State!=`deleted`])' --output text 2>/dev/null)
  check "TGW Peering Attachments" "$count"

  # TGW VPC Attachments
  count=$(aws ec2 describe-transit-gateway-vpc-attachments --region "$region" \
    --query 'length(TransitGatewayVpcAttachments[?State!=`deleted`])' --output text 2>/dev/null)
  check "TGW VPC Attachments" "$count"

  # VPC Endpoints (non-default gateway endpoints are free, but interface endpoints cost money)
  count=$(aws ec2 describe-vpc-endpoints --region "$region" \
    --filters "Name=vpc-endpoint-state,Values=available,pending" \
    --query 'length(VpcEndpoints)' --output text 2>/dev/null)
  check "VPC Endpoints" "$count"

  # Security Groups (project-tagged only)
  count=$(aws ec2 describe-security-groups --region "$region" \
    --filters "Name=tag-key,Values=Name" \
    --query 'length(SecurityGroups[?Tags[?Key==`Name` && (contains(Value,`shinjuku`) || contains(Value,`liberdade`))]])' \
    --output text 2>/dev/null)
  check "Security Groups (project-tagged)" "$count"

  # WAF Web ACLs (Regional)
  count=$(aws wafv2 list-web-acls --scope REGIONAL --region "$region" \
    --query 'length(WebACLs)' --output text 2>/dev/null)
  check "WAF Web ACLs (Regional)" "$count"

  # Kinesis Firehose Delivery Streams
  count=$(aws firehose list-delivery-streams --region "$region" \
    --query 'length(DeliveryStreamNames)' --output text 2>/dev/null)
  check "Kinesis Firehose Streams" "$count"

  # CloudWatch Log Groups (project-related)
  count=$(aws logs describe-log-groups --region "$region" \
    --query 'length(logGroups[?contains(logGroupName,`shinjuku`) || contains(logGroupName,`liberdade`)])' \
    --output text 2>/dev/null)
  check "CloudWatch Log Groups (project)" "$count"

  # CloudWatch Dashboards
  count=$(aws cloudwatch list-dashboards --region "$region" \
    --query 'length(DashboardEntries)' --output text 2>/dev/null)
  check "CloudWatch Dashboards" "$count"

  # CloudWatch Alarms
  count=$(aws cloudwatch describe-alarms --region "$region" \
    --query 'length(MetricAlarms)' --output text 2>/dev/null)
  check "CloudWatch Alarms" "$count"

  # SNS Topics
  count=$(aws sns list-topics --region "$region" \
    --query 'length(Topics)' --output text 2>/dev/null)
  check "SNS Topics" "$count"

  # Flow Logs
  count=$(aws ec2 describe-flow-logs --region "$region" \
    --query 'length(FlowLogs)' --output text 2>/dev/null)
  check "Flow Logs" "$count"

  # ACM Certificates
  count=$(aws acm list-certificates --region "$region" \
    --query 'length(CertificateSummaryList)' --output text 2>/dev/null)
  check "ACM Certificates" "$count"

  # Secrets Manager Secrets
  count=$(aws secretsmanager list-secrets --region "$region" \
    --query 'length(SecretList)' --output text 2>/dev/null)
  check "Secrets Manager Secrets" "$count"

  # SSM Parameters (project-related)
  count=$(aws ssm describe-parameters --region "$region" \
    --parameter-filters "Key=Name,Option=Contains,Values=shinjuku,liberdade" \
    --query 'length(Parameters)' --output text 2>/dev/null || echo 0)
  check "SSM Parameters (project)" "$count"

  echo ""
done

# --- Global resources ---
echo -e "${BOLD}--- Global / us-east-1 ---${NC}"

# S3 Buckets (project-related)
count=$(aws s3api list-buckets \
  --query 'length(Buckets[?contains(Name,`shinjuku`) || contains(Name,`liberdade`) || contains(Name,`lab3`)])' \
  --output text 2>/dev/null)
check "S3 Buckets (project-related)" "$count"

# CloudFront Distributions
count=$(aws cloudfront list-distributions \
  --query 'length(DistributionList.Items || `[]`)' --output text 2>/dev/null)
check "CloudFront Distributions" "$count"

# WAF Web ACLs (CloudFront scope, us-east-1)
count=$(aws wafv2 list-web-acls --scope CLOUDFRONT --region "$GLOBAL_REGION" \
  --query 'length(WebACLs)' --output text 2>/dev/null)
check "WAF Web ACLs (CloudFront)" "$count"

# ACM Certificates (us-east-1, used by CloudFront)
count=$(aws acm list-certificates --region "$GLOBAL_REGION" \
  --query 'length(CertificateSummaryList)' --output text 2>/dev/null)
check "ACM Certificates (us-east-1)" "$count"

# CloudTrail Trails
count=$(aws cloudtrail describe-trails \
  --query 'length(trailList)' --output text 2>/dev/null)
check "CloudTrail Trails" "$count"

# Route53 Records (excluding SOA and NS)
if aws route53 get-hosted-zone --id "$HOSTED_ZONE_ID" &>/dev/null; then
  count=$(aws route53 list-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" \
    --query 'length(ResourceRecordSets[?Type!=`SOA` && Type!=`NS`])' --output text 2>/dev/null)
  check "Route53 Records (non-SOA/NS)" "$count"
else
  echo -e "  ${GREEN}clear${NC}  Route53 Hosted Zone (not found)"
fi

# IAM Roles (project-related)
count=$(aws iam list-roles \
  --query 'length(Roles[?contains(RoleName,`shinjuku`) || contains(RoleName,`liberdade`)])' \
  --output text 2>/dev/null)
check "IAM Roles (project)" "$count"

# IAM Instance Profiles (project-related)
count=$(aws iam list-instance-profiles \
  --query 'length(InstanceProfiles[?contains(InstanceProfileName,`shinjuku`) || contains(InstanceProfileName,`liberdade`)])' \
  --output text 2>/dev/null)
check "IAM Instance Profiles (project)" "$count"

echo ""
echo -e "${BOLD}=== Summary ===${NC}"
if [[ "$found_resources" -eq 0 ]]; then
  echo -e "${GREEN}All clear — no active lab-3 resources found.${NC}"
else
  echo -e "${RED}Found $found_resources resource(s) still active. Review items marked FOUND above.${NC}"
fi
