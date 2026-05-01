#!/bin/bash
source functions.sh

#Trap TERM to exit from is_empty
#Trap allows you to catch signals and execute code when they occur. Signals are asynchronous notifications that are sent to your script when certain events occur.
trap "exit 1" TERM
export TOP_PID=$$ #In Bash, the command var=$$ assigns the process ID (PID) of the current shell or script to the variable named var

select_image(){
echo $'\nSelect a Docker Images to deploy the container\n'
docker images

read -p $'\nEnter the image name and tag (e.g., NAME:TAG): ' DOCKER_IMAGE
##echo "$DOCKER_IMAGE"

# Until the input doesn't match an existing Image, repeat the query
until [ $(docker image inspect "$DOCKER_IMAGE" | grep -i "$DOCKER_IMAGE" ) ] 
do
    read -p $'\nPlease try again: ' DOCKER_IMAGE
done

read -p $'\nDo you wish to inspect the image? (Y/N): ' INSPECT_IMAGE

# Until the value is either Y or N, ask the customer to retry
until [ "$INSPECT_IMAGE" == "Y" ] || [ "$INSPECT_IMAGE" == "N" ]
do
    read -p $'\nUnrecognized key, please try again: ' INSPECT_IMAGE
done

# Save details to external .txt file if Y
if [ "$INSPECT_IMAGE" == "Y" ]; then 
    TEMP_DOCKER_IMAGE="$(echo "$DOCKER_IMAGE" | tr /:- _)" # Change forward slash to underscore to avoid issues when naming file
    docker image inspect "$DOCKER_IMAGE" > "$TEMP_DOCKER_IMAGE"_inspection.txt
    echo $'\nDetails saved to '$TEMP_DOCKER_IMAGE'_inspection.txt'
fi
}

create_new_image(){

echo '''
================================================
CREATING IMAGE STAGE 1: SETTING UP THE VARIABLES
================================================
'''
read -p $'\nImage Name: ' IMAGE_NAME
    
IMAGE_NAME=$(is_empty "$IMAGE_NAME" "$TERM" "$TOP_PID")

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
./image-template.sh "$IMAGE_NAME" "$IMAGE_TAG" "$DOCKERFILE_PATH" "$IMAGE_LOG"

}

get_image(){

if ! docker images
then
    read -p "There are no images deployed. Do you wish to create a new one? (Y/N): " CREATE_IMAGE
    
    CREATE_IMAGE=$(is_empty "$CREATE_IMAGE" "$TERM" "$TOP_PID")
    if [ "$CREATE_IMAGE" == "Y" ]
    then
        create_new_image
    elif [ "$CREAET_IMAGE" == "N" ]
    then
        exit 1
    fi
fi

}

echo "
=================================
WELCOME TO DOCKER CONFIGURATIONS
==================================
"

PS3=$'\nChose an option: '
startup_options=("List Images" "List Containers" "List Volumes" "Create Image" "Create Container" "Delete Image" "Delete Container" "Exit")

COLUMNS=0 # Display menu in a single column

while true; do
echo -e "
\t======================
\t      MAIN MENU
\t======================
"
    select opt in "${startup_options[@]}"; do
        case $opt in
            "List Images")
                list_resources "List Images" 
                break
                ;;
            "List Containers")
                list_resources "List Containers"
                break
                ;;
            "List Volumes")
                list_resources "List Volumes" 
                break
                ;;
            "Create Image")
                create_new_image 
                break
                ;;
            "Create Container")
                ./create_container.sh
                break
                ;;
            "Delete Image")
                echo  "To be released" 
                break
                ;;
            "Delete Container")
                echo  "To be released" 
                break
                ;;
            "Exit")
                kill -s TERM $TOP_PID
                ;;
            *) echo "Option '$REPLY' not available, try again" ;;
        esac
    done 
done
#Run select_image function

echo "Next steps -->"
exit

