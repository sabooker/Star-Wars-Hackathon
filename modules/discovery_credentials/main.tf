# AWS Secrets Manager for storing discovery credentials
resource "aws_secretsmanager_secret" "windows_credentials" {
  name        = "${var.environment}-windows-discovery-credentials"
  description = "Credentials for Windows server discovery"
}

resource "aws_secretsmanager_secret_version" "windows_credentials" {
  secret_id     = aws_secretsmanager_secret.windows_credentials.id
  secret_string = jsonencode({
    local_admin_username = "empire-discovery-admin",
    local_admin_password = "Emp1reD1sc0v3ryP@ss!",
    domain_admin_username = "darth-vader",
    domain_admin_password = "Emp1reP@ss123!"
  })
}

resource "aws_secretsmanager_secret" "linux_credentials" {
  name        = "${var.environment}-linux-discovery-credentials"
  description = "Credentials for Linux server discovery"
}

resource "aws_secretsmanager_secret_version" "linux_credentials" {
  secret_id     = aws_secretsmanager_secret.linux_credentials.id
  secret_string = jsonencode({
    username = "rebel-discovery-user",
    password = "R3belD1sc0v3ryP@ss!",
    ssh_key_passphrase = "R3belK3yP@ss!"
  })
}

resource "aws_secretsmanager_secret" "network_credentials" {
  name        = "${var.environment}-network-discovery-credentials"
  description = "Credentials for network device discovery"
}

resource "aws_secretsmanager_secret_version" "network_credentials" {
  secret_id     = aws_secretsmanager_secret.network_credentials.id
  secret_string = jsonencode({
    snmp_community = "GalacticDiscovery",
    snmp_v3_user = "jedi-snmp-user",
    snmp_v3_auth_password = "J3d1AuthP@ss!",
    snmp_v3_priv_password = "J3d1PrivP@ss!",
    ssh_username = "network-jedi",
    ssh_password = "N3tw0rkJ3d1P@ss!"
  })
}

resource "aws_secretsmanager_secret" "database_credentials" {
  name        = "${var.environment}-database-discovery-credentials"
  description = "Credentials for database discovery"
}

resource "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id     = aws_secretsmanager_secret.database_credentials.id
  secret_string = jsonencode({
    sql_server_username = "death-star-sql-admin",
    sql_server_password = "D3@thSt@rSQL!",
    oracle_username = "jedi-oracle-admin",
    oracle_password = "J3d10r@cl3P@ss!"
  })
}

# IAM Role and Policy for the MID Server to access Secrets Manager
resource "aws_iam_role" "mid_server_role" {
  name = "${var.environment}-mid-server-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "mid_server_policy" {
  name        = "${var.environment}-mid-server-policy"
  description = "Policy for MID Server to access secrets"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect = "Allow"
        Resource = [
          aws_secretsmanager_secret.windows_credentials.arn,
          aws_secretsmanager_secret.linux_credentials.arn,
          aws_secretsmanager_secret.network_credentials.arn,
          aws_secretsmanager_secret.database_credentials.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "mid_server_policy_attachment" {
  role       = aws_iam_role.mid_server_role.name
  policy_arn = aws_iam_policy.mid_server_policy.arn
}

resource "aws_iam_instance_profile" "mid_server_profile" {
  name = "${var.environment}-mid-server-profile"
  role = aws_iam_role.mid_server_role.name
}
