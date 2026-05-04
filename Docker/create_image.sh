#!/bin/bash
source functions.sh

create_image(){
IMAGE_NAME=$1
IMAGE_TAG=$2
DOCKERFILE_PATH=$3 
#echo -e "\nImage Name: "$IMAGE_NAME"\nImage_Tag: "$IMAGE_TAG"\n"DOCKERFILE_PATH: "$DOCKERFILE_PATH"\nImage Log: "$IMAGE_LOG"""

# Build the docker image — write ONLY to log file (not terminal)


# Verify that the logs don't contain any errors
if docker build -t "$IMAGE_NAME":"$IMAGE_TAG" "$DOCKERFILE_PATH" >> "$SESSION_LOGS" 2>&1
then
    echo "[$(date)] - Image created successfully" | tee -a "$SESSION_LOGS"
    docker images "$IMAGE_NAME" >> "$SESSION_LOGS" 2>&1
    echo
else
	echo "[$(date)] - Failed to create Image" | tee -a "$SESSION_LOGS"
    grep -i "ERROR" "$SESSION_LOGS" | tee -a "$SESSION_LOGS"
    echo -e "More information in $SESSION_LOGS"
fi
}


echo '''
================================================
CREATING IMAGE STAGE 1: SETTING UP THE VARIABLES
================================================
'''

echo "Session ID: "$PIDP""

read -p $'\nImage Name: ' IMAGE_NAME
    
IMAGE_NAME=$(is_empty "$IMAGE_NAME")

read -p $'\nImage Tag (default is 'latest'): ' IMAGE_TAG
    
if [ -z "$IMAGE_TAG" ]
then
    IMAGE_TAG="latest"
fi

read -p $'\nEnter the path of the Dockerfile you whish to use (press enter for current directory): ' DOCKERFILE_PATH

if [ -z "$DOCKERFILE_PATH" ]
then 
    DOCKERFILE_PATH="."
else
    until [ -p "$DOCKERFILE_PATH" ]
    do
        read -p $'\nFile does not exist, please try again: ' DOCKERFILE_PATH
    done
fi

echo '''
===============================================
CREATING IMAGE STAGE 2: BUILD THE DOCKER IMAGE
===============================================
'''
create_image "$IMAGE_NAME" "$IMAGE_TAG" "$DOCKERFILE_PATH" 


get_image(){

if ! docker images
then
    read -p "There are no images deployed. Do you wish to create a new one? (Y/N): " CREATE_IMAGE
    
    CREATE_IMAGE=$(is_empty "$CREATE_IMAGE")
    if [ "$CREATE_IMAGE" == "Y" ]
    then
        create_new_image
    elif [ "$CREAET_IMAGE" == "N" ]
    then
        exit 1
    fi
fi

}
