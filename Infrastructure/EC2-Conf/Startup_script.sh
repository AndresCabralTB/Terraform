#!/bin/bash
DNS_NAME="${DNS_NAME}"
MOUNT_DIR="${MOUNT_DIR}"
INTERNAL_NAME="${INTERNAL_NAME}"

mkdir -p "$MOUNT_DIR"
chown 1000:1000 "$MOUNT_DIR"

hostnamectl set-hostname "$INTERNAL_NAME"

mount -t nfs4 \
  -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
  "$DNS_NAME":/ "$MOUNT_DIR"