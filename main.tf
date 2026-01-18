############################################
# Locals (naming convention: Echobase-*)
############################################
locals {
  name_prefix = var.project_name

  # Explanation: Name prefix is the roar that echoes through every tag.
  echobase_prefix = var.project_name

  # TODO: Students should lock this down after apply using the real secret ARN from outputs/state
  echobase_secret_arn_guess = "arn:aws:secretsmanager:${data.aws_region.echobase_region01.name}:${data.aws_caller_identity.echobase_self01.account_id}:secret:${local.echobase_prefix}/rds/mysql*"

  # Explanation: This is the roar address — where the galaxy finds your app.
  echobase_fqdn = "${var.app_subdomain}.${var.domain_name}"
}

# added by Lonnie Hodges on 2026-01-17
############################################
# Bonus A - Data
############################################

# Explanation: echobase wants to know “who am I in this galaxy?” so ARNs can be scoped properly.
data "aws_caller_identity" "echobase_self01" {}

# Explanation: Region matters—hyperspace lanes change per sector.
data "aws_region" "echobase_region01" {}
# ^^^ added by Lonnie Hodges on 2026-01-17

############################################
# VPC + Internet Gateway
############################################

# Explanation: Echobase needs a hyperlane—this VPC is the Millennium Falcon’s flight corridor.
resource "aws_vpc" "echobase_vpc01" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc01"
  }
}

# Explanation: Even Wookiees need to reach the wider galaxy—IGW is your door to the public internet.
resource "aws_internet_gateway" "echobase_igw01" {
  vpc_id = aws_vpc.echobase_vpc01.id

  tags = {
    Name = "${local.name_prefix}-igw01"
  }
}

############################################
# Subnets (Public + Private)
############################################

# Explanation: Public subnets are like docking bays—ships can land directly from space (internet).
resource "aws_subnet" "echobase_public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.echobase_vpc01.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet0${count.index + 1}"
  }
}

# Explanation: Private subnets are the hidden Rebel base—no direct access from the internet.
resource "aws_subnet" "echobase_private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.echobase_vpc01.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${local.name_prefix}-private-subnet0${count.index + 1}"
  }
}

############################################
# NAT Gateway + EIP
############################################

# Explanation: Echobase wants the private base to call home—EIP gives the NAT a stable “holonet address.”
resource "aws_eip" "echobase_nat_eip01" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip01"
  }
}

# Explanation: NAT is Echobase’s smuggler tunnel—private subnets can reach out without being seen.
resource "aws_nat_gateway" "echobase_nat01" {
  allocation_id = aws_eip.echobase_nat_eip01.id
  subnet_id     = aws_subnet.echobase_public_subnets[0].id # NAT in a public subnet

  tags = {
    Name = "${local.name_prefix}-nat01"
  }

  depends_on = [aws_internet_gateway.echobase_igw01]
}

############################################
# Routing (Public + Private Route Tables)
############################################

# Explanation: Public route table = “open lanes” to the galaxy via IGW.
resource "aws_route_table" "echobase_public_rt01" {
  vpc_id = aws_vpc.echobase_vpc01.id

  tags = {
    Name = "${local.name_prefix}-public-rt01"
  }
}

# Explanation: This route is the Kessel Run—0.0.0.0/0 goes out the IGW.
resource "aws_route" "echobase_public_default_route" {
  route_table_id         = aws_route_table.echobase_public_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.echobase_igw01.id
}

# Explanation: Attach public subnets to the “public lanes.”
resource "aws_route_table_association" "echobase_public_rta" {
  count          = length(aws_subnet.echobase_public_subnets)
  subnet_id      = aws_subnet.echobase_public_subnets[count.index].id
  route_table_id = aws_route_table.echobase_public_rt01.id
}

# Explanation: Private route table = “stay hidden, but still ship supplies.”
resource "aws_route_table" "echobase_private_rt01" {
  vpc_id = aws_vpc.echobase_vpc01.id

  tags = {
    Name = "${local.name_prefix}-private-rt01"
  }
}

# Explanation: Private subnets route outbound internet via NAT (Echobase-approved stealth).
resource "aws_route" "echobase_private_default_route" {
  route_table_id         = aws_route_table.echobase_private_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.echobase_nat01.id
}

# Explanation: Attach private subnets to the “stealth lanes.”
resource "aws_route_table_association" "echobase_private_rta" {
  count          = length(aws_subnet.echobase_private_subnets)
  subnet_id      = aws_subnet.echobase_private_subnets[count.index].id
  route_table_id = aws_route_table.echobase_private_rt01.id
}

