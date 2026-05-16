variable "project_environment" {
    type = string
}
resource "aws_vpc" "VPC_Terraform" {
  cidr_block            = "172.16.0.0/24" 
  enable_dns_support    = true
  enable_dns_hostnames  = true

  tags = {
    Name = "VPC-Terraform-${var.project_environment}"
  }
}

output "VPC_Terraform_Output" {
  value = aws_vpc.VPC_Terraform
}