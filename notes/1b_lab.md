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
    aws secretsmanager get-secret-value --secret-id echobase/rds/mysql

Expected:
  Both commands succeed
  No AccessDeniedException
```
1c_terrraform lhj-keepItSimple  ❯ aws ssm get-parameter --name /lab/db/endpoint
    aws secretsmanager get-secret-value --secret-id echobase/rds/mysql
{
    "Parameter": {
        "Name": "/lab/db/endpoint",
        "Type": "String",
        "Value": "echobase-rds01.cxo22gqsc8z4.us-east-2.rds.amazonaws.com",
        "Version": 1,
        "LastModifiedDate": "2026-01-18T15:03:52.798000-05:00",
        "ARN": "arn:aws:ssm:us-east-2:746669200167:parameter/lab/db/endpoint",
        "DataType": "text"
    }
}
{
    "ARN": "arn:aws:secretsmanager:us-east-2:746669200167:secret:echobase/rds/mysql-zZrbw7",
    "Name": "echobase/rds/mysql",
    "VersionId": "de712a83-5905-4a8a-94c2-094997383c60",
    "SecretString": "{\"dbname\":\"notesappdb\",\"host\":\"echobase-rds01.cxo22gqsc8z4.us-east-2.rds.amazonaws.com\",\"password\":\"<PASSWORD-REMOVED>\",\"port\":3306,\"username\":\"admin\"}",
    "VersionStages": [
        "AWSCURRENT"
    ],
    "CreatedDate": "2026-01-18T15:24:40.510000-05:00"
}
```
  
7.4 Verify CloudWatch Log Group Exists
    
    aws logs describe-log-groups \
      --log-group-name-prefix /aws/ec2/echobase-rds-app

Expected:
  Log group present
```
1c_terrraform lhj-keepItSimple  ❯ aws logs describe-log-groups \
      --log-group-name-prefix /aws/ec2/echobase-rds-app
{
    "logGroups": [
        {
            "logGroupName": "/aws/ec2/echobase-rds-app",
            "creationTime": 1768766257979,
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

```
~ ❯ aws logs filter-log-events \
      --log-group-name /aws/ec2/echobase-rds-app \
      --filter-pattern "ERROR"
{
    "events": [
        {
            "logStreamName": "echobase-rds-app",
            "timestamp": 1772501458286,
            "message": "ERROR: DB connection failed - (2003, \"Can't connect to MySQL server on 'echobase-rds01.cz00co24mrn8.ap-northeast-1.rds.amazonaws.com' ([Errno 111] Connection refused)\")",
            "ingestionTime": 1772501458328,
            "eventId": "39528103385260042104943181994103273755825886537964584960"
        },
        {
            "logStreamName": "echobase-rds-app",
            "timestamp": 1772501461783,
            "message": "ERROR: DB connection failed - (2003, \"Can't connect to MySQL server on 'echobase-rds01.cz00co24mrn8.ap-northeast-1.rds.amazonaws.com' ([Errno 111] Connection refused)\")",
            "ingestionTime": 1772501461788,
            "eventId": "39528103463245748064204771124236865645188166486659760128"
        }
    ],
    "searchedLogStreams": []
}
```
  
7.6 Verify CloudWatch Alarm

    aws cloudwatch describe-alarms \
      --alarm-name-prefix echobase-db-connection-failure

Expected:
  Alarm present
  State transitions to ALARM during failure
```
1c_terrraform main  ? ❯ aws cloudwatch describe-alarms \
      --alarm-name-prefix echobase-db-connection-failure
{
    "MetricAlarms": [
        {
            "AlarmName": "echobase-db-connection-failure",
            "AlarmArn": "arn:aws:cloudwatch:ap-northeast-1:746669200167:alarm:echobase-db-connection-failure",
            "AlarmConfigurationUpdatedTimestamp": "2026-03-02T20:08:41.736000-05:00",
            "ActionsEnabled": true,
            "OKActions": [],
            "AlarmActions": [
                "arn:aws:sns:ap-northeast-1:746669200167:echobase-db-incidents"
            ],
            "InsufficientDataActions": [],
            "StateValue": "ALARM",
            "StateReason": "Threshold Crossed: 1 datapoint [6.0 (03/03/26 01:35:00)] was greater than or equal to the threshold (3.0).",
            "StateReasonData": "{\"version\":\"1.0\",\"queryDate\":\"2026-03-03T01:40:05.812+0000\",\"startDate\":\"2026-03-03T01:35:00.000+0000\",\"statistic\":\"Sum\",\"period\":300,\"recentDatapoints\":[6.0],\"threshold\":3.0,\"evaluatedDatapoints\":[{\"timestamp\":\"2026-03-03T01:35:00.000+0000\",\"sampleCount\":6.0,\"value\":6.0}]}",
            "StateUpdatedTimestamp": "2026-03-02T20:40:05.858000-05:00",
            "MetricName": "DBConnectionErrors",
            "Namespace": "Lab/RDSApp",
            "Statistic": "Sum",
            "Dimensions": [],
            "Period": 300,
            "EvaluationPeriods": 1,
            "Threshold": 3.0,
            "ComparisonOperator": "GreaterThanOrEqualToThreshold",
            "TreatMissingData": "missing",
            "StateTransitionedTimestamp": "2026-03-02T20:40:05.858000-05:00"
        }
    ],
    "CompositeAlarms": []
}
```

7.7 Incident Recovery Verification
After restoring correct credentials or connectivity:

    curl http://<EC2_PUBLIC_IP>/list

Expected:
  Application resumes normal operation
  No redeployment required
```
1c_terrraform main  ? ❯ curl -I https://app.echobase.click/list
HTTP/2 200
content-type: text/html; charset=utf-8
content-length: 65
date: Tue, 03 Mar 2026 01:46:07 GMT
server: Werkzeug/3.1.6 Python/3.9.25
x-cache: Miss from cloudfront
via: 1.1 50fb19eda678e6a896981a444fb09aa6.cloudfront.net (CloudFront)
x-amz-cf-pop: MIA3-P3
x-amz-cf-id: m2WOlRbokCLbQImJ3_2XAepcoOtr8o7YAAcRjQ76lKtaUc_aAedj5g==
```

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