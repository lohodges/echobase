Verification commands (CLI) for Bonus-B
1) ALB exists and is active
   
      aws elbv2 describe-load-balancers \
        --names echobase-alb01 \
        --query "LoadBalancers[0].State.Code"
```
1c_terrraform lhj-keepItSimple  ❯ aws elbv2 describe-load-balancers \
        --names echobase-alb01 \
        --query "LoadBalancers[0].State.Code"
"active"
```

3) HTTPS listener exists on 443
   
      aws elbv2 describe-listeners \
        --load-balancer-arn <ALB_ARN> \
        --query "Listeners[].Port"

```
1c_terrraform lhj-keepItSimple  ? ❯ aws elbv2 describe-listeners \
        --load-balancer-arn arn:aws:elasticloadbalancing:us-east-2:746669200167:loadbalancer/app/echobase-alb01/b62af656a4f1375b \
        --query "Listeners[].Port"
[
    80,
    443
]
```


4) Target is healthy
   
      aws elbv2 describe-target-health \
        --target-group-arn <TG_ARN>
```
1c_terrraform lhj-keepItSimple  ? ❯ aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-2:746669200167:targetgroup/echobase-tg01/3ac8eb1647faffe9
{
    "TargetHealthDescriptions": [
        {
            "Target": {
                "Id": "i-0e44ad72c7b99c90f",
                "Port": 80
            },
            "HealthCheckPort": "80",
            "TargetHealth": {
                "State": "healthy"
            },
            "AdministrativeOverride": {
                "State": "no_override",
                "Reason": "AdministrativeOverride.NoOverride",
                "Description": "No override is currently active on target"
            }
        },
        {
            "Target": {
                "Id": "i-06e2bf130f642b94d",
                "Port": 80
            },
            "HealthCheckPort": "80",
            "TargetHealth": {
                "State": "healthy"
            },
            "AdministrativeOverride": {
                "State": "no_override",
                "Reason": "AdministrativeOverride.NoOverride",
                "Description": "No override is currently active on target"
            }
        }
    ]
}
```

5) WAF attached
   
      aws wafv2 get-web-acl-for-resource \
        --resource-arn <ALB_ARN>

```
1c_terrraform lhj-keepItSimple  ? ✗ aws wafv2 get-web-acl-for-resource \
        --resource-arn arn:aws:elasticloadbalancing:us-east-2:746669200167:loadbalancer/app/echobase-alb01/ec8f3f5d4b163e0a
{
    "WebACL": {
        "Name": "echobase-waf01",
        "Id": "43c77645-7cf5-4f92-aeb4-43f7d90009f0",
        "ARN": "arn:aws:wafv2:us-east-2:746669200167:regional/webacl/echobase-waf01/43c77645-7cf5-4f92-aeb4-43f7d90009f0",
        "DefaultAction": {
            "Allow": {}
        },
        "Description": "",
        "Rules": [
            {
                "Name": "AWSManagedRulesCommonRuleSet",
                "Priority": 1,
                "Statement": {
                    "ManagedRuleGroupStatement": {
                        "VendorName": "AWS",
                        "Name": "AWSManagedRulesCommonRuleSet"
                    }
                },
                "OverrideAction": {
                    "None": {}
                },
                "VisibilityConfig": {
                    "SampledRequestsEnabled": true,
                    "CloudWatchMetricsEnabled": true,
                    "MetricName": "echobase-waf-common"
                }
            }
        ],
        "VisibilityConfig": {
            "SampledRequestsEnabled": true,
            "CloudWatchMetricsEnabled": true,
            "MetricName": "echobase-waf01"
        },
        "Capacity": 700,
        "ManagedByFirewallManager": false,
        "LabelNamespace": "awswaf:746669200167:webacl:echobase-waf01:",
        "RetrofittedByFirewallManager": false,
        "OnSourceDDoSProtectionConfig": {
            "ALBLowReputationMode": "ACTIVE_UNDER_DDOS"
        }
    }
}
```

7) Alarm created (ALB 5xx)
   
      aws cloudwatch describe-alarms \
        --alarm-name-prefix echobase-alb-5xx
```
1c_terrraform lhj-keepItSimple  ? ❯ aws cloudwatch describe-alarms \
        --alarm-name-prefix echobase-alb-5xx
{
    "MetricAlarms": [
        {
            "AlarmName": "echobase-alb-5xx-alarm01",
            "AlarmArn": "arn:aws:cloudwatch:us-east-2:746669200167:alarm:echobase-alb-5xx-alarm01",
            "AlarmConfigurationUpdatedTimestamp": "2026-01-20T13:10:42.407000-05:00",
            "ActionsEnabled": true,
            "OKActions": [],
            "AlarmActions": [
                "arn:aws:sns:us-east-2:746669200167:echobase-db-incidents"
            ],
            "InsufficientDataActions": [],
            "StateValue": "INSUFFICIENT_DATA",
            "StateReason": "Unchecked: Initial alarm creation",
            "StateUpdatedTimestamp": "2026-01-20T13:10:42.407000-05:00",
            "MetricName": "HTTPCode_ELB_5XX_Count",
            "Namespace": "AWS/ApplicationELB",
            "Statistic": "Sum",
            "Dimensions": [
                {
                    "Name": "LoadBalancer",
                    "Value": "app/echobase-alb01/ec8f3f5d4b163e0a"
                }
            ],
            "Period": 300,
            "EvaluationPeriods": 1,
            "Threshold": 10.0,
            "ComparisonOperator": "GreaterThanOrEqualToThreshold",
            "TreatMissingData": "missing",
            "StateTransitionedTimestamp": "2026-01-20T13:10:42.407000-05:00"
        }
    ],
    "CompositeAlarms": []
}
```

9) Dashboard exists
    
      aws cloudwatch list-dashboards \
        --dashboard-name-prefix echobase
```
1c_terrraform lhj-keepItSimple  ? ❯ aws cloudwatch list-dashboards \
        --dashboard-name-prefix echobase
{
    "DashboardEntries": [
        {
            "DashboardName": "echobase-dashboard01",
            "DashboardArn": "arn:aws:cloudwatch::746669200167:dashboard/echobase-dashboard01",
            "LastModified": "2026-01-20T13:10:43-05:00",
            "Size": 652
        }
    ]
}
```