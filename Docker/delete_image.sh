#!/bin/bash

source functions.sh

#list_resources "List Filtererd Images"

#Map File is not available on MacOS
#mapfile -t "$my_images" < <(docker images --format "table {{.Repository}}\t{{.ID}}")

my_images=()

#Parse through the output line by line, and appeand each line to the array.  my_images+= is how you append values
while IFS= read -r line; do
    my_images+=( "$line" )
done < <(docker images --format "table {{.Repository}}\t{{.ID}}")

#done < <(docker images --format {{.Repository}})

#echo "My array is: "$my_images""
#echo "my_array[0] = ${my_images[0]}"
#echo "my_array[1] = ${my_images[1]}"
#echo "my_array length = ${#my_images[@]}"

#Remove the first index containing text "Repository, ID"
my_images=("${my_images[@]:1}")


echo -e "
\t======================
\tIMAGE NAME - IMAGE ID
\t======================

"
index=1
for i in ${!my_images[@]};
do
    echo -e " "$index") "${my_images["$i"]}""
    let "index=index+1"
done

read -p "Enter the image ID you wish to delete: " DELETE_IMAGE

until docker rmi "$DELETE_IMAGE" 
do
    if [ ! -z "$DELETE_IMAGE" ]
    then
        read -p "Failed to delete image, try again: " DELETE_IMAGE
    else  
        DELETE_IMAGE=$(is_empty "$DELETE_IMAGE")
    fi
done
echo "Image deleted successfully"
