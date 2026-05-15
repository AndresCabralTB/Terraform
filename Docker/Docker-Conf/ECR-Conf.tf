variable "project_environment" {
    type = string
}

resource "aws_ecr_repository" "ecr_repo"{
    name    = "ecr-repo-${var.project_environment}"
    image_tag_mutability = "IMMUTABLE"
    image_scanning_configuration {
        scan_on_push = true
    }
}