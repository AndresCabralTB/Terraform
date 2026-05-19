#!/bin/bash
source functions.sh

###################
#    FUNCTIONS    #
###################

create_container() {

echo '''
====================================================
CREATING CONTAINER STAGE 1: SETTING UP THE VARIABLES
====================================================
'''

read -p $'\nEnter the container name: ' CONTAINER_NAME
CONTAINER_NAME=$(is_empty "$CONTAINER_NAME") #Pass value from function
    
#Verify that there are images
docker images
if [ -n "$(docker images -q)" ]; then
  read -p $'\nEnter Image Name you want to use (without the tag): ' CONTAINER_IMAGE
else
  echo -e "\nThere are no images available. Create an Image first"
  exit 1;
fi

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
#Listing flags below:

# --mount -> Mount the source directory (pwd) into the targe /app created in the Dockerfile (Does not auto-create any of them)
CURRENT_DIR=$(pwd)

if docker run --name "$CONTAINER_NAME" --restart=on-failure --detach \
  --network jenkins --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 \
  --publish "$CONTAINER_PORT":8080 \
  --volume "$CONTAINER_VOLUME":/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  --mount "type=bind,source="${CURRENT_DIR}/../..",target=/app/Terraform-Project" \
  "$CONTAINER_IMAGE" >> "$SESSION_LOGS" 2>&1
then
  echo -e "[$(date)] - Container Created Successfully\n" | tee -a "$SESSION_LOGS"
  docker ps -a | grep -i "$CONTAINER_NAME" >> "$SESSION_LOGS" 2>&1
else
  echo "[$(date)] - Failed to create $CONTAINER_NAME" | tee -a "$SESSION_LOGS"
  echo "[$(date)] - Stopping container "$(docker stop "$CONTAINER_NAME")"" >> "$SESSION_LOGS" 
  echo "[$(date)] - Removing container "$(docker rm "$CONTAINER_NAME")"..." >> "$SESSION_LOGS" 
  echo -e "More information in "$SESSION_LOGS"\n"
  exit 1
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

delete_container() {
#list_resources "List Filtererd Images"

#Map File is not available on MacOS
#mapfile -t "$my_images" < <(docker images --format "table {{.Repository}}\t{{.ID}}")

######################################################################
# OPTION 1 - Parse through the images and store them in an array
######################################################################

#my_images=()

#Parse through the output line by line, and appeand each line to the array.  my_images+= is how you append values
#while IFS= read -r line; do
#	my_images+=("$line")
#done < <(docker images --format "table {{.Repository}}\t{{.ID}}")

#done < <(docker images --format {{.Repository}})

#echo "My array is: "$my_images""
#echo "my_array[0] = ${my_images[0]}"
#echo "my_array[1] = ${my_images[1]}"
#echo "my_array length = ${#my_images[@]}"

#Remove the first index containing text "Repository, ID"
#my_images=("${my_images[@]:1}")

#echo -e "
#\t======================
#\tIMAGE NAME - IMAGE ID
#\t======================
#
#"
#index=1
#for i in ${!my_images[@]}; do
#	echo -e " "$index") "${my_images["$i"]}""
#	let "index=index+1"
#done

######################################################################
# OPTION 2 - Simply print all the images with the list_resources function in functions.sh
######################################################################
list_resources "List Containers"
if [ -n "$(docker ps -q)" ];
then
	read -p $'\nEnter the Container Name you wish to delete, or enter 1 to exit: ' DELETE_CONTAINER
	until [ "$DELETE_CONTAINER" == "1" ]; do
		if docker stop "$DELETE_CONTAINER" && docker rm "$DELETE_CONTAINER" >>"$SESSION_LOGS" 2>&1; then
			echo -e "\nContainer Deleted successfully"
			read -p $'\nEnter the Container Name you wish to delete, or enter 1 to exit: ' DELETE_CONTAINER
		elif [ -z "$DELETE_CONTAINER" ]; then
			DELETE_CONTAINER=$(is_empty "$DELETE_CONTAINER")
		else
			read -p $'\nError deleting container, try again, or enter 1 to exit: ' DELETE_CONTAINER
		fi
	done
	exit 1  
else
	echo -e "\nThere are no containers deployed\nGoodbye."
fi
}

access_container() {
echo
if [ -n "$(docker ps -q)" ]; then
  docker ps
  read -p $'\nEnter the Name of the Container you wish to acces: ' CONTAINER_NAME
  CONTAINER_NAME=$(is_empty "$CONTAINER_NAME") 
  if docker exec -it "$CONTAINER_NAME" bash
  then
    echo
    echo -e "[$(date)] - Connection to "$CONTAINER_NAME" Complete" | tee -a "$SESSION_LOGS"
    exit 1
  else
    echo
    echo -e "[$(date)] - Connection to "$CONTAINER_NAME" Failed" | tee -a "$SESSION_LOGS"
    exit
  fi  
else
  echo -e "\nThere are no containers to access. Create a Container first.\nGoodbye."
fi
}

###################
#     MAIN        #
###################
PS3=$'\nEnter the operation you wish to do: '
options=("List Containers" "Create Container" "Delete Container" "Access Container" "Back")

COLUMNS=0 # Display menu in a single column

while true; do
echo -e "
\t======================
\t      CONTAINERS
\t======================
"
	select opt in "${options[@]}"; do
		case $opt in
			"List Containers")
			list_resources "List Containers"
			break
			;;
			"Create Container")
			create_container
			break
			;;
			"Delete Container")
			delete_container
			break
			;;
      "Access Container")
      access_container
      ;;
			"Back")
			exit 1
			;;
			*) echo "Value "$REPLY" not identified. Try again." ;;
		esac
	done
done
