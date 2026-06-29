resource "aws_cloudwatch_log_group" "jenkins_log_group" {
  name              = "/ecs/jenkins/${var.project_environment}"
  retention_in_days = 30

  tags = {
    Environment = "${var.project_environment}"
    ManagedBy   = "terraform"
    Name        = "Jenkins-log-group"
  }
}

resource "aws_cloudwatch_log_group" "grafana_log_group" {
  name              = "/ecs/grafana/${var.project_environment}"
  retention_in_days = 30
  count           = var.enable_grafana ? 1 : 0

  tags = {
    Environment = "${var.project_environment}"
    ManagedBy   = "terraform"
    Name        = "Grafana-log-group"
  }
}