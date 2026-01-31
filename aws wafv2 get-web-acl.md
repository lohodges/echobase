aws wafv2 get-web-acl \
  --name echobase-cf-waf01 \
  --scope CloudFront \
  --id 67599567-5d54-4728-8d0c-47aa4384a407 \
  --region us-east-1


aws cloudfront get-distribution \
  --id E2NGQIH2WYYBR3 \
  --query "Distribution.DistributionConfig.WebACLId"
```
1c_terrraform lhj-keepItSimple  ? ✗ aws cloudfront get-distribution \
  --id E2NGQIH2WYYBR3 \
  --query "Distribution.DistributionConfig.WebACLId"
"arn:aws:wafv2:us-east-1:746669200167:global/webacl/echobase-cf-waf01/67599567-5d54-4728-8d0c-47aa4384a407"
```




Code that does not work from the repo:
aws wafv2 get-web-acl \
  --name <project>-cf-waf01 \
  --scope CLOUDFRONT \
  --id <WEB_ACL_ID>

Use this instead:
https://docs.aws.amazon.com/cli/latest/reference/wafv2/get-web-acl.html
You must include the region.

aws wafv2 get-web-acl \
  --name echobase-cf-waf01 \
  --scope CLOUDFRONT \
  --id 67599567-5d54-4728-8d0c-47aa4384a407 \
  --region us-east-1

```
1c_terrraform lhj-keepItSimple  ? ❯ aws wafv2 get-web-acl \
  --name echobase-cf-waf01 \
  --scope CLOUDFRONT \
  --id 67599567-5d54-4728-8d0c-47aa4384a407 \
  --region us-east-1
{
    "WebACL": {
        "Name": "echobase-cf-waf01",
        "Id": "67599567-5d54-4728-8d0c-47aa4384a407",
        "ARN": "arn:aws:wafv2:us-east-1:746669200167:global/webacl/echobase-cf-waf01/67599567-5d54-4728-8d0c-47aa4384a407",
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
                    "MetricName": "echobase-cf-waf-common"
                }
            }
        ],
        "VisibilityConfig": {
            "SampledRequestsEnabled": true,
            "CloudWatchMetricsEnabled": true,
            "MetricName": "echobase-cf-waf01"
        },
        "Capacity": 700,
        "ManagedByFirewallManager": false,
        "LabelNamespace": "awswaf:746669200167:webacl:echobase-cf-waf01:",
        "RetrofittedByFirewallManager": false,
        "OnSourceDDoSProtectionConfig": {
            "ALBLowReputationMode": "ACTIVE_UNDER_DDOS"
        }
    },
    "LockToken": "35e10de8-17e3-41a7-8dd4-52ddc2ed8aed"
}
```
curl -I https://echobase.click
curl -I https://app.echobase.click