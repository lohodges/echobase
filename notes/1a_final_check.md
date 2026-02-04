```
1c_terrraform/python main ? ✗ REGION=$REGION INSTANCE_ID=$INSTANCE_ID SECRET_ID=$SECRET_ID DB_ID=$DB_ID ./run_all_gates.sh
=== Running Gate 1/2: secrets_and_role ===

=== SEIR Gate: Secrets + EC2 Role Verification ===
Timestamp (UTC): 2026-01-15T00:36:59Z
Region:          us-east-2
Instance ID:     i-0490a61382b353f55
Secret ID:       echobase/rds/mysql
Resolved Role:   echobase-ec2-role01
Caller ARN:      arn:aws:iam::746669200167:user/AWSCLI
-----------------------------------------------
PASS: aws sts get-caller-identity succeeded (credentials OK).
PASS: secret exists and is describable (echobase/rds/mysql).
INFO: rotation requirement disabled (REQUIRE_ROTATION=false).
PASS: no resource policy found (OK) or not applicable (echobase/rds/mysql).
PASS: instance has IAM instance profile attached (i-0490a61382b353f55).
PASS: resolved instance profile -> role (echobase-instance-profile01 -> echobase-ec2-role01).
INFO: EXPECTED_ROLE_NAME not set; using resolved role (echobase-ec2-role01).
INFO: on-instance checks skipped (not running as expected role on EC2).

Warnings:
  - WARN: current caller ARN is not assumed-role/echobase-ec2-role01 (you may be running off-instance).

RESULT: PASS
===============================================

Wrote: gate_result.json
=== Running Gate 2/2: network_db ===

=== SEIR Gate: Network + RDS Verification ===
Timestamp (UTC): 2026-01-15T00:37:08Z
Region:          us-east-2
EC2 Instance:    i-0490a61382b353f55
RDS Instance:    echobase-rds01
Engine:          mysql
DB Port:         3306
Caller ARN:      arn:aws:iam::746669200167:user/AWSCLI
-------------------------------------------
PASS: aws sts get-caller-identity succeeded (credentials OK).
PASS: RDS instance exists (echobase-rds01).
PASS: RDS is not publicly accessible (PubliclyAccessible=False).
PASS: discovered DB port = 3306 (engine=mysql).
PASS: EC2 security groups resolved (i-0490a61382b353f55): sg-01da50e49533dc4c8
PASS: RDS security groups resolved (echobase-rds01): sg-05ebae9d518be0c6d
PASS: RDS SG allows DB port 3306 from EC2 SG (SG-to-SG ingress present).
INFO: private subnet check disabled (CHECK_PRIVATE_SUBNETS=false).

RESULT: PASS
===========================================

Wrote: gate_result.json
```