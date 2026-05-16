#!/bin/bash
source functions.sh

create_volume(){
    read -p $'\nEnter the volume name: ' VOLUME_NAME
}

delete_volume(){
    echo
    docker volume ls
    read -p $'\nEnter the volume you wish to delete: ' DELETE_VOLUME
    DELETE_VOLUME=$(is_empty "$DELETE_VOLUME")

    until [ "$DELETE_VOLUME" == "1" ]; do
        if [ -n "$(docker volume ls)" ]; then
        if docker volume rm "$DELETE_VOLUME" >> "$SESSION_LOGS" 2>&1
        then
            echo -e "\nVolume "$DELETE_VOLUME" successfully deleted" | tee -a "$SESSION_LOGS"
            read -p $'\nEnter the volume you wish to delete: ' DELETE_VOLUME
        elif docker volume rm "$DELETE_VOLUME" 2>&1 | grep -i "is in use"; then
            #docker ps -q --filter volume="$DELETE_VOLUME"
            PARENT_CONTAINERS=$(docker ps -q --filter volume="$DELETE_VOLUME")
            CONTAINERS_LIST=$(IFS=', '; echo "${PARENT_CONTAINERS[*]}")
            read -p $'\nVolume is in use by containers: '"$CONTAINERS_LIST"$'\nDo you wish to force delete? (Press Y to delete, or any other key to exit): ' FORCE_DELETE_VOLUME	
            
            if [ "$FORCE_DELETE_VOLUME" == "Y" ]; then
                for container in "${CONTAINERS_LIST[@]}"; do
                    if docker stop "$container" && docker rm "$container"; then
                        if docker volume rm "$DELETE_VOLUME" >> "$SESSION_LOGS" 2>&1; then
                            echo -e "\nVolume "$DELETE_VOLUME" successfully deleted" | tee -a "$SESSION_LOGS"
                        else
                            echo -e "\nFailed to delete "$DELETE_VOLUME". More information on "$SESSION_LOGS"" | tee -a "$SESSION_LOGS"
                        fi
                    else
                        echo -e "\nFailed to delete "$DELETE_VOLUME". More information on "$SESSION_LOGS"" | tee -a "$SESSION_LOGS"
                    fi
                done
            else
                echo -e "\nGoodbye"
                exit 1
            fi
            elif docker volume rm "$DELETE_VOLUME" 2>&1 | grep -i "no such volume"; then
                read -p $'\nNo such Volume, try again, or enter 1 to exit: ' DELETE_VOLUME
            else
                echo -e "\nError deleting Volume. Review logs"
                exit 1
            fi
        else
            echo -e "\nThere are no Volumes to delete.\nGoodbye."
        fi                                  
    done
}

###################
#     MAIN        #
###################
PS3=$'\nEnter the operation you wish to do: '
options=("List Volumes" "Create Volume" "Delete Volume" "Back")

COLUMNS=0 # Display menu in a single column

while true; do
echo -e "
\t======================
\t      VOLUMES
\t======================
"
	select opt in "${options[@]}"; do
		case $opt in
			"List Volumes")
			list_resources "List Volumes"
			break
			;;
			"Create Volume")
			create_volume
			break
			;;
			"Delete Volume")
			delete_volume
			break
			;;
			"Back")
			exit 1
			;;
			*) echo "Value "$REPLY" not identified. Try again." ;;
		esac
	done
done
