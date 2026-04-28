CONTAINER_NAME=$1
IMAGE_NAME=$2
PORT=$3

if [ -z "$USER" ] || [ -z "$BASE_OVPN" ]; then
  echo "Usage: ./Container-Startup.sh <container_name> <image_name:tag> <port>"
  exit 1
fi

docker run --name $CONTAINER_NAME --restart=on-failure --detach \
  --network jenkins --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 --env JENKINS_OPTS="--httpPort=$PORT" \
  --publish $PORT:$PORT --publish 60000:60000 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  $IMAGE_NAME
