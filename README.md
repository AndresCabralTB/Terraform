# Cloud Infrastructure Project — IaaC

This is an Infrastructure as Code (IaC) project built with Terraform that deploys a secure, self-contained AWS network infrastructure. The entire environment can be deployed and destroyed with a single command.

## Architecture

### 1. VPC and Subnets
The foundation of the infrastructure is a VPC with two subnets:

- **Subnet A (Public)** — Has internet access via an Internet Gateway. A Route Table is attached to the VPC with a route that directs all outbound traffic from Subnet A through the Internet Gateway. Any resource deployed in this subnet automatically has internet access.
- **Subnet B (Private)** — Isolated from the internet. No outbound route to an Internet Gateway exists for this subnet.

### 2. Bastion Host
Deployed in Subnet A, the Bastion Host is a publicly accessible EC2 instance that serves as the entry point into the infrastructure. Because it resides in Subnet A, it inherits internet access through the Route Table and Internet Gateway.

The Bastion Host has an IAM Instance Profile assigned with the SSM Session Manager role, allowing terminal access through AWS Systems Manager without requiring open SSH ports or key pairs.

### 3. Private Host
Deployed in Subnet B, the Private Host is an EC2 instance that is completely isolated from the internet and from SSM access. To connect to it, there are two options:

- Create a Security Group that allows the Bastion Host to connect to the Private Host directly.
- Connect through the Client VPN, which is discussed in section 5.

### 4. Route 53 Private DNS
Both instances are assigned Route 53 DNS records, allowing other resources within the VPC to reference them by name instead of IP address:

- Bastion Host: `bastionhost.cabral.cloud`
- Private Host: `privatehost.cabral.cloud`

This was configured by creating a Route 53 Private Hosted Zone attached to the VPC, and defining records inside the zone that point to each EC2 instance's private IP.

### 5. Client VPN
The Client VPN allows external clients such as on-premise machines to connect directly to the VPC using an OpenVPN-compatible configuration file, bypassing the need to go through the Bastion Host.

**Certificate setup:**
Client and Server certificates were generated following the AWS documentation:
https://docs.aws.amazon.com/pdfs/vpn/latest/clientvpn-admin/client-vpn-admin-guide.pdf page 24

Once generated, the certificates were imported into AWS ACM and referenced by the VPN endpoint.

**Configuration:**
- The VPN endpoint is configured with the VPC DNS resolver (`172.16.0.2`) so that private Route 53 records resolve correctly when connected.
- Split tunneling is enabled, meaning only VPC-bound traffic is routed through the VPN tunnel. All other internet traffic goes directly from the client. This prevents general internet browsing from hanging or being degraded while connected.
- Both Subnet A and Subnet B are associated as target networks, granting connected clients access to resources in both subnets.

## Conclusion
The result is a secure, modular, and independently deployable infrastructure. External clients can connect to the VPC through the Client VPN, access private resources directly by DNS name, and the entire environment can be torn down and redeployed at any time without manual intervention.
