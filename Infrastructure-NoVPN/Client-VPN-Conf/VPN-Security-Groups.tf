# ─────────────────────────────────────────────
# Variables for referencing existing Security Groups
# ─────────────────────────────────────────────

# Security Group ID of the private host (no public internet access)
variable "privateHost_SecurityGroup_id" {
  type = string
}

# Security Group ID of the bastion host (has public internet access, so no VPN ingress rule needed for it here)
variable "bastionHost_SecurityGroup_id" {
  type = string
}

# ─────────────────────────────────────────────
# VPN Security Group Configuration
# Creates the security group and defines ingress/egress rules
# for the VPN server. Allows clients worldwide to connect,
# and allows the VPN to forward traffic to the bastion and private host.
# ─────────────────────────────────────────────

resource "aws_security_group" "VPN_Security_Group" {
  name   = "VPN-Security-Group"
  vpc_id = var.vpc_id
  tags = {
    Name = "VPN-Security-Group"
  }
}

# Allow all inbound traffic from anywhere.
# This is intentional — VPN clients can connect from any device or location worldwide.
resource "aws_vpc_security_group_ingress_rule" "VPN_Ingress_Rule" {
  description       = "Allow connections from any client worldwide"
  #from_port         = 0
  ip_protocol       = "-1"
  #to_port           = 0
  security_group_id = aws_security_group.VPN_Security_Group.id
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name = "VPN-IngressRule-SG"
  }
}

# Allow all outbound traffic to anywhere.
# This covers general internet access and also makes the two rules below redundant,
# but those are kept for explicitness and documentation purposes.
resource "aws_vpc_security_group_egress_rule" "VPN_Egress_Rule" {
  #from_port         = 0
  #to_port           = 0
  ip_protocol       = "-1"
  security_group_id = aws_security_group.VPN_Security_Group.id
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Name = "VPN-Egress-Rule-Internet"
  }
}

# Allow VPN to send UDP/443 traffic to the Bastion Host.
# Redundant given the broad egress rule above, but kept for clarity.
resource "aws_vpc_security_group_egress_rule" "VPN_Egress_Rule_BastionHost" {
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "udp"
  security_group_id            = aws_security_group.VPN_Security_Group.id
  referenced_security_group_id = var.bastionHost_SecurityGroup_id
  tags = {
    Name = "VPN-Egress-Rule-BastionHost"
  }
}

# Allow VPN to send UDP/443 traffic to the Private Host.
# Redundant given the broad egress rule above, but kept for clarity.
resource "aws_vpc_security_group_egress_rule" "VPN_Egress_Rule_PrivateHost" {
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "udp"
  security_group_id            = aws_security_group.VPN_Security_Group.id
  referenced_security_group_id = var.privateHost_SecurityGroup_id
  tags = {
    Name = "VPN-Egress-Rule-PrivateHost"
  }
}

# ─────────────────────────────────────────────
# Private Host Ingress Rules
# The private host has no public internet access, so all traffic comes through the VPN.
# Two rules are needed:
#   1. UDP/443 — allows the VPN tunnel to be established
#   2. TCP/22  — allows SSH traffic that flows inside the VPN tunnel
# ─────────────────────────────────────────────

# Allows the VPN tunnel (UDP/443) to reach the private host.
# Source is the VPN Security Group, not a CIDR, so only VPN server traffic is accepted.
resource "aws_vpc_security_group_ingress_rule" "PrivateHostIngress_VPN" {
  description                  = "Allow VPN tunnel (UDP/443) from VPN Security Group to Private Host"
  from_port                    = 443
  ip_protocol                  = "udp"
  to_port                      = 443
  security_group_id            = var.privateHost_SecurityGroup_id
  referenced_security_group_id = aws_security_group.VPN_Security_Group.id  # Only accept traffic originating from the VPN SG
  tags = {
    Name = "IngressRule_PrivateHost_SG_VPN"
  }
}

