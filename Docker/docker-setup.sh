#!/bin/bash

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

    printf "\n"
}

create_new_image(){
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

    #Create a directory if it doesn't exist, as well as the log file for the creation of the image
    mkdir -p ./logs
    IMAGE_LOG=$(echo ./logs/"$IMAGE_NAME"_"$IMAGE_TAG"_startup.log | tr :- _)
    touch "$IMAGE_LOG"

    echo
    
    #Build the docker image, and print the output in the terminal and in the creation.log file (). 2>&1 only views the result, but doesn't print it in the terminal
    docker build -t "$IMAGE_NAME":"$IMAGE_TAG" "$DOCKERFILE_PATH"  2>&1 | tee "$IMAGE_LOG" > /dev/null 2>&1

    #Verify that the logs don't contain any errors. 2>&1 only views the result, but doesn't print it in the terminal
    if [[ $(grep -ri "ERROR" "$IMAGE_LOG") ]]
    then
        echo $'\nFailed to create Image\n'
        grep -ri "ERROR" "$IMAGE_LOGS"
        echo -e "\nMore information on "$IMAGE_LOGS"\n" # -e flas permitts newlines \n
    else
        echo $'\nImage successfulyl created\n'
        docker images "$IMAGE_NAME"
        echo
    fi

}
is_empty(){
VAR=$1

until [ ! -z "$VAR" ]
do
    read -p $'\nValue cannot be empt, try again or press 1 to exit: ' VAR
    if [ "$VAR" == 1 ]
    then
        echo $'\nGoodbye\n'
        kill -s TERM $TOP_PID #Kill the script and the process ID, which is assigned to TOP_ID
    fi
done
echo "$VAR"
}  

create_container(){
    read -p $'\nEnter the container name: ' CONTAINER_NAME
    CONTAINER_NAME=$(is_empty "$CONTAINER_NAME") #Pass value from function
    
    #echo " your container name is "$CONTAINER_NAME""

    echo -e "\nSelect the Docker Image you want to use"
    list_resources "List Images"
    read -p $'\nEnter Image Name (without the tag): ' CONTAINER_IMAGE
    until docker image inspect "$CONTAINER_IMAGE" > /dev/null 2>&1
    do
        read -p $'\nImage does not exist, try again or press enter to exit: ' CONTAINER_IMAGE
        
        #Call is_empty function to verify if it's empty or not
        CONTAINER_IMAGE=$(is_empty "$CONTAINER_IMAGE")
    done

    read -p $'\nEnter the PORT number to host the container: ' CONTAINER_PORT
    CONTAINER_PORT=$(is_empty "$CONTAINER_PORT")

    read -p $'\nEnter the volume where data will be stored (press enter to see available options): ' CONTAINER_VOLUME
    
    until [ ! -z "$CONTAINER_VOLUME" ]
    do
        list_resources "List Volumes"
        read -p $'\nEnter a volume: ' CONTAINER_VOLUME
    done
    
    #Create variable to define the container startup log
    mkdir -p ./logs/
    CONTAINER_LOG=$(echo ./logs/"$CONTAINER_NAME"_startup.log | tr :- _)
    touch $CONTAINER_LOG > /dev/null 2>&1


    ./container-template.sh "$CONTAINER_NAME" "$CONTAINER_VOLUME" "$CONTAINER_PORT" "$CONTAINER_IMAGE" > "$CONTAINER_LOG" 2>&1

    if [[ $(grep -ri "ERROR" "$CONTAINER_LOG") ]]
    then
        echo $'\nFailed to create the container\n'
        grep -ri "ERROR" "$CONTAINER_LOG"
        echo -e "\nMore information on "$CONTAINER_LOG"\n"
        docker stop "$CONTAINER_NAME" && docker rm "$CONTAINER_NAME"
    else
        echo $'\nContainer Created Successfully\n'
        docker ps -a | grep -i "$CONTAINER_NAME"
    fi

echo
}

list_resources(){
COMMAND=$1

case $COMMAND in
    "List Images")
        echo
        docker images
        echo
        ;;
    "List Containers")
        echo
        docker ps -a
        echo
        ;;
    "List Volumes")
        echo
        docker volume ls
        echo
        ;;
esac
}

echo "
===========================
DOCKER CONFIGURATIONS
===========================
"

PS3=$'\nStart by choosing an option: '
startup_options=("List Images" "List Containers" "List Volumes" "Create Image" "Create Container" "Exit")

COLUMNS=0 # Display menu in a single column

while true; do
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
                create_container 
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

