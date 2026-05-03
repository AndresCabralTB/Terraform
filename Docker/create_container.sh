#!/bin/bash 
source functions.sh

create_container() {

CONTAINER_NAME=$1
CONTAINER_VOLUME=$2
CONTAINER_PORT=$3
CONTAINER_IMAGE=$4

docker run --name "$CONTAINER_NAME" --restart=on-failure --detach \
  --network jenkins --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 \
  --publish "$CONTAINER_PORT":8080 \
  --volume "$CONTAINER_VOLUME":/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  "$CONTAINER_IMAGE" >> "$SESSION_LOGS" 2>&1

if grep -qi "ERROR" "$SESSION_LOGS"; 
then
  echo "[$(date)] - Failed to create $CONTAINER_NAME" | tee -a "$SESSION_LOGS"
  echo "[$(date)] - Stopping container "$(docker stop "$CONTAINER_NAME")"" >> "$SESSION_LOGS" 
  echo "[$(date)] - Removing container "$(docker rm "$CONTAINER_NAME")"..." >> "$SESSION_LOGS" 
  echo -e "More information in "$SESSION_LOGS"\n"
  exit 1
else
  echo -e "[$(date)] - Container Created Successfully\n" | tee -a "$SESSION_LOGS"
  docker ps -a | grep -i "$CONTAINER_NAME" >> "$SESSION_LOGS" 2>&1
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

inspect_image "$CONTAINER_IMAGE"

read -p $'\nEnter the PORT number to host the container: ' CONTAINER_PORT
CONTAINER_PORT=$(is_empty "$CONTAINER_PORT")

echo $'\nVolumes Available\n'
list_resources "List Volumes"

read -p $'\nEnter the volume where data will be stored\nAvoid using the same volume more than once: ' CONTAINER_VOLUME
CONTAINER_VOLUME=$(is_empty "$CONTAINER_VOLUME")

echo '''
====================================================
CREATING CONTAINER STAGE 2: CREATING THE CONTAINER
====================================================
'''
create_container "$CONTAINER_NAME" "$CONTAINER_VOLUME" "$CONTAINER_PORT" "$CONTAINER_IMAGE"

