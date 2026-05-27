#!/bin/bash
DNS_NAME="${DNS_NAME}"
MOUNT_DIR="${MOUNT_DIR}"
INTERNAL_NAME="${INTERNAL_NAME}"

mkdir -p "${MOUNT_DIR}"
chown 1000:1000 "${MOUNT_DIR}"

hostnamectl set-hostname "${INTERNAL_NAME}"
mount -t efs -o tls "${DNS_NAME}":/ "${MOUNT_DIR}"

