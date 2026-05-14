#!/bin/bash
set -e
REGION=$1

ENDPOINT_ID=$(aws ec2 describe-client-vpn-endpoints \
    --region "$REGION" \
    --query 'ClientVpnEndpoints[0].ClientVpnEndpointId' \
    --output text)

if [ -z "$ENDPOINT_ID" ] || [ "$ENDPOINT_ID" == "None" ] || [ "$ENDPOINT_ID" == "null" ]; then
    echo "No VPN endpoint found, skipping cleanup."
    exit 0
fi

echo "Found VPN Endpoint: $ENDPOINT_ID"

# Step 1 - Remove all authorization rules first
echo "Removing authorization rules..."
AUTH_RULES=$(aws ec2 describe-client-vpn-authorization-rules \
    --region "$REGION" \
    --client-vpn-endpoint-id "$ENDPOINT_ID" \
    --query 'AuthorizationRules[*].{cidr:DestinationCidr,group:GroupId}' \
    --output json)

echo "$AUTH_RULES" | jq -c '.[]' | while read -r rule; do
    CIDR=$(echo "$rule" | jq -r '.cidr')
    GROUP=$(echo "$rule" | jq -r '.group')
    echo "Revoking auth rule: $CIDR"
    if [ "$GROUP" == "null" ] || [ -z "$GROUP" ]; then
        aws ec2 revoke-client-vpn-ingress \
            --region "$REGION" \
            --client-vpn-endpoint-id "$ENDPOINT_ID" \
            --target-network-cidr "$CIDR" \
            --revoke-all-groups || true
    else
        aws ec2 revoke-client-vpn-ingress \
            --region "$REGION" \
            --client-vpn-endpoint-id "$ENDPOINT_ID" \
            --target-network-cidr "$CIDR" \
            --access-group-id "$GROUP" || true
    fi
done

# Step 2 - Remove all routes
echo "Removing routes..."
ROUTES=$(aws ec2 describe-client-vpn-routes \
    --region "$REGION" \
    --client-vpn-endpoint-id "$ENDPOINT_ID" \
    --query 'Routes[?Type!=`federated`].{cidr:DestinationCidr,subnet:TargetSubnet}' \
    --output json)

echo "$ROUTES" | jq -c '.[]' | while read -r route; do
    CIDR=$(echo "$route" | jq -r '.cidr')
    SUBNET=$(echo "$route" | jq -r '.subnet')
    echo "Deleting route: $CIDR via $SUBNET"
    aws ec2 delete-client-vpn-route \
        --region "$REGION" \
        --client-vpn-endpoint-id "$ENDPOINT_ID" \
        --destination-cidr-block "$CIDR" \
        --target-vpc-subnet-id "$SUBNET" || true
done

# Step 3 - Disassociate all subnets
echo "Disassociating subnets..."
ASSOCIATION_IDS=$(aws ec2 describe-client-vpn-target-networks \
    --region "$REGION" \
    --client-vpn-endpoint-id "$ENDPOINT_ID" \
    --query 'ClientVpnTargetNetworks[*].AssociationId' \
    --output text)

for ASSOC_ID in $ASSOCIATION_IDS; do
    echo "Disassociating: $ASSOC_ID"
    aws ec2 disassociate-client-vpn-target-network \
        --region "$REGION" \
        --client-vpn-endpoint-id "$ENDPOINT_ID" \
        --association-id "$ASSOC_ID" || true
done

# Step 4 - Wait until ALL associations are fully gone (not just "disassociated")
echo "Waiting for all associations to be removed..."
while true; do
    REMAINING=$(aws ec2 describe-client-vpn-target-networks \
        --region "$REGION" \
        --client-vpn-endpoint-id "$ENDPOINT_ID" \
        --query 'ClientVpnTargetNetworks[?Status.Code!=`disassociated`].AssociationId' \
        --output text)

    if [ -z "$REMAINING" ]; then
        echo "All associations fully removed."
        break
    fi

    echo "Still waiting on: $REMAINING — retrying in 15s"
    sleep 15
done

echo "VPN cleanup complete. Safe to destroy."