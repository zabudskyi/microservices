# Microservices
Prerequisites:
- install docker-ce: https://docs.docker.com/engine/installation/
- install docker-machine: https://docs.docker.com/machine/install-machine/
- install GCloud SDK: https://cloud.google.com/sdk/
  Run `gcloud init` and `gcloud auth application-default login`
## Create your image with reddit app with GCE
1. Create docker-host
```
docker-machine create --driver google \
--google-project <GCE project name> \
--google-zone europe-west1-b \
--google-machine-type f1-micro \
--google-machine-image $(gcloud compute images list --filter ubuntu-1604-lts --uri) \
docker-host
```
2. Set docker variables
```
eval $(docker-machine env docker-host)
```
3. Build docker image
```
docker build -t reddit:latest .
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
