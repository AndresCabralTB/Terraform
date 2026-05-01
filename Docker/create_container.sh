#!/bin/bash 
source functions.sh

create_container() {

CONTAINER_NAME=$1
CONTAINER_VOLUME=$2
CONTAINER_PORT=$3
CONTAINER_IMAGE=$4
CONTAINER_LOG=$5

docker run --name "$CONTAINER_NAME" --restart=on-failure --detach \
  --network jenkins --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 \
  --publish "$CONTAINER_PORT":8080 \
  --volume "$CONTAINER_VOLUME":/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  "$CONTAINER_IMAGE" >> "$CONTAINER_LOG" 2>&1

if grep -qi "ERROR" "$CONTAINER_LOG"; 
then
  echo "Failed to create $CONTAINER_NAME" | tee -a "$CONTAINER_LOG"
  echo "Stopping container "$(docker stop "$CONTAINER_NAME")"" >> "$CONTAINER_LOG" 
  echo "Removing container "$(docker rm "$CONTAINER_NAME")"..." >> "$CONTAINER_LOG" 
  echo -e "More information in "$CONTAINER_LOG"\n"
  exit 1
else
  echo -e "Container Created Successfully\n" | tee -a "$CONTAINER_LOG"
  docker ps -a | grep -i "$CONTAINER_NAME" >> "$CONTAINER_LOG" 2>&1
fi
#NGROK DISABLED FOR NOW

#echo $'\nStarting NGROK...\n'
#ngrok config add-authtoken "$NGROK_AUTHTOKEN"

#if ngrok http "$CONTAINER_PORT"; then
#  echo $'\nSuccessfully started NGROK'
#else
#  echo -e "\nFailed to start NGROK on $CONTAINER_PORT"
#  echo $'\nGoodbye\n'
#  exit 1
#fi
}


echo '''
====================================================
CREATING CONTAINER STAGE 1: SETTING UP THE VARIABLES
====================================================
'''

read -p $'\nEnter the container name: ' CONTAINER_NAME
CONTAINER_NAME=$(is_empty "$CONTAINER_NAME") #Pass value from function
    
echo -e "\nSelect the Docker Image you want to use"
list_resources "List Images"
read -p $'\nEnter Image Name (without the tag): ' CONTAINER_IMAGE

#Review if image exists
until docker image inspect "$CONTAINER_IMAGE" > /dev/null 2>&1
  do
    read -p $'\nImage does not exist, try again: ' CONTAINER_IMAGE

    if [ -z "$CONTAINER_IMAGE" ]
    then
      CONTAINER_IMAGE=$(is_empty "$CONTAINER_IMAGE")
    fi
  done

read -p $'\nEnter the PORT number to host the container: ' CONTAINER_PORT
CONTAINER_PORT=$(is_empty "$CONTAINER_PORT")

echo $'\nVolumes Available\n'
list_resources "List Volumes"

read -p $'\nEnter the volume where data will be stored\nAvoid using the same volume more than once: ' CONTAINER_VOLUME
CONTAINER_VOLUME=$(is_empty "$CONTAINER_VOLUME")

echo '''
====================================================
CREATING CONTAINER STAGE 2: CREATING THE LOG FILE
====================================================
'''
#Create variable to define the container startup log
mkdir -p ./logs/
CONTAINER_LOG=$(echo ./logs/"$CONTAINER_NAME"_startup.log | tr :- _)
touch $CONTAINER_LOG > /dev/null 2>&1
echo -e "Log file "$CONTAINER_LOG" created successfully\n" && chmod +rwx "$CONTAINER_LOG"
    
echo '''
====================================================
CREATING CONTAINER STAGE 3: CREATING THE CONTAINER
====================================================
'''
create_container "$CONTAINER_NAME" "$CONTAINER_VOLUME" "$CONTAINER_PORT" "$CONTAINER_IMAGE" "$CONTAINER_LOG"

