resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

locals {
  alarms = {
    lambda-errors = {
      ns        = "AWS/Lambda"
      metric    = "Errors"
      stat      = "Sum"
      op        = "GreaterThanThreshold"
      threshold = 0
      dims      = tomap({ FunctionName = local.lambda_name })
    }
    ecs-cpu = {
      ns        = "AWS/ECS"
      metric    = "CPUUtilization"
      stat      = "Average"
      op        = "GreaterThanThreshold"
      threshold = 80
      dims      = tomap({ ClusterName = aws_ecs_cluster.main.name, ServiceName = aws_ecs_service.graphql.name })
    }
    alb-5xx = {
      ns        = "AWS/ApplicationELB"
      metric    = "HTTPCode_Target_5XX_Count"
      stat      = "Sum"
      op        = "GreaterThanThreshold"
      threshold = 5
      dims      = tomap({ LoadBalancer = aws_lb.graphql.arn_suffix })
    }
    rds-cpu = {
      ns        = "AWS/RDS"
      metric    = "CPUUtilization"
      stat      = "Average"
      op        = "GreaterThanThreshold"
      threshold = 80
      dims      = tomap({ DBInstanceIdentifier = aws_db_instance.postgres.identifier })
    }
    rds-connections = {
      ns        = "AWS/RDS"
      metric    = "DatabaseConnections"
      stat      = "Average"
      op        = "GreaterThanThreshold"
      threshold = 80
      dims      = tomap({ DBInstanceIdentifier = aws_db_instance.postgres.identifier })
    }
    rds-low-storage = {
      ns        = "AWS/RDS"
      metric    = "FreeStorageSpace"
      stat      = "Minimum"
      op        = "LessThanThreshold"
      threshold = 2000000000
      dims      = tomap({ DBInstanceIdentifier = aws_db_instance.postgres.identifier })
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm" {
  for_each            = local.alarms
  alarm_name          = "${var.project_name}-${each.key}"
  namespace           = each.value.ns
  metric_name         = each.value.metric
  statistic           = each.value.stat
  comparison_operator = each.value.op
  threshold           = each.value.threshold
  dimensions          = each.value.dims
  period              = 60
  evaluation_periods  = 2
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}