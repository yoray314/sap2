resource "aws_sns_topic" "alerts" {
  name = "${var.project}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ALB 5XX spike alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# Healthy host count below redundancy (expect 2 healthy)
resource "aws_cloudwatch_metric_alarm" "alb_low_healthy" {
  alarm_name          = "${var.project}-alb-low-healthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 2
  treat_missing_data  = "breaching"
  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.web.arn_suffix
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}

# RDS free storage alarm (warn early)
resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${var.project}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  # ~1 GB threshold
  threshold          = 1000000000
  treat_missing_data = "notBreaching"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}