############################################
# Security Groups (EC2 + RDS)
############################################

# Explanation: EC2 SG is Echobase’s bodyguard—only let in what you mean to.
resource "aws_security_group" "echobase_ec2_sg01" {
  name        = "${local.name_prefix}-ec2-sg01"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.echobase_vpc01.id

  tags = {
    Name = "${local.name_prefix}-ec2-sg01"
  }
}

# TODO: student adds inbound rules (HTTP 80, SSH 22 from their IP)
# added by Lonnie Hodges
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id            = aws_security_group.echobase_ec2_sg01.id
  referenced_security_group_id = aws_security_group.echobase_alb_sg01.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}
# ^^^ added by Lonnie Hodgesv

# added by Lonnie Hodges
resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id            = aws_security_group.echobase_ec2_sg01.id
  referenced_security_group_id = aws_security_group.echobase_alb_sg01.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}
# ^^^ added by Lonnie Hodges

# TODO: student ensures outbound allows DB port to RDS SG (or allow all outbound)
# added by Lonnie Hodges
resource "aws_vpc_security_group_egress_rule" "out_to_rds" {
  security_group_id = aws_security_group.echobase_ec2_sg01.id
  #cidr_ipv4         = "0.0.0.0/0"
  referenced_security_group_id = aws_security_group.echobase_rds_sg01.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
}

