#!/bin/bash
source functions.sh

create_image(){
IMAGE_NAME=$1
IMAGE_TAG=$2
DOCKERFILE_PATH=$3
IMAGE_LOG=$4
 
#echo -e "\nImage Name: "$IMAGE_NAME"\nImage_Tag: "$IMAGE_TAG"\n"DOCKERFILE_PATH: "$DOCKERFILE_PATH"\nImage Log: "$IMAGE_LOG"""

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
}


echo '''
================================================
CREATING IMAGE STAGE 1: SETTING UP THE VARIABLES
================================================
'''
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
==========================================
CREATING IMAGE STAGE 2: CREATE THE LOGFILE
==========================================
'''

#Create a directory if it doesn't exist, as well as the log file for the creation of the image
mkdir -p ./logs
IMAGE_LOG=$(echo ./logs/"$IMAGE_NAME"_"$IMAGE_TAG"_startup.log | tr :- _)
touch "$IMAGE_LOG"
echo -e "Image log file "$IMAGE_LOG" created\n" && chmod +rwx "$IMAGE_LOG"
echo '''
===============================================
CREATING IMAGE STAGE 3: BUILD THE DOCKER IMAGE
===============================================
'''
create_image "$IMAGE_NAME" "$IMAGE_TAG" "$DOCKERFILE_PATH" "$IMAGE_LOG"


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
