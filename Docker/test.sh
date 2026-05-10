#!/bin/bash

PS3="Enter a value:"
animals=("Dog" "Cat" "Shark" "Girrafe")

echo "${animals[@]}"
echo
for animal in "${animals[@]}"; do
    echo "The animal is: "$animal""
done

select option in "${animals[@]}"; do
    case $option in
        "Dog")
            echo "Dog"
            ;;
        "Cat")
            echo "Cat"
            ;;
        "Shark")
            echo "Shark"
            ;;
        "Girrafe")
            echo "Girrafe"
            ;;
        *) echo "Option not avaible";;
    esac
done
    