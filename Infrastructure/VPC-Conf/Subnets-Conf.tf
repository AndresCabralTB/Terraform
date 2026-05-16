
resource "aws_subnet" "VPC_Subnet_A" {
  availability_zone                             = "us-east-1a"
  cidr_block                                    = "172.16.0.0/27"
  #"172.16.50.0/12"
  enable_resource_name_dns_a_record_on_launch   = true
  map_public_ip_on_launch                       = true
  vpc_id = aws_vpc.VPC_Terraform.id #VPC is made inside the same module. Therefore, it can be referenced as such

  tags = {
    Name = "VPC-Subnet-A-Terraform-${var.project_environment}"
  }
}

resource "aws_subnet" "VPC_Subnet_B" {
  availability_zone                             = "us-east-1b"
  cidr_block                                    = "172.16.0.32/27"
  #"172.16.50.0/12"
  enable_resource_name_dns_a_record_on_launch   = false
  map_public_ip_on_launch                       = false
  vpc_id = aws_vpc.VPC_Terraform.id #VPC is made inside the same module. Therefore, it can be referenced as such

  tags = {
    Name = "VPC-Subnet-B-Terraform-${var.project_environment}"
  }
}

resource "aws_subnet" "VPC_Subnet_C" {
  availability_zone                             = "us-east-1c"
  cidr_block                                    = "172.16.0.64/27"
  #"172.16.50.0/12"
  enable_resource_name_dns_a_record_on_launch   = false
  map_public_ip_on_launch                       = false
  vpc_id = aws_vpc.VPC_Terraform.id #VPC is made inside the same module. Therefore, it can be referenced as such

  tags = {
    Name = "VPC-Subnet-C-Terraform-${var.project_environment}"
  }
}

output "VPC_Subnet_A_Output" {
  value = aws_subnet.VPC_Subnet_A
}


output "VPC_Subnet_B_Output" {
  value = aws_subnet.VPC_Subnet_B
}

output "VPC_Subnet_C_Output" {
  value = aws_subnet.VPC_Subnet_C
}