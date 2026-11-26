resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Load balancer: only CloudFront may connect"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "GraphQL containers: only the load balancer may connect"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-lambda-sg"
  description = "Database Lambda: no inbound at all"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Database: only the Lambda may connect"
  vpc_id      = aws_vpc.main.id
}

# THE TABLE: one line one allowed connection (from -> to: port)
locals {
  sg_links = {
    alb_to_ecs    = { from = aws_security_group.alb.id, to = aws_security_group.ecs.id, port = 4000 }
    lambda_to_rds = { from = aws_security_group.lambda.id, to = aws_security_group.rds.id, port = 5432 }
  }
}

resource "aws_vpc_security_group_ingress_rule" "link_in" {
  for_each                     = local.sg_links
  security_group_id            = each.value.to
  referenced_security_group_id = each.value.from
  ip_protocol                  = "tcp"
  from_port                    = each.value.port
  to_port                      = each.value.port
}

resource "aws_vpc_security_group_egress_rule" "link_out" {
  for_each                     = local.sg_links
  security_group_id            = each.value.from
  referenced_security_group_id = each.value.to
  ip_protocol                  = "tcp"
  from_port                    = each.value.port
  to_port                      = each.value.port
}

# Public side: only CloudFront's published address list may reach the load balancer
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_cloudfront" {
  security_group_id = aws_security_group.alb.id
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

# ECS and Lambda call AWS APIs (ECR, Secrets Manager, CloudWatch, Lambda) over HTTPS through the NAT
resource "aws_vpc_security_group_egress_rule" "https_out" {
  for_each          = { ecs = aws_security_group.ecs.id, lambda = aws_security_group.lambda.id }
  security_group_id = each.value
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}