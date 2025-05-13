# Outputs
output "windows_security_group_id" {
  description = "Security group ID for Windows servers"
  value       = aws_security_group.windows_security.id
}

output "linux_security_group_id" {
  description = "Security group ID for Linux servers"
  value       = aws_security_group.linux_security.id
}

output "database_security_group_id" {
  description = "Security group ID for database servers"
  value       = aws_security_group.database_security.id
}

output "mid_server_security_group_id" {
  description = "Security group ID for MID Server"
  value       = aws_security_group.mid_server_security.id
}

output "monitoring_security_group_id" {
  description = "Security group ID for monitoring servers"
  value       = aws_security_group.monitoring_security.id
}

output "alb_security_group_id" {
  description = "Security group ID for Application Load Balancers"
  value       = aws_security_group.alb_security.id
}