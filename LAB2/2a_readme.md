Lab 2 = “Origin Cloaking + CloudFront as the only public ingress.”
The clean, realistic interpretation of your requirement (and what big orgs actually do) is:

  Only CloudFront is publicly reachable.
  ALB is still “internet-facing” (because CloudFront must reach it), but it’s cloaked so direct access is blocked:
    Security Group allows inbound only from the AWS-managed CloudFront origin-facing prefix list (com.amazonaws.global.cloudfront.origin-facing). 
    ALB listener requires a secret custom header that only CloudFront adds. 
  WAF moves to CloudFront (WAFv2 scope = "CLOUDFRONT"), and it is associated to the distribution. 
  chewbacca-growl.com (and app.chewbacca-growl.com) alias to CloudFront.



