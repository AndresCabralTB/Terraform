# ─────────────────────────────────────────────
# CA (Certificate Authority)
# The CA is the root of trust for the VPN.
# It signs both the server and client certificates,
# allowing mutual TLS authentication between them.
# ─────────────────────────────────────────────

# Generate the CA's private key, used to sign all certificates
resource "tls_private_key" "ca" {
  count = var.create_resource
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Generate the self-signed CA certificate.
# Valid for 10 years. Acts as the root of trust for the entire VPN PKI.
resource "tls_self_signed_cert" "ca" {
  count = var.create_resource
  private_key_pem       = tls_private_key.ca[count.index].private_key_pem
  validity_period_hours = 87600 # 10 years
  is_ca_certificate     = true

  subject {
    common_name  = "ca.cabral.cloud"
    organization = "ca.cabral.cloud"
  }

  allowed_uses = [
    "cert_signing", # Can sign other certificates
    "crl_signing",  # Can sign certificate revocation lists
  ]
}

# ─────────────────────────────────────────────
# SERVER CERTIFICATE
# Identifies the VPN server to connecting clients.
# Signed by the CA above.
# ─────────────────────────────────────────────

# Generate the server's private key
resource "tls_private_key" "server" {
  count = var.create_resource
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create a certificate signing request (CSR) for the server
resource "tls_cert_request" "server" {
  count = var.create_resource
  private_key_pem = tls_private_key.server[count.index].private_key_pem

  subject {
    common_name  = "server.cabral.cloud"
    organization = "cabral.cloud"
  }

  dns_names = ["server.cabral.cloud"]
}

# Sign the server CSR with the CA to produce the final server certificate.
# Valid for 10 years. Allows key encipherment, digital signing, and server auth.
resource "tls_locally_signed_cert" "server" {
  count = var.create_resource
  cert_request_pem      = tls_cert_request.server[count.index].cert_request_pem
  ca_private_key_pem    = tls_private_key.ca[count.index].private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca[count.index].cert_pem
  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "key_encipherment",  # Required for TLS key exchange
    "digital_signature", # Required for TLS handshake
    "server_auth",       # Identifies this cert as a server certificate
  ]
}

# Upload the signed server certificate to ACM so it can be used by the AWS Client VPN endpoint
resource "aws_acm_certificate" "server" {
  count = var.create_resource
  private_key       = tls_private_key.server[count.index].private_key_pem
  certificate_body  = tls_locally_signed_cert.server[count.index].cert_pem
  certificate_chain = tls_self_signed_cert.ca[count.index].cert_pem # CA chain for client validation
}

# Upload the CA certificate to ACM separately.
# AWS Client VPN uses this as the root CA to validate client certificates.
resource "aws_acm_certificate" "ca" {
  count = var.create_resource
  private_key      = tls_private_key.ca[count.index].private_key_pem
  certificate_body = tls_self_signed_cert.ca[count.index].cert_pem
}

# ─────────────────────────────────────────────
# CLIENT CERTIFICATES
# One certificate is generated per VPN user.
# Each is signed by the CA, allowing the VPN server
# to authenticate clients via mutual TLS.
# ─────────────────────────────────────────────

# Generate a unique private key for each VPN user
resource "tls_private_key" "client" {
  for_each  = toset(var.vpn_users)
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create a CSR for each VPN user
resource "tls_cert_request" "client" {
  for_each        = toset(var.vpn_users)
  private_key_pem = tls_private_key.client[each.key].private_key_pem

  subject {
    common_name  = "${each.key}.cabral.cloud"
    organization = "cabral.cloud"
  }

  dns_names = ["${each.key}.cabral.cloud"]
}

# Sign each client CSR with the CA.
# Valid for 2 years — shorter than the server cert, intentionally,
# so client access can be rotated more frequently.
resource "tls_locally_signed_cert" "client" {
  for_each              = toset(var.vpn_users)
  cert_request_pem      = tls_cert_request.client[each.key].cert_request_pem
  ca_private_key_pem    = tls_private_key.ca[count.index].private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca[count.index].cert_pem
  validity_period_hours = 17520 # 2 years

  allowed_uses = [
    "digital_signature", # Required for TLS handshake
    "client_auth",       # Identifies this cert as a client certificate
  ]
}

# Output each user's certificate and private key so they can be
# bundled into a .ovpn config file for distribution.
# Marked sensitive to prevent values from appearing in plain text in logs.
output "vpn_user_certs" {
  sensitive = true
  value = {
    for user in var.vpn_users : user => {
      cert = tls_locally_signed_cert.client[user].cert_pem
      key  = tls_private_key.client[user].private_key_pem
    }
  }
}

# Output the CA certificate so it can be embedded in client .ovpn configs
# for server certificate validation. Marked sensitive as it is part of the PKI.
output "ca_cert" {
  sensitive = true
  value     = tls_self_signed_cert.ca.cert_pem
}