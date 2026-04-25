# Cloud Infrastructure Project — IaaC

Run: `fswatch -o . | xargs -n1 -I{} aws s3 sync . s3://terraform-infrastructure-project --delete`

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

---

#### Certificate Setup — Option A: Manual (EasyRSA)

Client and Server certificates were generated following the AWS documentation:
https://docs.aws.amazon.com/pdfs/vpn/latest/clientvpn-admin/client-vpn-admin-guide.pdf page 24

Once the keys were generated in a safe directory, they were copied over to this repo:

```bash
cd easyrsa
cp pki/ca.crt .
cp pki/issued/server.crt .
cp pki/private/server.key .
cp pki/issued/client1.domain.tld.crt .
cp pki/private/client1.domain.tld.key .
```

Once generated, the certificates were imported into AWS ACM and referenced by the VPN endpoint:

```bash
aws acm import-certificate \
  --certificate fileb://server.crt \
  --private-key fileb://server.key \
  --certificate-chain fileb://ca.crt
```

```json
{
    "CertificateArn": "arn:aws:acm:us-east-1:718254829448:certificate/b9625cba-9c31-4085-9ada-b03f85a82cf4"
}
```

The CA certificate must also be uploaded separately so the VPN endpoint can use it to validate incoming client certificates:

```bash
aws acm import-certificate \
  --certificate fileb://ca.crt \
  --private-key fileb://ca.key
```

The endpoint's `server_certificate_arn` is pointed to the server cert ARN, and `root_certificate_chain_arn` is pointed to the CA cert ARN.

**To distribute access to a new user**, generate a new client keypair with EasyRSA, embed the cert and key into a copy of the downloaded `.ovpn` file, and send it to the user. They import it into OpenVPN Connect and connect — no further configuration needed.

---

#### Certificate Setup — Option B: Fully Automated via Terraform (Recommended)

Instead of using EasyRSA manually, the entire certificate lifecycle — CA, server cert, per-user client certs, and ACM uploads — is managed by Terraform using the `tls` provider. This means `terraform apply` creates everything and `terraform destroy` tears it all down with no orphaned certificates left in ACM.

Certificates require a valid DNS domain to be accepted by AWS ACM. The `tls_cert_request` resources use `dns_names` to add a Subject Alternative Name (SAN), which is what ACM validates:

```hcl
# CA
resource "tls_self_signed_cert" "ca" {
  subject {
    common_name = "ca.cabral.cloud"
  }
  ...
}

# Server
resource "tls_cert_request" "server" {
  subject {
    common_name = "server.cabral.cloud"
  }
  dns_names = ["server.cabral.cloud"]
}

# Per-user clients
resource "tls_cert_request" "client" {
  for_each = toset(var.vpn_users)
  subject {
    common_name = "${each.key}.cabral.cloud"
  }
  dns_names = ["${each.key}.cabral.cloud"]
}
```

**To add a new user**, add their name to the `vpn_users` variable and run `terraform apply`:

```hcl
variable "vpn_users" {
  type    = list(string)
  default = ["alice", "bob", "charlie"]
}
```

**To generate a ready-to-use `.ovpn` per user**, run the helper script after apply:

```bash
# Requires: jq (brew install jq)
# Usage: ./generate_ovpn.sh <username> <downloaded.ovpn>

./generate_ovpn.sh alice downloaded.ovpn
./generate_ovpn.sh bob downloaded.ovpn
```

This embeds each user's unique cert and key into the base `.ovpn` downloaded from the AWS Console. The user receives a ready-to-import file — no manual certificate editing required.

> ⚠️ Private keys are stored in the Terraform state file. Ensure your state backend (e.g. S3) has encryption and restricted access enabled.

---

**Configuration:**

- The VPN endpoint is configured with the VPC DNS resolver (`172.16.0.2`) so that private Route 53 records resolve correctly when connected.
- Split tunneling is enabled, meaning only VPC-bound traffic is routed through the VPN tunnel. All other internet traffic goes directly from the client. This prevents general internet browsing from hanging or being degraded while connected.
- Both Subnet A and Subnet B are associated as target networks, granting connected clients access to resources in both subnets.

## Conclusion

The result is a secure, modular, and independently deployable infrastructure. External clients can connect to the VPC through the Client VPN, access private resources directly by DNS name, and the entire environment can be torn down and redeployed at any time without manual intervention.