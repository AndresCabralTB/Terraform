variable "TerraformDB_SecurityGroup_Id" {
  type = string
}

resource "aws_security_group" "PrivateHostSG" {
    name = "Private-Host-Security-Group"
    vpc_id = var.vpc_id
    tags = {
      Name = "Private-Host-Security-Group"
    }
}

resource "aws_vpc_security_group_ingress_rule" "PrivateHostIngress" {
  #cidr_ipv4 = var.cidr_ipv4_mac - Not needed because we reference the security group from the Bastion Host
  description = "Allow connections from Mac"
  from_port = 22
  ip_protocol = "tcp"
  to_port = 22
  security_group_id = aws_security_group.PrivateHostSG.id
  referenced_security_group_id = aws_security_group.BastionHostSG.id

  tags = {
    Name = "IngressRule_BastionHost_SG"
  }
}

# Commented out because there is no database to connec to yet
resource "aws_vpc_security_group_egress_rule" "PrivateHostEgress" {    
    from_port = 3306
    to_port = 3306
    ip_protocol = "tcp"
    security_group_id = aws_security_group.PrivateHostSG.id
    referenced_security_group_id = var.TerraformDB_SecurityGroup_Id
}

output "PrivateHostSecurityGroup_Output" {
  value = aws_security_group.PrivateHostSG
}