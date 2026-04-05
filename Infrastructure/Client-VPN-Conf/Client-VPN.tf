#Create the Client VPN endpoint

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

# Retrieve the Server certificate generated from https://docs.aws.amazon.com/pdfs/vpn/latest/clientvpn-admin/client-vpn-admin-guide.pdf#cvpn-working page 24
data "aws_acm_certificate" "server_certificate_arn" {
  domain = "server"
}

# Retrieve the client key from AWS ACM
data "aws_acm_certificate" "client_certificate_arn" {
  domain = "client1.domain.tld"
}

# The Client VPN endpoint is the resource that you create and configure to enable and manage client VPN sessions. It's the termination point for all client VPN sessions.
resource "aws_ec2_client_vpn_endpoint" "ClientVPN_Endpoint" {
    description             = "terraform-clientvpn"
    server_certificate_arn  = data.aws_acm_certificate.server_certificate_arn.arn
    authentication_options {
        type = "certificate-authentication"
        root_certificate_chain_arn = data.aws_acm_certificate.client_certificate_arn.arn
        
    }
    connection_log_options {
        enabled = false
    }
    # Routes only VPC-bound traffic through the VPN tunnel; all other internet traffic goes directly from the client
    split_tunnel      = true
    client_cidr_block = "10.0.0.0/22"
    dns_servers        = ["172.16.0.2"]  # VPC DNS resolver (always VPC base IP + 2)
}

# To allow clients to establish a VPN session, you associate a target network with the Client VPN endpoint. A target network is a subnet in a VPC.
resource "aws_ec2_client_vpn_network_association" "Client_Network_Association_Subnet_A" {
    client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.ClientVPN_Endpoint.id
    subnet_id = var.subnet_A_id
  }

resource "aws_ec2_client_vpn_network_association" "Client_Network_Association_Subnet_B" {
    client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.ClientVPN_Endpoint.id
    subnet_id = var.subnet_B_id
  }

# For clients to access the VPC, there needs to be a route to the VPC in the Client VPN endpoint's route table and an authorization rule. The route was already added automatically in the previous step. For this tutorial, we want to grant all users access to the VPC.

resource "aws_ec2_client_vpn_authorization_rule" "ClientVPN_Authorization_Rule_Subnet_A" {
    client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.ClientVPN_Endpoint.id
    #target_network_cidr = "172.16.0.0/24" # The IPv4 or IPv6 address range, in CIDR notation, of the network to which the authorization rule applies. - Here we allow access to the entire VPC
    target_network_cidr = var.subnet_A_cidr # Here, we allow connections only to subnet B of the VPC
    authorize_all_groups = true
    lifecycle {
    ignore_changes = all  # Ignores if it already exists
    }
}

resource "aws_ec2_client_vpn_authorization_rule" "ClientVPN_Authorization_Rule_Subnet_B" {
    client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.ClientVPN_Endpoint.id
    #target_network_cidr = "172.16.0.0/24" # The IPv4 or IPv6 address range, in CIDR notation, of the network to which the authorization rule applies. - Here we allow access to the entire VPC
    target_network_cidr = var.subnet_B_cidr # Here, we allow connections only to subnet B of the VPC
    authorize_all_groups = true
    lifecycle {
    ignore_changes = all  # Ignores if it already exists
    }
}

output "ClientVPN_Endpoint_Output" {
  value = aws_ec2_client_vpn_endpoint.ClientVPN_Endpoint
}

