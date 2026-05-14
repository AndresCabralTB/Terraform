#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${1:-us-east-1}"

echo "Using AWS region: $AWS_REGION"
echo "Fetching Client VPN Endpoint ID from Terraform state..."

ENDPOINT_ID=$(terraform output -raw ClientVPN_Endpoint_Output 2>&1)

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to get ClientVPN_Endpoint_Output from Terraform state"
    echo "Output was: $ENDPOINT_ID"
    exit 1
fi

if [ -z "$ENDPOINT_ID" ] || [ "$ENDPOINT_ID" = "null" ] || [ "$ENDPOINT_ID" = "None" ]; then
    echo "WARNING: No Client VPN Endpoint found in state, skipping deletion..."
else
    echo "Found Client VPN Endpoint: $ENDPOINT_ID"
    echo "Disassociating network associations first..."

    aws ec2 describe-client-vpn-target-networks \
        --region "$AWS_REGION" \
        --client-vpn-endpoint-id "$ENDPOINT_ID" \
        --query 'ClientVpnTargetNetworks[*].AssociationId' \
        --output text | tr '\t' '\n' | while read -r ASSOC_ID; do
            if [ -n "$ASSOC_ID" ] && [ "$ASSOC_ID" != "None" ]; then
                echo "Disassociating: $ASSOC_ID"

                aws ec2 disassociate-client-vpn-target-network \
                    --region "$AWS_REGION" \
                    --client-vpn-endpoint-id "$ENDPOINT_ID" \
                    --association-id "$ASSOC_ID"
            fi
        done

    echo "Waiting for disassociations to complete..."
    sleep 60

    echo "Deleting Client VPN Endpoint: $ENDPOINT_ID"

    aws ec2 delete-client-vpn-endpoint \
        --region "$AWS_REGION" \
        --client-vpn-endpoint-id "$ENDPOINT_ID"

    echo "Waiting for endpoint deletion..."
    sleep 30
fi