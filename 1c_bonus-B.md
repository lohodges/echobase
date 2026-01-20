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

7) Alarm created (ALB 5xx)
   
      aws cloudwatch describe-alarms \
        --alarm-name-prefix echobase-alb-5xx

9) Dashboard exists
    
      aws cloudwatch list-dashboards \
        --dashboard-name-prefix echobase