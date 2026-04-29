#!/bin/bash
# Usage: ./generate_ovpn.sh alice downloaded.ovpn

USER=$1
BASE_OVPN=$2

TERRAFORM_DIR="/Users/andrescabral/Desktop/Terraform-Project/Infrastructure"  # ADD THIS

# Get cert and key from Terraform outputs
CERT=$(terraform -chdir=$TERRAFORM_DIR output -json vpn_user_certs | jq -r ".\"$USER\".cert")
KEY=$(terraform -chdir=$TERRAFORM_DIR output -json vpn_user_certs | jq -r ".\"$USER\".key")
CA=$(terraform -chdir=$TERRAFORM_DIR output -raw ca_cert)

# Copy base ovpn and append certs
cp "$BASE_OVPN" "$USER.ovpn"

cat >> "$USER.ovpn" <<EOF

<ca>
$CA
</ca>

<cert>
$CERT
</cert>

<key>
$KEY
</key>

reneg-sec 0
verify-x509-name server name
EOF

echo "$USER.ovpn generated successfully"