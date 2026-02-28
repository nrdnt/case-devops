# Logging & Alerts: SNS topic, CloudWatch alarm, opsiyonel e-posta bildirimi

resource "aws_sns_topic" "alerts" {
  name = "${var.cluster_name}-alerts"
  tags = {
    Name        = "${var.cluster_name}-alerts"
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "alert_email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# EKS node failure veya kritik durumda alarm
resource "aws_cloudwatch_metric_alarm" "eks_failed_node" {
  alarm_name          = "${var.cluster_name}-failed-node"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "cluster_failed_node_count"
  namespace           = "AWS/EKS"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "EKS cluster'da en az bir node failed durumda"
  alarm_actions        = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = aws_eks_cluster.main.name
  }

  tags = {
    Environment = var.environment
  }
}
