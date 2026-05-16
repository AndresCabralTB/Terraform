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

PS3=$'\nWhat do you wish to work with: '
startup_options=("Images" "Containers" "Volumes" "Exit")

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
            "Images")
                ./images.sh
                break
                ;;
            "Containers")
                ./containers.sh
                break
                ;;
            "Volumes")
                ./volumes.sh                 
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


