#!/bin/bash
ENVIRONMENT=$1
date=$(date '+%Y%m%d')
echo "Creating backup"

# Get running instances
IFS=$'\n' read -r -d '' -a INSTANCE_LIST < <(
  aws ec2 describe-instances \
    --filters \
      "Name=tag:Name,Values=*${ENVIRONMENT}*" \
      "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text
)

NEW_INSTANCE_LIST=$(IFS=','; echo "${INSTANCE_LIST[*]}")
echo "List: ${NEW_INSTANCE_LIST}"

if [ ${#INSTANCE_LIST[@]} -gt 0 ]; then
    for instance in "${INSTANCE_LIST[@]}"; do
        InstanceName=$(aws ec2 describe-instances \
            --instance-ids "${instance}" \
            --query "Reservations[*].Instances[*].Tags[?Key=='Name'].Value[]" \
            --output text)

        AMI_NAME="${InstanceName}-backup-${date}"

        # Deregister existing AMI with the same name
        EXISTING_AMI=$(aws ec2 describe-images \
            --owners self \
            --filters "Name=name,Values=${AMI_NAME}" \
            --query "Images[0].ImageId" \
            --output text)

        if [ "${EXISTING_AMI}" != "None" ]; then
            echo "Deregistering existing AMI ${EXISTING_AMI} for ${InstanceName}"
            aws ec2 deregister-image --image-id "${EXISTING_AMI}"
        fi

        AMI_ID=$(aws ec2 create-image \
            --instance-id "${instance}" \
            --name "${AMI_NAME}" \
            --no-reboot \
            --query "ImageId" \
            --output text)

        aws ec2 create-tags \
            --resources "${AMI_ID}" \
            --tags "Key=Name,Value=${AMI_NAME}"

        echo "Created AMI ${AMI_ID} for ${InstanceName}"
    done
else
    echo "There are no instances deployed on ${ENVIRONMENT} - Exiting backup"
fi