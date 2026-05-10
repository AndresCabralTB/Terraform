#!/bin/bash
source functions.sh
export PIDP=$$
export SESSION_LOGS=$(echo ./logs/session_"$PIDP".logs | tr :- _)
chmod +rx ./*.sh
echo "
=================================
WELCOME TO DOCKER CONFIGURATIONS
==================================
"
echo "Session ID: "$PIDP""
mkdir -p "./logs"
SESSION_LOGS=$(echo ./logs/session_"$PIDP".logs | tr :- _)
touch "$SESSION_LOGS"
echo "$(date)" >> "$SESSION_LOGS"

PS3=$'\nChose an option: '
startup_options=("List Images" "List Containers" "List Volumes" "Create Image" "Create Container" "Delete Image" "Delete Container" "Access Container" "Exit")

COLUMNS=0 # Display menu in a single column

while true; do
echo -e "
\t======================
\t      MAIN MENU
\t======================
"
    select opt in "${startup_options[@]}"; do
    #@ means "all elements" of the array.
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
                ./images.sh "Create"
                break
                ;;
            "Create Container")
                ./containers.sh "Create"
                break
                ;;
            "Delete Image")
                ./images.sh "Delete"
                break
                ;;
            "Delete Container")
                ./containers.sh "Delete"
                break
                ;;
            "Access Container")
                ./containers.sh "Access"
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


