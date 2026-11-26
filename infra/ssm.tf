# infra/ssm.tf (values Serverless Framework reads with ${ssm:...})
locals {
  ssm_params = {
    "lambda-sg-id"     = aws_security_group.lambda.id
    "private-subnet-1" = aws_subnet.private[0].id
    "private-subnet-2" = aws_subnet.private[1].id
    "db-secret-arn"    = aws_db_instance.postgres.master_user_secret[0].secret_arn
    "db-host"          = aws_db_instance.postgres.address
    "db-name"          = var.db_name
  }
}

resource "aws_ssm_parameter" "bridge" {
  for_each = local.ssm_params
  name     = "/${var.project_name}/${var.environment}/${each.key}"
  type     = "String"
  value    = each.value
}