resource "aws_vpc_security_group_egress_rule" "out_ec2_all" {
  security_group_id = aws_security_group.echobase_ec2_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Explanation: RDS SG is the Rebel vault—only the app server gets a keycard.
resource "aws_security_group" "echobase_rds_sg01" {
  name        = "${local.name_prefix}-rds-sg01"
  description = "RDS security group"
  vpc_id      = aws_vpc.echobase_vpc01.id

  tags = {
    Name = "${local.name_prefix}-rds-sg01"
  }
}

# TODO: student adds inbound MySQL 3306 from aws_security_group.echobase_ec2_sg01.id
# added by Lonnie Hodges
resource "aws_vpc_security_group_ingress_rule" "from_ec2" {
  security_group_id            = aws_security_group.echobase_rds_sg01.id
  referenced_security_group_id = aws_security_group.echobase_ec2_sg01.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
}

# added by Lonnie Hodges 2026-01-17
############################################
# Security Group for VPC Interface Endpoints
############################################

# Explanation: Even endpoints need guards—Echobase posts a Wookiee at every airlock.
resource "aws_security_group" "echobase_vpce_sg01" {
  name        = "${local.echobase_prefix}-vpce-sg01"
  description = "SG for VPC Interface Endpoints"
  vpc_id      = aws_vpc.echobase_vpc01.id

  # TODO: Students must allow inbound 443 FROM the EC2 SG (or VPC CIDR) to endpoints.
  # NOTE: Interface endpoints ENIs receive traffic on 443.

  tags = {
    Name = "${local.echobase_prefix}-vpce-sg01"
  }
}

# added by Lonnie Hodges
resource "aws_vpc_security_group_ingress_rule" "https_vpce01" {
  security_group_id = aws_security_group.echobase_vpce_sg01.id
  cidr_ipv4         = "10.124.0.0/16"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
# ^^^ added by Lonnie Hodges

############################################
# Security Group: ALB
############################################

# Explanation: The ALB SG is the blast shield — only allow what the Rebellion needs (80/443).
resource "aws_security_group" "echobase_alb_sg01" {
  name        = "${var.project_name}-alb-sg01"
  description = "ALB security group"
  vpc_id      = aws_vpc.echobase_vpc01.id

  # TODO: students add inbound 80/443 from 0.0.0.0/0
  # TODO: students set outbound to target group port (usually 80) to private targets

  tags = {
    Name = "${var.project_name}-alb-sg01"
  }
}

# Explanation: echobase only opens the hangar door — allow ALB -> EC2 on app port (e.g., 80).
resource "aws_vpc_security_group_ingress_rule" "echobase_ec2_ingress_from_alb01" {
  security_group_id = aws_security_group.echobase_alb_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "echobase_ec2_ingress_from_alb01_tls" {
  security_group_id = aws_security_group.echobase_alb_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "echobase_ec2_egress_to_ec201" {
  security_group_id            = aws_security_group.echobase_alb_sg01.id
  referenced_security_group_id = aws_security_group.echobase_ec2_sg01.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "echobase_ec2_egress_to_ec201_tls" {
  security_group_id            = aws_security_group.echobase_alb_sg01.id
  referenced_security_group_id = aws_security_group.echobase_ec2_sg01.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}
# ^^^ added by Lonnie Hodges 2026-01-17

############################################
# RDS Subnet Group
############################################

# Explanation: RDS hides in private subnets like the Rebel base on Hoth—cold, quiet, and not public.
resource "aws_db_subnet_group" "echobase_rds_subnet_group01" {
  name       = "${local.name_prefix}-rds-subnet-group01"
  subnet_ids = aws_subnet.echobase_private_subnets[*].id

  tags = {
    Name = "${local.name_prefix}-rds-subnet-group01"
  }
}

############################################
# RDS Instance (MySQL)
############################################

# Explanation: This is the holocron of state—your relational data lives here, not on the EC2.
resource "aws_db_instance" "echobase_rds01" {
  identifier        = "${local.name_prefix}-rds01"
  engine            = var.db_engine
  instance_class    = var.db_instance_class
  allocated_storage = 20
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.echobase_rds_subnet_group01.name
  vpc_security_group_ids = [aws_security_group.echobase_rds_sg01.id]

  publicly_accessible = false
  skip_final_snapshot = true

  # added by Lonnie Hodges
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery", "iam-db-auth-error"]

  # TODO: student sets multi_az / backups / monitoring as stretch goals
  # added by Lonnie Hodges: to add later



  tags = {
    Name = "${local.name_prefix}-rds01"
  }
}

############################################
# IAM Role + Instance Profile for EC2
############################################

# added by Lonnie Hodges
resource "aws_iam_policy" "policy_ec2_read_secret" {
  name        = "read_specific_secret"
  path        = "/"
  description = "EC2 must read secrets/params during recovery—give it access."

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "ReadSpecificSecret",
        "Effect" : "Allow",
        "Action" : ["secretsmanager:GetSecretValue"],
        # "Resource" : "arn:aws:secretsmanager:<REGION>:<ACCOUNT ID>:secret:echobase/rds/mysql*"
        "Resource" : "arn:aws:secretsmanager:us-east-2:746669200167:secret:echobase/rds/mysql*"
      }
    ]
  })
}
# added by Lonnie Hodges

# Explanation: Echobase refuses to carry static keys—this role lets EC2 assume permissions safely.
resource "aws_iam_role" "echobase_ec2_role01" {
  name = "${local.name_prefix}-ec2-role01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Explanation: These policies are your Wookiee toolbelt—tighten them (least privilege) as a stretch goal.
resource "aws_iam_role_policy_attachment" "echobase_ec2_ssm_attach" {
  role       = aws_iam_role.echobase_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Explanation: EC2 must read secrets/params during recovery—give it access (students should scope it down).
resource "aws_iam_role_policy_attachment" "echobase_ec2_secrets_attach" {
  role = aws_iam_role.echobase_ec2_role01.name
  # added by Lonnie Hodges
  #policy_arn = aws_iam_policy.policy_ec2_read_secret.arn
  # commented out line below by Lonnie Hodges
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite" # TODO: student replaces w/ least privilege
}

# Explanation: CloudWatch logs are the “ship’s black box”—you need them when things explode.
resource "aws_iam_role_policy_attachment" "echobase_ec2_cw_attach" {
  role       = aws_iam_role.echobase_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Explanation: Instance profile is the harness that straps the role onto the EC2 like bandolier ammo.
resource "aws_iam_instance_profile" "echobase_instance_profile01" {
  name = "${local.name_prefix}-instance-profile01"
  role = aws_iam_role.echobase_ec2_role01.name
}

############################################
# EC2 Instance (App Host)
############################################

# Explanation: This is your “Han Solo box”—it talks to RDS and complains loudly when the DB is down.
resource "aws_instance" "echobase_ec201" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.echobase_public_subnets[0].id
  vpc_security_group_ids = [aws_security_group.echobase_ec2_sg01.id]
  iam_instance_profile   = aws_iam_instance_profile.echobase_instance_profile01.name

  # TODO: student supplies user_data to install app + CW agent + configure log shipping
  # added by Lonnie Hodges
  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "${local.name_prefix}-ec201"
  }
}

# added by Lonnie Hodges on 2026-01-17
# from bonus_a.tf
############################################
# Move EC2 into PRIVATE subnet (no public IP)
############################################

# Explanation: Echobase hates exposure—private subnets keep your compute off the public holonet.
resource "aws_instance" "echobase_ec201_private_bonus" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.echobase_private_subnets[0].id
  vpc_security_group_ids = [aws_security_group.echobase_ec2_sg01.id]
  iam_instance_profile   = aws_iam_instance_profile.echobase_instance_profile01.name

  # TODO: Students should remove/disable SSH inbound rules entirely and rely on SSM.
  # TODO: Students add user_data that installs app + CW agent; for true hard mode use a baked AMI.
  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "${local.echobase_prefix}-ec201-private"
  }
}
# ^^^ added by Lonnie Hodges on 2026-01-17

