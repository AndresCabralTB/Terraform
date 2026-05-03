#!/bin/bash 

#Trap TERM to exit from is_empty
#Trap allows you to catch signals and execute code when they occur. Signals are asynchronous notifications that are sent to your script when certain events occur.
trap "exit 1" TERM
export TOP_PID=$$

#Verify if a variable is empty
is_empty(){
VAR=$1

until [ ! -z "$VAR" ]
do
    read -p $'\nValue cannot be empty, try again or press 1 to exit: ' VAR
    if [ "$VAR" == 1 ]
    then
        echo $'\nGoodbye\n'
        kill -s TERM $TOP_PID #Kill the script and the process ID, which is assigned to TOP_ID
    fi
done

}  

#List all the docker resources requested
list_resources(){
COMMAND=$1

case $COMMAND in
    "List Images")
        echo '===================================================='
        docker images
        echo '===================================================='
        ;;
    "List Containers")
        echo '===================================================='
        docker ps -a
        echo '===================================================='
        ;;
    "List Volumes")
        echo '===================================================='
        docker volume ls
        echo '===================================================='
        ;;
    "List Filtererd Images")
        echo '===================================================='
        docker images --format {{.ID}}
        echo '===================================================='
        ;;
esac
}

inspect_image(){

CONTAINER_IMAGE=$1

read -p $'\nDo you wish to inspect the image? (Y/N): ' INSPECT_IMAGE

# Until the value is either Y or N, ask the customer to retry
until [ "$INSPECT_IMAGE" == "Y" ] || [ "$INSPECT_IMAGE" == "N" ]
do
    read -p $'\nUnrecognized key, please try again: ' INSPECT_IMAGE
done

# Save details to external .txt file if Y
if [ "$INSPECT_IMAGE" == "Y" ]; then 
    mkdir -p ./logs
    TEMP_DOCKER_IMAGE="$(echo ./logs/"$CONTAINER_IMAGE" | tr :- _)" # Change forward slash to underscore to avoid issues when naming file
    if docker image inspect "$CONTAINER_IMAGE" >> "$TEMP_DOCKER_IMAGE"_inspection.txt 2>&1
    then
        echo $'\nDetails saved to '$TEMP_DOCKER_IMAGE'_inspection.log'
    else
        echo "Failed to inspect the image"
    fi
fi
}