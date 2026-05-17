variable "new_username" {
    type = string
} 

variable "project_environment" {
    type = string
} 

resource "aws_iam_user" "new_user" {
    name = "${var.new_username}-${var.project_environment}"
}

output "new_user_output" {
    value = aws_iam_user.new_user.name
}