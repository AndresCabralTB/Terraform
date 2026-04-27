docker run --name mydocker-container-v11-4040 --restart=on-failure --detach \
  --network jenkins --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 --env JENKINS_OPTS="--httpPort=4040" \
  --publish 4040:4040 --publish 60000:60000 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  docker-images-v11:latest
