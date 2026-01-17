7. Technical Verification Using AWS CLI (Required)
You must verify everything via CLI — not screenshots alone. What? You think this is easy?

7.1 Verify Parameter Store Values

    aws ssm get-parameters \
      --names /lab/db/endpoint /lab/db/port /lab/db/name \
      --with-decryption

Expected:
  Parameter names returned
  Correct DB endpoint and port
```
1c_terrraform/python main ? ❯ aws ssm get-parameters \
      --names "/lab/db/endpoint" "/lab/db/port" "/lab/db/name" \
      --with-decryption
{
    "Parameters": [
        {
            "Name": "/lab/db/endpoint",
            "Type": "String",
            "Value": "echobase-rds01.cxo22gqsc8z4.us-east-2.rds.amazonaws.com",
            "Version": 1,
            "LastModifiedDate": "2026-01-14T18:04:24.719000-05:00",
            "ARN": "arn:aws:ssm:us-east-2:746669200167:parameter/lab/db/endpoint",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/name",
            "Type": "String",
            "Value": "notesappdb",
            "Version": 1,
            "LastModifiedDate": "2026-01-14T17:59:12.409000-05:00",
            "ARN": "arn:aws:ssm:us-east-2:746669200167:parameter/lab/db/name",
            "DataType": "text"
        },
        {
            "Name": "/lab/db/port",
            "Type": "String",
            "Value": "3306",
            "Version": 1,
            "LastModifiedDate": "2026-01-14T18:04:24.723000-05:00",
            "ARN": "arn:aws:ssm:us-east-2:746669200167:parameter/lab/db/port",
            "DataType": "text"
        }
    ],
    "InvalidParameters": []
}
```

  7.2 Verify Secrets Manager Value
  
      aws secretsmanager get-secret-value \
      --secret-id lab/rds/mysql

Expected:
  JSON output
  Fields: 
    username 
    password 
    host 
    port
```
1c_terrraform/python main ? ❯ aws secretsmanager get-secret-value \
      --secret-id lab/rds/mysql
{
    "ARN": "arn:aws:secretsmanager:us-east-2:746669200167:secret:lab/rds/mysql-VxRjeA",
    "Name": "lab/rds/mysql",
    "VersionId": "276e03b4-480e-4623-9323-62b630fc3857",
    "SecretString": "{\"username\":\"admin\",\"password\":\"<PASSWORD-INTENTIONALLY-REMOVED-FROM-OUTPUT>\",\"engine\":\"mysql\",\"host\":\"lab-mysql.cxo22gqsc8z4.us-east-2.rds.amazonaws.com\",\"port\":3306,\"dbInstanceIdentifier\":\"lab-mysql\"}",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2026-01-10T07:20:32.007000-05:00"
}
```

7.3 Verify EC2 Can Read Both Systems
From EC2:

    aws ssm get-parameter --name /lab/db/endpoint
    aws secretsmanager get-secret-value --secret-id lab/rds/mysql

Expected:
  Both commands succeed
  No AccessDeniedException
```
1c_terrraform/python main ? ❯ aws ssm get-parameter --name /lab/db/endpoint
{
    "Parameter": {
        "Name": "/lab/db/endpoint",
        "Type": "String",
        "Value": "echobase-rds01.cxo22gqsc8z4.us-east-2.rds.amazonaws.com",
        "Version": 1,
        "LastModifiedDate": "2026-01-14T18:04:24.719000-05:00",
        "ARN": "arn:aws:ssm:us-east-2:746669200167:parameter/lab/db/endpoint",
        "DataType": "text"
    }
}

1c_terrraform/python main ? ❯ aws secretsmanager get-secret-value --secret-id lab/rds/mysql
{
    "ARN": "arn:aws:secretsmanager:us-east-2:746669200167:secret:lab/rds/mysql-VxRjeA",
    "Name": "lab/rds/mysql",
    "VersionId": "276e03b4-480e-4623-9323-62b630fc3857",
    "SecretString": "{\"username\":\"admin\",\"password\":\"<PASSWORD REMOVED>\",\"engine\":\"mysql\",\"host\":\"lab-mysql.cxo22gqsc8z4.us-east-2.rds.amazonaws.com\",\"port\":3306,\"dbInstanceIdentifier\":\"lab-mysql\"}",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2026-01-10T07:20:32.007000-05:00"
}
```
  
7.4 Verify CloudWatch Log Group Exists
    
    aws logs describe-log-groups \
      --log-group-name-prefix /aws/ec2/echobase-rds-app

Expected:
  Log group present
```
1c_terrraform main  ✗ aws logs describe-log-groups \
      --log-group-name-prefix /aws/ec2/echobase-rds-app
{
    "logGroups": [
        {
            "logGroupName": "/aws/ec2/echobase-rds-app",
            "creationTime": 1768515272605,
            "retentionInDays": 7,
            "metricFilterCount": 0,
            "arn": "arn:aws:logs:us-east-2:746669200167:log-group:/aws/ec2/echobase-rds-app:*",
            "storedBytes": 0,
            "logGroupClass": "STANDARD",
            "logGroupArn": "arn:aws:logs:us-east-2:746669200167:log-group:/aws/ec2/echobase-rds-app",
            "deletionProtectionEnabled": false
        }
    ]
}
```

7.5 Verify DB Failure Logs Appear
Simulate failure (examples):
  Stop RDS
  Change DB password in Secrets Manager without updating DB
  Block SG temporarily

Then check logs:

    aws logs filter-log-events \
      --log-group-name /aws/ec2/echobase-rds-app \
      --filter-pattern "ERROR"

Expected:
  Explicit DB connection failure messages
  
7.6 Verify CloudWatch Alarm

    aws cloudwatch describe-alarms \
      --alarm-name-prefix lab-db-connection

Expected:
  Alarm present
  State transitions to ALARM during failure

7.7 Incident Recovery Verification
After restoring correct credentials or connectivity:

    curl http://<EC2_PUBLIC_IP>/list

Expected:
  Application resumes normal operation
  No redeployment required

8. Incident-Response Focus (What This Lab Teaches)
During recovery, you must:
  Identify failure source via logs
  Retrieve correct values from:
    Parameter Store
    Secrets Manager
  Restore service using configuration — not guesswork

This mirrors real on-call workflows.

9. Common Failure Modes (And Why They Matter)
| Failure                    | Real-World Meaning        |
| -------------------------- | ------------------------- |
| Alarm never fires          | Poor observability        |
| Logs lack detail           | Weak incident diagnostics |
| EC2 can’t read parameters  | IAM misdesign             |
| Recovery requires redeploy | Fragile architecture      |

10. What Completing Lab 1b Proves
If you complete this lab, you can confidently say:
  “I can operate, monitor, and recover AWS workloads using proper secret management and observability.”

That is mid-level engineer capability, not entry-level.

11. Reflection Questions: Answer all of these
  A) Why might Parameter Store still exist alongside Secrets Manager?
  B) What breaks first during secret rotation?
  C) Why should alarms be based on symptoms instead of causes?  
  D) How does this lab reduce mean time to recovery (MTTR)?
  E) What would you automate next?