#!/bin/bash

IMAGE_NAME=$1
IMAGE_TAG=$2
DOCKERFILE_PATH=$3
IMAGE_LOG=$4
 
#echo -e "Image Name: "$IMAGE_NAME"\nImage_Tag: "$IMAGE_TAG"\n"DOCKERFILE_PATH: "$DOCKERFILE_PATH"\nImage Log: "$IMAGE_LOG"""

#exec >> "$IMAGE_LOG" 2>&1  # <-- handles everything from here down

# Build the docker image — write ONLY to log file (not terminal)
docker build -t "$IMAGE_NAME":"$IMAGE_TAG" "$DOCKERFILE_PATH" >> "$IMAGE_LOG" 2>&1

# Verify that the logs don't contain any errors
if grep -qi "ERROR" "$IMAGE_LOG"
then
    echo $'\nFailed to create Image\n' | tee -a "$IMAGE_LOG"
    grep -i "ERROR" "$IMAGE_LOG" | tee -a "$IMAGE_LOG"
    echo -e "\nMore information in $IMAGE_LOG\n" | tee -a "$IMAGE_LOG"
else
    echo $'\nImage created successfully\n' | tee -a "$IMAGE_LOG"
    docker images "$IMAGE_NAME" >> "$IMAGE_LOG" 2>&1
    echo
fi