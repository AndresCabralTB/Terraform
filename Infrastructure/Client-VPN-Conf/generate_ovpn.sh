#!/bin/bash
# Usage: ./generate_ovpn.sh <username> <downloaded.ovpn>
# Example: ./generate_ovpn.sh alice downloaded-client-config.ovpn
# Requires: jq (brew install jq)

USER=$1
BASE_OVPN=$2
TERRAFORM_DIR=$3 
a
if [ -z "$USER" ] || [ -z "$BASE_OVPN" ] || [ -z "$TERRAFORM_DIR" ]; then
  echo "Usage: ./generate_ovpn.sh <username> <downloaded.ovpn> <client-vpn-directory>"
  exit 1
fi

# Get cert and key from Terraform outputs
CERT=$(terraform -chdir=$TERRAFORM_DIR output -json vpn_user_certs | jq -r ".\"$USER\".cert")
KEY=$(terraform -chdir=$TERRAFORM_DIR output -json vpn_user_certs | jq -r ".\"$USER\".key")
CA=$(terraform -chdir=$TERRAFORM_DIR output -raw ca_cert)

if [ -z "$CERT" ] || [ "$CERT" == "null" ]; then
  echo "Error: user '$USER' not found in Terraform outputs. Make sure they are in the vpn_users variable."
  exit 1
fi

# Strip everything from the first <ca> block to the end of the downloaded config,
# and also remove any existing verify-x509-name and reneg-sec lines
# so we can add them cleanly once at the end
STRIPPED=$(sed '/<ca>/,/<\/ca>/d' "$BASE_OVPN" | grep -v "reneg-sec" | grep -v "verify-x509-name")

# Write the clean ovpn
cat > "$USER.ovpn" <<EOF
$STRIPPED

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
verify-x509-name server.cabral.cloud name
EOF

echo "$USER.ovpn generated successfully"