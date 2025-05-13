variable "environment_name" {
  type        = string
  description = "Environment name for tagging resources"
}

variable "monitored_instances" {
  type        = list(string)
  description = "List of EC2 instance IDs to monitor"
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  for_each = toset(var.monitored_instances)

  alarm_name          = "${var.environment_name}-${each.key}-HighCPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when CPU exceeds 80% for ${each.key}"
  alarm_actions       = []  # Add SNS topic ARN if desired
  ok_actions          = []
  insufficient_data_actions = []
  dimensions = {
    InstanceId = each.value
  }
}
