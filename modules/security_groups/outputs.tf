output "security_group_ids" {
  description = "IDs of the security groups"
  value = {
    "imperial_security"   = aws_security_group.imperial_security.id
    "rebel_security"     = aws_security_group.rebel_security.id
    "mandalorian_security" = aws_security_group.mandalorian_security.id
  }
}
