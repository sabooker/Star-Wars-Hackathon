output "windows_alb_dns_name" {
  value = aws_lb.windows_alb.dns_name
}

output "linux_alb_dns_name" {
  value = aws_lb.linux_alb.dns_name
}
