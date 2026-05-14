variable "project_version" {
    type = string
}

variable "vpc_id" {
  type = string
}

resource "aws_route53_zone" "Route53-Zone-A-Terraform"{
  name = "cabral.cloud.${var.project_version}"
  vpc {
    vpc_id = var.vpc_id
  }
}