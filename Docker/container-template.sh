CONTAINER_NAME=$1
CONTAINER_VOLUME=$2
CONTAINER_PORT=$3
CONTAINER_IMAGE=$4

docker run --name "$CONTAINER_NAME" --restart=on-failure --detach \
  --network jenkins --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 \
  --publish "$CONTAINER_PORT":8080 \
  --volume "$CONTAINER_VOLUME":/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  "$CONTAINER_IMAGE"