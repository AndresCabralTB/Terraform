variable "db_username" {
  type = string
  sensitive = true
}

variable "db_password" {
  type = string
  sensitive = true
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "project-db-credentials-${var.project_version}"
  tags = {
    Environment = "PROD"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
    secret_id = aws_secretsmanager_secret.db_credentials.id
    secret_string = jsonencode({
        username = var.db_username
        password = var.db_password
    })
}