# added by Lonnie Hodges on 2026-01-17
# from bonus_b.tf
############################################
# Application Load Balancer
############################################

# Explanation: The ALB is your public customs checkpoint — it speaks TLS and forwards to private targets.
resource "aws_lb" "echobase_alb01" {
  name               = "${var.project_name}-alb01"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.echobase_alb_sg01.id]
  subnets         = aws_subnet.echobase_public_subnets[*].id

  # TODO: students can enable access logs to S3 as a stretch goal

  tags = {
    Name = "${var.project_name}-alb01"
  }
}

############################################
# Target Group + Attachment
############################################

# Explanation: Target groups are echobase’s “who do I forward to?” list — private EC2 lives here.
resource "aws_lb_target_group" "echobase_tg01" {
  name     = "${var.project_name}-tg01"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.echobase_vpc01.id

  # TODO: students set health check path to something real (e.g., /health)
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-tg01"
  }
}

# Explanation: echobase personally introduces the ALB to the private EC2 — “this is my friend, don’t shoot.”
resource "aws_lb_target_group_attachment" "echobase_tg_attach01" {
  target_group_arn = aws_lb_target_group.echobase_tg01.arn
  target_id        = aws_instance.echobase_ec201_private_bonus.id
  port             = 80

  # TODO: students ensure EC2 security group allows inbound from ALB SG on this port (rule above)
}

############################################
# ACM Certificate (TLS) for app.passportog.com or app.echobase.click
############################################

# Explanation: TLS is the diplomatic passport — browsers trust you, and echobase stops growling at plaintext.
resource "aws_acm_certificate" "echobase_acm_cert01" {
  domain_name       = local.echobase_fqdn
  validation_method = var.certificate_validation_method

  # TODO: students can add subject_alternative_names like var.domain_name if desired
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-acm-cert01"
  }
}

# added by Lonnie Hodges on 2026-01-17
data "aws_route53_zone" "echobase_zone_01" {
  name         = "echobase.click"
  private_zone = false
}

# Explanation: DNS validation records are the “prove you own the planet” ritual — Route53 makes this elegant.
# TODO: students implement aws_route53_record(s) if they manage DNS in Route53.
# resource "aws_route53_record" "echobase_acm_validation" { ... }
resource "aws_route53_record" "echobase_acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.echobase_acm_cert01.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.echobase_zone_01.id
}

resource "aws_route53_record" "app" {
  #zone_id = aws_route53_zone.echobase_zone_01.id
  zone_id = data.aws_route53_zone.echobase_zone_01.id
  name    = "app.echobase.click"
  type    = "A"
  alias {
    name = aws_lb.echobase_alb01.name
    zone_id = aws_lb.echobase_alb01.zone_id
    evaluate_target_health = true
  }
}

# Explanation: Once validated, ACM becomes the “green checkmark” — until then, ALB HTTPS won’t work.
resource "aws_acm_certificate_validation" "echobase_acm_validation01" {
  certificate_arn = aws_acm_certificate.echobase_acm_cert01.arn

  # TODO: if using DNS validation, students must pass validation_record_fqdns
  #validation_record_fqdns = [aws_route53_record.echobase_acm_validation.fqdn]
  validation_record_fqdns = [for record in aws_route53_record.echobase_acm_validation : record.fqdn]
}

############################################
# ALB Listeners: HTTP -> HTTPS redirect, HTTPS -> TG
############################################

# Explanation: HTTP listener is the decoy airlock — it redirects everyone to the secure entrance.
resource "aws_lb_listener" "echobase_http_listener01" {
  load_balancer_arn = aws_lb.echobase_alb01.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Explanation: HTTPS listener is the real hangar bay — TLS terminates here, then traffic goes to private targets.
resource "aws_lb_listener" "echobase_https_listener01" {
  load_balancer_arn = aws_lb.echobase_alb01.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.echobase_acm_validation01.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.echobase_tg01.arn
  }

  depends_on = [aws_acm_certificate_validation.echobase_acm_validation01]
}
# ^^^ added by Lonnie Hodges on 2026-01-17

