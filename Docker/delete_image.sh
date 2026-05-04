#!/bin/bash

source functions.sh

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

list_resources "List Images"
read -p $'\nEnter the image ID or Name you wish to delete, or enter 1 to exit: ' DELETE_IMAGE



until [ "$DELETE_IMAGE" == "1" ]; do
	if docker rmi "$DELETE_IMAGE" >>"$SESSION_LOGS" 2>&1; then
		echo -e "\nImage deleted successfully"
        read -p $'\nEnter the image ID or Name you wish to delete, or enter 1 to exit: ' DELETE_IMAGE
	elif [ -z "$DELETE_IMAGE" ]; then
		DELETE_IMAGE=$(is_empty "$DELETE_IMAGE")
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
                read -p $'\nEnter the image ID or Name you wish to delete, or any other key to exit: ' DELETE_IMAGE
			else
				echo "Failed to force delete image '$DELETE_IMAGE'" >&2
			fi
        else
			echo "This is the first exit"
            exit 1
		fi
	else
        read -p $'Error deleting image, try again, or enter 1 to exit: ' DELETE_IMAGE
	fi
done
echo "This is the third exit when user presses 1"
