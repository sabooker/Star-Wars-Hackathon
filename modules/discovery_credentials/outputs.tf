output "windows_credentials_secret_arn" {
  description = "ARN of the Windows credentials secret"
  value       = aws_secretsmanager_secret.windows_credentials.arn
}

output "linux_credentials_secret_arn" {
  description = "ARN of the Linux credentials secret"
  value       = aws_secretsmanager_secret.linux_credentials.arn
}

output "network_credentials_secret_arn" {
  description = "ARN of the network credentials secret"
  value       = aws_secretsmanager_secret.network_credentials.arn
}

output "database_credentials_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.database_credentials.arn
}

output "mid_server_instance_profile" {
  description = "Instance profile for the MID Server"
  value       = aws_iam_instance_profile.mid_server_profile.name
}
