resource "aws_cloudwatch_log_group" "jenkins_log_group" {
  name              = "/ecs/jenkins/${var.project_environment}"
  retention_in_days = 30

  tags = {
    Environment = "${var.project_environment}"
    ManagedBy   = "terraform"
    Name        = "Jenkins-log-group"
  }
}

resource "aws_cloudwatch_log_group" "garafana_log_group" {
  name              = "/ecs/garafana/${var.project_environment}"
  retention_in_days = 30

  tags = {
    Environment = "${var.project_environment}"
    ManagedBy   = "terraform"
    Name        = "Garafana-log-group"
  }
}