#!/bin/bash
source functions.sh

echo "
=================================
WELCOME TO DOCKER CONFIGURATIONS
==================================
"

PS3=$'\nChose an option: '
startup_options=("List Images" "List Containers" "List Volumes" "Create Image" "Create Container" "Delete Image" "Delete Container" "Exit")

COLUMNS=0 # Display menu in a single column

while true; do
echo -e "
\t======================
\t      MAIN MENU
\t======================
"
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
                ./create_image.sh
                break
                ;;
            "Create Container")
                ./create_container.sh
                break
                ;;
            "Delete Image")
                ./delete_image.sh
                break
                ;;
            "Delete Container")
                #echo  "To be released" 
                read -p "Enter test value: " TEST_VAL
                TEST_VAL=$(is_empty "$TEST_VAL")
                echo "TEST_VAL = "$TEST_VAL""
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

