variable "vpc_id" {
  type = string
}

variable "cidr_ipv4_mac" {
  type = string
}

variable "project_environment" {
  type = string
}


resource "aws_security_group" "BastionHostSG" {
    name = "Bastion-Host-Security-Group-${var.project_environment}"
    vpc_id = var.vpc_id
    description = "Security Group for the Bastion Host - ${var.project_environment}"

    tags = {
      Name = "Bastion-Host-Security-Group-${var.project_environment}"
    }
}

resource "aws_vpc_security_group_ingress_rule" "BastionHostIngress" {
  cidr_ipv4 = var.cidr_ipv4_mac
  description = "Allow connections from Mac - ${var.project_environment}"
  from_port = 22
  ip_protocol = "tcp"
  to_port = 22
  security_group_id = aws_security_group.BastionHostSG.id

  tags = {
    Name = "IngressRule-BastionHost-SG--${var.project_environment}"
  }
}
resource "aws_vpc_security_group_egress_rule" "BastionHostEgress" {
    cidr_ipv4 = "0.0.0.0/0" # Allow connection to access the internet
    ip_protocol = "-1"
    security_group_id = aws_security_group.BastionHostSG.id
    #referenced_security_group_id = aws_security_group.PrivateHostSG.id
    tags = {
      Name = "EgressRule-BastionHost-SG-${var.project_environment}"
    }
}

output "BastionHostSecurityGroup_Id_Output" {
  value = aws_security_group.BastionHostSG.id
}