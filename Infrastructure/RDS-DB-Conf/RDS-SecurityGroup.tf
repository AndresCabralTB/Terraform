variable "vpc_id" {
  type = string
}

variable "PrivateHostSG_ID" {
  type = string
}

resource "aws_security_group" "TerraformDB-SecurityGroup" {
    name = "Terraform-Database-Security-Group-${var.project_version}"
    vpc_id = var.vpc_id
    description = "Security Group for the RDS Terraform Database"

    tags = {
      Name = "Terraform-Database-Security-Group-${var.project_version}"
    }
}

resource "aws_vpc_security_group_ingress_rule" "TerraformDBIngress" {
  description = "Allow connections from Private Host Security Group"
  from_port = 3306
  ip_protocol = "tcp"
  to_port = 3306
  security_group_id = aws_security_group.TerraformDB-SecurityGroup.id
  referenced_security_group_id = var.PrivateHostSG_ID   

  tags = {
    Name = "IngressRule-TerraformDB-SG-${var.project_version}"
  }
}

#Egress rule not required yet
#resource "aws_vpc_security_group_egress_rule" "TerraformDBEgress" {
#    cidr_ipv4 = "0.0.0.0/0" # Allow connection to access the internet
#    ip_protocol = "-1"
#    security_group_id = aws_security_group.BastionHostSG.id
#    #referenced_security_group_id = aws_security_group.PrivateHostSG.id
#}

output "TerraformDB_SecurityGroup_Output_id" {
  value = aws_security_group.TerraformDB-SecurityGroup.id
}
