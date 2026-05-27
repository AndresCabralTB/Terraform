#!/bin/bash
DNS_NAME=$1
MOUNT_DIR=$2
INTERNAL_NAME=$3

mkdir ${DNS_NAME}
chown -R ${DNS_NAME} 1000:1000

hostnamectl set-hostname ${INTERNAL_NAME}
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${DNS_NAME}:/ ${MOUNT_DIR}
