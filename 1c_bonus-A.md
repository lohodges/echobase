Design goals
  EC2 is private (no public IP)
  No SSH required (use SSM Session Manager)
  Private subnets don’t need NAT to talk to AWS control-plane services
  Use VPC Interface Endpoints for:
    SSM, EC2Messages, SSMMessages (Session Manager)
    CloudWatch Logs
    Secrets Manager
    KMS (optional but realistic)
Use S3 Gateway Endpoint (common “gotcha” for private environments)
Tighten IAM: GetSecretValue only for your secret, GetParameter(s) only for your path

Note: If you remove NAT entirely, OS package installs can be tricky unless repos are reachable (often via S3). This skeleton gives you S3 endpoint and leaves NAT as optional “student choice.” In many orgs, teams use golden AMIs or image pipelines to avoid yum/apt internet needs in private subnets.


Student verification (CLI) for Bonus-A
1) Prove EC2 is private (no public IP)
  aws ec2 describe-instances \
  --instance-ids <INSTANCE_ID> \
  --query "Reservations[].Instances[].PublicIpAddress"

Expected: 
  null
```
1c_terrraform lhj-keepItSimple  ❯ aws ec2 describe-instances \
  --instance-ids i-080b7c580b7cf487f \
  --query "Reservations[].Instances[].PublicIpAddress"
[]
```

2) Prove VPC endpoints exist
  aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=<VPC_ID>" \
  --query "VpcEndpoints[].ServiceName"

Expected: list includes:
  ssm 
  ec2messages 
  ssmmessages 
  logs 
  secretsmanager
  s3

  
```
1c_terrraform lhj-keepItSimple  ? ❯ aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=vpc-0dd49728f2b31ee35" \
  --query "VpcEndpoints[].ServiceName"
[
    "com.amazonaws.us-east-2.s3",
    "com.amazonaws.us-east-2.ssm",
    "com.amazonaws.us-east-2.ssmmessages",
    "com.amazonaws.us-east-2.ec2messages",
    "com.amazonaws.us-east-2.logs",
    "com.amazonaws.us-east-2.kms",
    "com.amazonaws.us-east-2.secretsmanager"
]
```

3) Prove Session Manager path works (no SSH)
  aws ssm describe-instance-information \
  --query "InstanceInformationList[].InstanceId"

Expected: your private EC2 instance ID appears
```
1c_terrraform lhj-keepItSimple  ? ❯ aws ssm describe-instance-information \
  --query "InstanceInformationList[].InstanceId"
[
    "i-080b7c580b7cf487f"
]
```

4) Prove the instance can read both config stores
Run from SSM session:
  aws ssm get-parameter --name /lab/db/endpoint
  aws secretsmanager get-secret-value --secret-id <your-secret-name>
```
1c_terrraform lhj-keepItSimple  ? ❯ aws ssm get-parameter --name /lab/db/endpoint
  aws secretsmanager get-secret-value --secret-id echobase/rds/mysql
{
    "Parameter": {
        "Name": "/lab/db/endpoint",
        "Type": "String",
        "Value": "echobase-rds01.cxo22gqsc8z4.us-east-2.rds.amazonaws.com",
        "Version": 1,
        "LastModifiedDate": "2026-01-19T07:35:15.689000-05:00",
        "ARN": "arn:aws:ssm:us-east-2:746669200167:parameter/lab/db/endpoint",
        "DataType": "text"
    }
}
{
    "ARN": "arn:aws:secretsmanager:us-east-2:746669200167:secret:echobase/rds/mysql-QsWdk8",
    "Name": "echobase/rds/mysql",
    "VersionId": "terraform-20260119123515370900000009",
    "SecretString": "{\"dbname\":\"notesappdb\",\"host\":\"echobase-rds01.cxo22gqsc8z4.us-east-2.rds.amazonaws.com\",\"password\":\"<PASSWORD-REMOVED>\",\"port\":3306,\"username\":\"admin\"}",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2026-01-19T07:35:15.677000-05:00"
}
```

5) Prove CloudWatch logs delivery path is available via endpoint
  aws logs describe-log-streams \
    --log-group-name /aws/ec2/<prefix>-rds-app
```
1c_terrraform lhj-keepItSimple  ? ❯ aws logs describe-log-streams \
    --log-group-name /aws/ec2/echobase-rds-app
{
    "logStreams": [
        {
            "logStreamName": "echobase-rds-app",
            "creationTime": 1768825720288,
            "arn": "arn:aws:logs:us-east-2:746669200167:log-group:/aws/ec2/echobase-rds-app:log-stream:echobase-rds-app",
            "storedBytes": 0
        }
    ]
}
```

How this maps to “real company” practice (short, employer-credible)
  Private compute + SSM is standard in regulated orgs and mature cloud shops.
  VPC endpoints reduce exposure and dependency on NAT for AWS APIs.
  Least privilege is not optional in security interviews.
  Terraform submission mirrors how teams ship changes: PR → plan → review → apply → monitor.


