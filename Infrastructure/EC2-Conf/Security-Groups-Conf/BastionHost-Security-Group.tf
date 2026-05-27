variable "vpc_id" {
  type = string
}

variable "allowed_hosts" {
  type = list
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
    for_each = toset(var.allowed_hosts)
    cidr_ipv4 = each.key
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

resource "aws_vpc_security_group_ingress_rule" "EFSIngress" {
    cidr_ipv4 = "0.0.0.0/0"
    description = "Allow connections for EFS"
    from_port = 2049
    to_port = 2049
    ip_protocol = "tcp"
    security_group_id = aws_security_group.BastionHostSG.id

    tags = {
        Name = "EFS-IngressRule-BastionHost-SG--${var.project_environment}"
    }
}

resource "aws_vpc_security_group_egress_rule" "EFSEgress" {
    cidr_ipv4 = "0.0.0.0/0" # Allow connection to access the internet
    description = "Allow connections for EFS"
    from_port = 2049
    to_port = 2049
    ip_protocol = "tcp"
    security_group_id = aws_security_group.BastionHostSG.id
    #referenced_security_group_id = aws_security_group.PrivateHostSG.id
    tags = {
      Name = "EFS-EgressRule-BastionHost-SG-${var.project_environment}"
    }
}

output "BastionHostSecurityGroup_Id_Output" {
  value = aws_security_group.BastionHostSG.id
}