############################################
# Parameter Store (SSM Parameters)
############################################

# Explanation: Parameter Store is Echobase’s map—endpoints and config live here for fast recovery.
resource "aws_ssm_parameter" "echobase_db_endpoint_param" {
  name  = "/lab/db/endpoint"
  type  = "String"
  value = aws_db_instance.echobase_rds01.address

  tags = {
    Name = "${local.name_prefix}-param-db-endpoint"
  }
}

# Explanation: Ports are boring, but even Wookiees need to know which door number to kick in.
resource "aws_ssm_parameter" "echobase_db_port_param" {
  name  = "/lab/db/port"
  type  = "String"
  value = tostring(aws_db_instance.echobase_rds01.port)

  tags = {
    Name = "${local.name_prefix}-param-db-port"
  }
}

# Explanation: DB name is the label on the crate—without it, you’re rummaging in the dark.
resource "aws_ssm_parameter" "echobase_db_name_param" {
  name  = "/lab/db/name"
  type  = "String"
  value = var.db_name

  tags = {
    Name = "${local.name_prefix}-param-db-name"
  }
}

############################################
# Secrets Manager (DB Credentials)
############################################

# Explanation: Secrets Manager is Echobase’s locked holster—credentials go here, not in code.
resource "aws_secretsmanager_secret" "echobase_db_secret01" {
  name = "${local.name_prefix}/rds/mysql"
  # added by Lonnie Hodges
  # When I run terraform destroy, I want to immediately destroy the secret.
  recovery_window_in_days = 0
}

# Explanation: Secret payload—students should align this structure with their app (and support rotation later).
resource "aws_secretsmanager_secret_version" "echobase_db_secret_version01" {
  secret_id = aws_secretsmanager_secret.echobase_db_secret01.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.echobase_rds01.address
    port     = aws_db_instance.echobase_rds01.port
    dbname   = var.db_name
  })
}

############################################
# CloudWatch Logs (Log Group)
############################################

# Explanation: When the Falcon is on fire, logs tell you *which* wire sparked—ship them centrally.
resource "aws_cloudwatch_log_group" "echobase_log_group01" {
  name              = "/aws/ec2/${local.name_prefix}-rds-app"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-log-group01"
  }
}

# added by Lonnie Hodges 2026-01-15
resource "aws_cloudwatch_log_stream" "echobase_log_stream01" {
  name           = "${local.name_prefix}-rds-app"
  log_group_name = aws_cloudwatch_log_group.echobase_log_group01.name
}

############################################
# Custom Metric + Alarm (Skeleton)
############################################
# Explanation: Metrics are Echobase’s growls—when they spike, something is wrong.
# NOTE: Students must emit the metric from app/agent; this just declares the alarm.
# Added by Lonnie Hodges:  https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/download-CloudWatch-Agent-on-EC2-Instance-commandline-first.html
resource "aws_cloudwatch_metric_alarm" "echobase_db_alarm01" {
  alarm_name          = "${local.name_prefix}-db-connection-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DBConnectionErrors"
  namespace           = "Lab/RDSApp"
  period              = 300
  statistic           = "Sum"
  threshold           = 3

  alarm_actions = [aws_sns_topic.echobase_sns_topic01.arn]

  tags = {
    Name = "${local.name_prefix}-alarm-db-fail"
  }
}

############################################
# SNS (PagerDuty simulation)
############################################

# Explanation: SNS is the distress beacon—when the DB dies, the galaxy (your inbox) must hear about it.
resource "aws_sns_topic" "echobase_sns_topic01" {
  name = "${local.name_prefix}-db-incidents"
}

# Explanation: Email subscription = “poor man’s PagerDuty”—still enough to wake you up at 3AM.
resource "aws_sns_topic_subscription" "echobase_sns_sub01" {
  topic_arn = aws_sns_topic.echobase_sns_topic01.arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoint
}

############################################
# (Optional but realistic) VPC Endpoints (Skeleton)
############################################

# Explanation: Endpoints keep traffic inside AWS like hyperspace lanes—less exposure, more control.
# TODO: students can add endpoints for SSM, Logs, Secrets Manager if doing “no public egress” variant.
# resource "aws_vpc_endpoint" "echobase_vpce_ssm" { ... }