# Allows SSH (TCP/22) from the VPN Security Group to the private host.
# Once the VPN tunnel is established, clients SSH into the private host through it.
# Source is the VPN Security Group to ensure only tunneled traffic is accepted.
resource "aws_vpc_security_group_ingress_rule" "PrivateHostIngress_SSH" {
  description                  = "Allow SSH (TCP/22) from VPN Security Group to Private Host"
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
  security_group_id            = var.privateHost_SecurityGroup_id
  referenced_security_group_id = aws_security_group.VPN_Security_Group.id  # Only accept SSH that comes through the VPN
  tags = {
    Name = "IngressRule_PrivateHost_SG_SSH"
  }
}

# ─────────────────────────────────────────────
# Bastion Host -Private Ip- Ingress Rules
# The private host has no public internet access, so all traffic comes through the VPN.
# Two rules are needed:
#   1. UDP/443 — allows the VPN tunnel to be established
#   2. TCP/22  — allows SSH traffic that flows inside the VPN tunnel
# ─────────────────────────────────────────────


resource "aws_vpc_security_group_ingress_rule" "BastionHostIngress_VPN" {
  description                  = "Allow VPN tunnel (UDP/443) from VPN Security Group to Private Host"
  from_port                    = 443
  ip_protocol                  = "udp"
  to_port                      = 443
  security_group_id            = var.bastionHost_SecurityGroup_id
  referenced_security_group_id = aws_security_group.VPN_Security_Group.id  # Only accept traffic originating from the VPN SG
  tags = {
    Name = "IngressRule_BastionHost_Private_SG_VPN"
  }
}

resource "aws_vpc_security_group_ingress_rule" "BastionHostIngress_8080" {
  #cidr_ipv4  = "10.0.0.0/22"  # VPN client CIDR
  description = "Jenkins access from VPN clients"
  from_port = 8080
  ip_protocol = "tcp"
  to_port = 8080
  security_group_id = var.bastionHost_SecurityGroup_id
  referenced_security_group_id = aws_security_group.VPN_Security_Group.id  # Return 8080 TCP traffic goes back through the VPN SG

  tags = {
    Name = "IngressRule_BastionHost_SG_8080"
  }
}

# Allows SSH (TCP/22) from the VPN Security Group to the private host.
# Once the VPN tunnel is established, clients SSH into the private host through it.
# Source is the VPN Security Group to ensure only tunneled traffic is accepted.
resource "aws_vpc_security_group_ingress_rule" "BastionHostIngress_SSH" {
  description                  = "Allow SSH (TCP/22) from VPN Security Group to Private Host"
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
  security_group_id            = var.bastionHost_SecurityGroup_id
  referenced_security_group_id = aws_security_group.VPN_Security_Group.id  # Only accept SSH that comes through the VPN
  tags = {
    Name = "IngressRule_BastionHost_Private_SG_SSH"
  }
}

# ─────────────────────────────────────────────
# Private Host Egress Rule
# Allows the private host to respond to SSH sessions back through the VPN.
# TCP/22 egress to the VPN Security Group covers SSH return traffic.
# ─────────────────────────────────────────────

# Allows the private host to send SSH return traffic (TCP/22) back to the VPN Security Group.
# This is the response side of the SSH connection initiated by the client through the VPN.
resource "aws_vpc_security_group_egress_rule" "PrivateHostEgress_VPN" {
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  security_group_id            = var.privateHost_SecurityGroup_id
  referenced_security_group_id = aws_security_group.VPN_Security_Group.id  # Return SSH traffic goes back through the VPN SG
}

# ─────────────────────────────────────────────
# Bastion Host -Private Ip- Egress Rule
# Allows the private host to respond to SSH sessions back through the VPN.
# TCP/22 egress to the VPN Security Group covers SSH return traffic.
# ─────────────────────────────────────────────


resource "aws_vpc_security_group_egress_rule" "BastionHostEgress_VPN" {
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  security_group_id            = var.bastionHost_SecurityGroup_id
  referenced_security_group_id = aws_security_group.VPN_Security_Group.id  # Return SSH traffic goes back through the VPN SG
}

resource "aws_vpc_security_group_egress_rule" "BastionHostEgress_8080" {
  description                  = "Allow Jenkins response traffic back through VPN"
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
  security_group_id            = var.bastionHost_SecurityGroup_id
  referenced_security_group_id = aws_security_group.VPN_Security_Group.id
  tags = {
    Name = "EgressRule_BastionHost_SG_8080"
  }
}


