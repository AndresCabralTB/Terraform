#!/bin/bash
set -e

REGION=$1
ENDPOINT_ID=$(aws ec2 describe-client-vpn-endpoints \
    --region "$REGION" \
    --query 'ClientVpnEndpoints[0].ClientVpnEndpointId' \
    --output text)

if [ -z "$ENDPOINT_ID" ] || [ "$ENDPOINT_ID" == "None" ]; then
    echo "No VPN endpoint found, skipping cleanup."
    exit 0
fi

echo "Cleaning up VPN Endpoint: $ENDPOINT_ID"

# Get all association IDs
ASSOCIATION_IDS=$(aws ec2 describe-client-vpn-target-networks \
    --region "$REGION" \
    --client-vpn-endpoint-id "$ENDPOINT_ID" \
    --query 'ClientVpnTargetNetworks[*].AssociationId' \
    --output text)

# Disassociate each subnet
for ASSOC_ID in $ASSOCIATION_IDS; do
    echo "Disassociating: $ASSOC_ID"
    aws ec2 disassociate-client-vpn-target-network \
        --region "$REGION" \
        --client-vpn-endpoint-id "$ENDPOINT_ID" \
        --association-id "$ASSOC_ID"
done

# Wait until all associations are removed
echo "Waiting for disassociation to complete..."
while true; do
    STATUS=$(aws ec2 describe-client-vpn-target-networks \
        --region "$REGION" \
        --client-vpn-endpoint-id "$ENDPOINT_ID" \
        --query 'ClientVpnTargetNetworks[*].Status.Code' \
        --output text)

    if [ -z "$STATUS" ] || [[ "$STATUS" == *"disassociated"* && ! "$STATUS" == *"associating"* && ! "$STATUS" == *"associated"* ]]; then
        echo "All associations removed."
        break
    fi

    echo "Still disassociating... waiting 15s"
    sleep 15
done