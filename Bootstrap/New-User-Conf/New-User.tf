variable "infrastructure_user" {
    type = string
} 

variable "docker_user" {
    type = string
} 

variable "project_environment" {
    type = string
} 

resource "aws_iam_user" "infrastructure_user" {
    name = "${var.infrastructure_user}-${var.project_environment}"
}

resource "aws_iam_user" "docker_user" {
    name = "${var.docker_user}-${var.project_environment}"
}

output "infrastructure_user_output" {
    value = aws_iam_user.infrastructure_user.name
}

output "docker_user_output" {
    value = aws_iam_user.docker_user.name
}