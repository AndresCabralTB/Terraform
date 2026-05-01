#!/bin/bash 

trap "Exit 1" TERM
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
echo "$VAR"
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
esac
}