output "alarm_names" {
  value = [for alarm in aws_cloudwatch_metric_alarm.cpu_utilization : alarm.alarm_name]
}