variable "TerraformDB_SecurityGroup_Id" {
  type = string
}

variable "deploy_private_resources"{
  type = bool
}

# ─────────────────────────────────────────────
# Private Host Security Group
# Defines inbound and outbound rules for the private host.
#
# Note: The ingress rule allowing the VPN to reach this host (UDP/443),
# and the egress rule allowing this host to respond to the VPN (TCP/22),
# are defined in Infrastructure/Client-VPN-Conf/VPN-Security-Groups.tf
# ─────────────────────────────────────────────

resource "aws_security_group" "PrivateHostSG" {
  count   = var.deploy_private_resources ? 1 : 0
  name    = "Private-Host-Security-Group-${var.project_environment}"
  vpc_id  = var.vpc_id
  tags    = {
    Name = "Private-Host-Security-Group-${var.project_environment}"
  }
}

# Allow SSH from the Bastion Host only.
# Users SSH into the bastion first, then jump to this private host.
# No direct public SSH access is permitted.
resource "aws_vpc_security_group_ingress_rule" "PrivateHostIngress" {
  count   = var.deploy_private_resources ? 1 : 0
  description                  = "Allow SSH connections from Bastion Host - ${var.project_environment}"
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
  security_group_id            = aws_security_group.PrivateHostSG[count.index].id
  referenced_security_group_id = aws_security_group.BastionHostSG[count.index].id
  tags = {
    Name = "IngressRule-PrivateHost-SG-${var.project_environment}"
  }
}

# Allow the private host to reach the database on port 3306 (MySQL/Aurora).
# Scoped to the DB security group only — no broad outbound access.
resource "aws_vpc_security_group_egress_rule" "PrivateHostEgress" {
  count   = var.deploy_private_resources ? 1 : 0
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.PrivateHostSG[count.index].id
  referenced_security_group_id = var.TerraformDB_SecurityGroup_Id
}

# Output the Private Host SG ID so it can be referenced by other modules,
# such as the VPN and DB security group configurations.
output "PrivateHostSecurityGroup_Id_Output" {
  value = one(aws_security_group.PrivateHostSG[*].id)
}