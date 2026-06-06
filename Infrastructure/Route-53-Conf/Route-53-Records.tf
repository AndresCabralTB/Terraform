variable "bastionhost_private_ip" {
  type = string
}

variable "privatehost_private_ip" {
  type = string
}

variable "deploy_private_resources"{
  type = string
}

locals {
  BastionHostName = "BastionHost.${var.project_environment}" #The record name will be: bastionhost.cabral.cloud
  PrivateHostName = "PrivateHost.${var.project_environment}" #The record name will be: privatehost.cabral.cloud
}


resource "aws_route53_record" "bastionhost_route53_record" {
  zone_id   = aws_route53_zone.Route53-Zone-A-Terraform.id
  name      = local.BastionHostName
  type      = "A"
  ttl       = 300
  records   = [var.bastionhost_private_ip]
}

resource "aws_route53_record" "privatehost_route53_record" {
  count     = var.deploy_private_resources ? 1 : 0
  zone_id   = aws_route53_zone.Route53-Zone-A-Terraform.id
  name      = local.PrivateHostName
  type      = "A"
  ttl       = 300
  records   = [var.privatehost_private_ip]
}
