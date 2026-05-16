#!/bin/bash
# Usage: ./generate_ovpn.sh <username> <downloaded.ovpn> <terraform-dir> <environment>
USER=$1
BASE_OVPN=$2
TERRAFORM_DIR=$3
ENVIRONMENT=$4

if [ -z "$USER" ] || [ -z "$BASE_OVPN" ] || [ -z "$TERRAFORM_DIR" ] || [ -z "$ENVIRONMENT" ]; then
    echo "Usage: ./generate_ovpn.sh <username> <downloaded.ovpn> <terraform-dir> <environment>"
    exit 1
fi

# Select the correct workspace so outputs come from the right environment
terraform -chdir=$TERRAFORM_DIR workspace select $ENVIRONMENT

# Get cert and key from Terraform outputs
CERT=$(terraform -chdir=$TERRAFORM_DIR output -json vpn_user_certs | jq -r ".\"$USER\".cert")
KEY=$(terraform -chdir=$TERRAFORM_DIR output -json vpn_user_certs | jq -r ".\"$USER\".key")
CA=$(terraform -chdir=$TERRAFORM_DIR output -raw ca_cert)

if [ -z "$CERT" ] || [ "$CERT" == "null" ]; then
    echo "Error: user '$USER' not found in Terraform outputs for workspace '$ENVIRONMENT'."
    exit 1
fi

STRIPPED=$(sed '/<ca>/,/<\/ca>/d' "$BASE_OVPN" | grep -v "reneg-sec" | grep -v "verify-x509-name")

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

echo "$USER.ovpn generated successfully for environment: $ENVIRONMENT"