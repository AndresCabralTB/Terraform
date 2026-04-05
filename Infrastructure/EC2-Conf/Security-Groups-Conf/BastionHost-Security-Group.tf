variable "vpc_id" {
  type = string
}

variable "cidr_ipv4_mac" {
  type = string
}

variable "privateHost_private_ip" {
  type = string
}

resource "aws_security_group" "BastionHostSG" {
    name = "Bastion-Host-Security-Group"
    vpc_id = var.vpc_id
    description = "Security Group for the Bastion Host"

    tags = {
      Name = "Bastion-Host-Security-Group"
    }
}

resource "aws_vpc_security_group_ingress_rule" "BastionHostIngress" {
  cidr_ipv4 = var.cidr_ipv4_mac
  description = "Allow connections from Mac"
  from_port = 22
  ip_protocol = "tcp"
  to_port = 22
  security_group_id = aws_security_group.BastionHostSG.id

  tags = {
    Name = "IngressRule_BastionHost_SG"
  }
}

resource "aws_vpc_security_group_egress_rule" "BastionHostEgress" {
    cidr_ipv4 = "0.0.0.0/0" # Allow connection to access the internet
    ip_protocol = "-1"
    security_group_id = aws_security_group.BastionHostSG.id
    #referenced_security_group_id = aws_security_group.PrivateHostSG.id
}

output "BastionHostSecurityGroup_Output" {
  value = aws_security_group.BastionHostSG
}