#!/bin/bash
source functions.sh

###################
#    FUNCTIONS    #
###################

create_image(){
echo '''
================================================
CREATING IMAGE STAGE 1: SETTING UP THE VARIABLES
================================================
'''
read -p $'\nEnter the Image Name: ' IMAGE_NAME
IMAGE_NAME=$(is_empty "$IMAGE_NAME")

read -p $'\nImage Tag (press enter for default 'latest'): ' IMAGE_TAG
    
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


delete_image() {
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


if [ -n "$(docker images -q)" ]
then
	docker images
    read -p $'\nEnter the image ID or Name you wish to delete, or enter 1 to exit: ' DELETE_IMAGE
	DELETE_IMAGE=$(is_empty "$DELETE_IMAGE")
	
	until [ "$DELETE_IMAGE" == "1" ]; do
		if docker rmi "$DELETE_IMAGE" >>"$SESSION_LOGS" 2>&1; then
			echo -e "\nImage deleted successfully"
			read -p $'\nEnter the image ID or Name you wish to delete, or enter 1 to exit: ' DELETE_IMAGE
		elif docker rmi "$DELETE_IMAGE" 2>&1 | grep "container"; then
			PARENT_CONTAINERS=($(docker ps -q --filter ancestor="$DELETE_IMAGE"))
			# Format for display: join IDs with ", "
			CONTAINER_LIST=$(IFS=', '; echo "${PARENT_CONTAINERS[*]}")
			read -p $'\nImage is in use by containers: '"$CONTAINER_LIST"$'\nDo you wish to force delete? (Press Y to delete, or any other key to exit): ' FORCE_DELETE_IMAGE	
			if [ "$FORCE_DELETE_IMAGE" == "Y" ]; then
				for CONTAINER in "${PARENT_CONTAINERS[@]}";do
					docker stop "$CONTAINER" && docker rm "$CONTAINER" 
				done
				if docker rmi "$DELETE_IMAGE"; then
					echo "Image '$DELETE_IMAGE' successfully deleted"
					exit 1;
				else
					echo "Failed to force delete image '$DELETE_IMAGE'" >&2
				fi
			else
				exit 1
			fi
		elif docker rmi "$DELETE_IMAGE" 2>&1 | grep -i "no such image"; then
			read -p $'\nNo such Image, try again, or enter 1 to exit: ' DELETE_IMAGE
		else
			echo -e "\nError deleting Image. Review logs"
		fi
	done
else 
    echo -e "\nThere are no images to delete.\nGoodbye."
fi
}

###################
#     MENU        #
###################

PS3=$'\nEnter the operation you wish to do: '
options=("List Images" "Create Image" "Delete Image" "Back")

COLUMNS=0 # Display menu in a single column

while true; do
echo -e "
\t======================
\t      IMAGES
\t======================
"
	select opt in "${options[@]}"; do
		case $opt in
			"List Images")
			list_resources "List Images"
			break
			;;
			"Create Image")
			create_image
			break
			;;
			"Delete Image")
			delete_image
			break
			;;
			"Back")
			exit 1
			;;
			*) echo "Value "$REPLY" not identified. Try again." ;;
		esac
	done
done
