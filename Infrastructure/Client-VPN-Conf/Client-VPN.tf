# ─────────────────────────────────────────────
# VARIABLES
# ─────────────────────────────────────────────
variable "subnet_A_id" {
  type = string
}
variable "subnet_A_cidr" {
  type = string
}
variable "subnet_B_id" {
  type = string
}
variable "subnet_B_cidr" {
  type = string
}
variable "vpn_users" {
  type    = list(string)
  default = ["alice", "bob"]
}

# ─────────────────────────────────────────────
# CA
# ─────────────────────────────────────────────

# Generate CA private key
resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Generate CA certificate
resource "tls_self_signed_cert" "ca" {
  private_key_pem       = tls_private_key.ca.private_key_pem
  validity_period_hours = 87600 # 10 years
  is_ca_certificate     = true

  subject {
    common_name = "ca.cabral.cloud"  # Use a proper domain
    organization = "ca.cabral.cloud"  # ADD THIS
  }

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

# ─────────────────────────────────────────────
# SERVER CERTIFICATE
# ─────────────────────────────────────────────

# Generate server private key
resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server" {
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name = "server.cabral.cloud"  # Use a proper domain
    organization = "cabral.cloud"  # ADD THIS
  }

  dns_names = ["server.cabral.cloud"]  # ADD THIS
}

# Generate server certificate signed by CA
resource "tls_locally_signed_cert" "server" {
  cert_request_pem      = tls_cert_request.server.cert_request_pem
  ca_private_key_pem    = tls_private_key.ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca.cert_pem
  validity_period_hours = 87600

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Upload server cert to ACM
resource "aws_acm_certificate" "server" {
  private_key       = tls_private_key.server.private_key_pem
  certificate_body  = tls_locally_signed_cert.server.cert_pem
  certificate_chain = tls_self_signed_cert.ca.cert_pem
}

# Upload CA cert to ACM (used as client root CA)
resource "aws_acm_certificate" "ca" {
  private_key      = tls_private_key.ca.private_key_pem
  certificate_body = tls_self_signed_cert.ca.cert_pem
}

# ─────────────────────────────────────────────
# CLIENT CERTIFICATES (one per user)
# ─────────────────────────────────────────────
resource "tls_private_key" "client" {
  for_each  = toset(var.vpn_users)
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client" {
  for_each        = toset(var.vpn_users)
  private_key_pem = tls_private_key.client[each.key].private_key_pem

  subject {
    common_name = "${each.key}.cabral.cloud"  # Use a proper domain
    organization = "cabral.cloud"  # ADD THIS
  }

  dns_names = ["${each.key}.cabral.cloud"]  # ADD THIS
}

resource "tls_locally_signed_cert" "client" {
  for_each              = toset(var.vpn_users)
  cert_request_pem      = tls_cert_request.client[each.key].cert_request_pem
  ca_private_key_pem    = tls_private_key.ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca.cert_pem
  validity_period_hours = 17520 # 2 years

  allowed_uses = [
    "digital_signature",
    "client_auth",
  ]
}

# ─────────────────────────────────────────────
# VPN ENDPOINT
# ─────────────────────────────────────────────

# The Client VPN endpoint is the resource that you create and configure to enable and manage client VPN sessions. It's the termination point for all client VPN sessions.
resource "aws_ec2_client_vpn_endpoint" "ClientVPN_Endpoint" {
  description            = "terraform-clientvpn"
  server_certificate_arn = aws_acm_certificate.server.arn

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.ca.arn
  }

  connection_log_options {
    enabled = false
  }

  # Routes only VPC-bound traffic through the VPN tunnel; all other internet traffic goes directly from the client
  split_tunnel      = true
  client_cidr_block = "10.0.0.0/22"
  dns_servers       = ["172.16.0.2"] # VPC DNS resolver (always VPC base IP + 2)
}

# ─────────────────────────────────────────────
# NETWORK ASSOCIATIONS
# ─────────────────────────────────────────────

# To allow clients to establish a VPN session, you associate a target network with the Client VPN endpoint. A target network is a subnet in a VPC.
resource "aws_ec2_client_vpn_network_association" "Client_Network_Association_Subnet_A" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.ClientVPN_Endpoint.id
  subnet_id              = var.subnet_A_id
}

resource "aws_ec2_client_vpn_network_association" "Client_Network_Association_Subnet_B" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.ClientVPN_Endpoint.id
  subnet_id              = var.subnet_B_id
}

# ─────────────────────────────────────────────
# AUTHORIZATION RULES
# ─────────────────────────────────────────────

# For clients to access the VPC, there needs to be a route to the VPC in the Client VPN endpoint's route table and an authorization rule. The route was already added automatically in the previous step. For this tutorial, we want to grant all users access to the VPC.
resource "aws_ec2_client_vpn_authorization_rule" "ClientVPN_Authorization_Rule_Subnet_A" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.ClientVPN_Endpoint.id
  #target_network_cidr = "172.16.0.0/24" # The IPv4 or IPv6 address range, in CIDR notation, of the network to which the authorization rule applies. - Here we allow access to the entire VPC
  target_network_cidr  = var.subnet_A_cidr # Here, we allow connections only to subnet A of the VPC
  authorize_all_groups = true

  lifecycle {
    ignore_changes = all # Ignores if it already exists
  }
}

resource "aws_ec2_client_vpn_authorization_rule" "ClientVPN_Authorization_Rule_Subnet_B" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.ClientVPN_Endpoint.id
  #target_network_cidr = "172.16.0.0/24" # The IPv4 or IPv6 address range, in CIDR notation, of the network to which the authorization rule applies. - Here we allow access to the entire VPC
  target_network_cidr  = var.subnet_B_cidr # Here, we allow connections only to subnet B of the VPC
  authorize_all_groups = true

  lifecycle {
    ignore_changes = all # Ignores if it already exists
  }
}

# ─────────────────────────────────────────────
# OUTPUTS
# ─────────────────────────────────────────────
output "ClientVPN_Endpoint_Output" {
  value = aws_ec2_client_vpn_endpoint.ClientVPN_Endpoint
}

output "vpn_user_certs" {
  sensitive = true
  value = {
    for user in var.vpn_users : user => {
      cert = tls_locally_signed_cert.client[user].cert_pem
      key  = tls_private_key.client[user].private_key_pem
    }
  }
}

output "ca_cert" {
  sensitive = true
  value     = tls_self_signed_cert.ca.cert_pem
}