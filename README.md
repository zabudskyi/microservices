# Microservices
Prerequisites:
- install docker-ce: https://docs.docker.com/engine/installation/
- install docker-machine: https://docs.docker.com/machine/install-machine/
- install GCloud SDK: https://cloud.google.com/sdk/
  Run `gcloud init` and `gcloud auth application-default login`
## Create image and run container with GCE (Monolith)
1. Create docker-host
```
docker-machine create --driver google \
--google-project <GCE project name> \
--google-zone europe-west1-b \
--google-machine-type g1-small \
--google-machine-image $(gcloud compute images list --filter ubuntu-1604-lts --uri) \
docker-host
```
2. Set docker variables
```
eval $(docker-machine env docker-host)
```
3. Build docker image
```
docker build -t reddit:latest monolith/
```
4. Run container
Don't forget to add firewall rule `tcp:9292` for `docker-machine` tag
```
docker run --name reddit -d --network=host reddit:latest
```
5. Upload image to your docker hub account
```
docker login
docker tag reddit:latest <your-login>/<your-image-name>
docker push <your-login>/<your-image-name>
```
6. Remove docker machine
```
docker-machine rm docker-host
```
## Run app from separate containers
Prerequisites:
- pull mongodb image: `docker pull mongo:latest`
- create docker network for app: `docker network create reddit`
- build images:
```
docker build -t <your-login>/post:1.0 ./post-py
docker build -t <your-login>/comment:1.0 ./comment
docker build -t <your-login>/ui:2.2 ./ui
```
- create volume so data remains after container restarts: `docker volume create reddit_db`
Run app
```
docker run -d --network=reddit -v reddit_db:/data/db --network-alias=post_db --network-alias=comment_db_container mongo:latest
docker run -d --network=reddit --network-alias=post_container <your-login>/post:1.0
docker run -d --network=reddit --network-alias=comment_container <your-login>/comment:1.0
docker run -d --network=reddit -p 9292:9292 <your-login>/ui:2.2
```
## Debugging container
```
docker run -d --name=logtest --network=reddit -p 9292:9292 coul/ui:2.2
docker logs logtest
docker attach logtest
```
