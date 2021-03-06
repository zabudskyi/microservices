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
docker run -d --network=reddit -v reddit_db:/data/db --network-alias=post_db_container --network-alias=comment_db_container mongo:latest
docker run -d --network=reddit --network-alias=post_container <your-login>/post:1.0
docker run -d --network=reddit --network-alias=comment_container <your-login>/comment:1.0
docker run -d --network=reddit -p 9292:9292 <your-login>/ui:2.2
```
### Run ui and db containers in separate networks
Prerequisites:
- create networks:
```
docker network create front_net --subnet=10.0.1.0/24
docker network create back_net --subnet=10.0.2.0/24
```
1. Run db, comment and post containers in `back_net` network and ui container in `front_net`
```
docker run -d --network=back_net --name mongodb -v reddit_db:/data/db \
              --network-alias=comment_db_container --network-alias=post_db_container mongo:latest
docker run -d --network=back_net --name post --network-alias=post_container <your-login>/post:1.0
docker run -d --network=back_net --name comment --network-alias=comment_container <your-login>/comment:1.0
docker run -d --network=front_net --name ui -p 9292:9292 <your-login>/ui:2.2
```
2. Connect post and comment containers to `front_net`:
```
docker network connect front_net post
docker network connect front_net comment
```
## Run app with docker-compose
### Prerequisites:
Fill`.env.example` with your variables and rename it to `.env`

Build the images:
- ui, post and comment (use `docker_build.sh` script in appropriate folders)
- mongodb exporter container (https://github.com/dcu/mongodb_exporter)
- prometheus `docker build -t <your-login>/prometheus prometheus/`
- alertmanager
Modify alertmanager/config.yml with slack webhook info and run `docker build -t <your-login>/alertmanager alertmanager/`
### Run docker-compose
```
docker-compose up -d
```
Yes, so easy
## Run app with docker swarm
### Init docker swarm master
```
docker swarm init
```
### Join docker swarm workers
```
docker swarm join --token <your-token> <manager address>:2377
```
### Run app
Tune deploy options in `docker-compose-swarm.service.yml` file
```
docker stack deploy --compose-file=<(docker-compose -f docker-compose-swarm.infra.yml -f docker-compose-swarm.service.yml config 2>/dev/null)  DEV
```
### Remove app
```
docker stack rm DEV
```
## Run app with kubernetes
### Prerequisites:
Install kubectl
```
wget https://storage.googleapis.com/kubernetes-release/release/v1.8.0/bin/linux/amd64/kubectl
```
```
chmod +x kubectl
```
```
sudo mv kubectl /usr/local/bin/
```
### Run app:
```
kubectl apply -f kubernetes/
```
### Run app with minikube
Install virtualbox(not described here) and minikube
```
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.23.0/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
```
Start minikube
```
minikube start
```
Run app
```
kubectl apply -f kubernetes/
```
## Run app with GKE and Terraform
### GCE Service account key
Place your GCP Service account key at `kubernetes/terraform` folder and name it `gce_account.json`. Terraform will use it for Google cloud authentication.
 [Check this link](https://cloud.google.com/iam/docs/creating-managing-service-account-keys)
### Create Kubernetes cluster with Terraform (go to kubernetes/terraform folder)
Fill `terraform.tfvars.example` with desired values, remove `.example` part and run `terraform apply`
### Create `dev` environment, add tls support and setup service account for kubernetes dashboard
Put your secrets to `ui-ingress-secret.yml.example` and remove `.example` part
You can create these secrets from a file containing your SSL cert/key like so:
```
openssl base64 -in tls.key -out tls.key.b64
openssl base64 -in tls.crt -out tls.crt.b64
```
Just remember to strip newlines after encoding to base64. Kubernetes secrets doesn’t play nice with newlines.
And then apply prerequisites manifests.
```
kubectl apply -f prerequisites/
```
### Run app with kubernetes in `dev` environment
```
kubectl apply -f ./ -n dev
```
Run `kubectl proxy` and access kubernetes dashboard at `http://127.0.0.1:8001/ui`. Here you can find proxy port for ui service or just run
`kubectl describe service ui  -n dev  | grep NodePort`
## Run app with Helm 
[Install Helm](https://github.com/kubernetes/helm/releases)
Launch tiller server
```
kubernetes$ kubectl  apply -f helm/tiller.yml && helm init --service-account tiller
```
Install app with helm
```
kubernetes$ helm install --name reddit charts/reddit/
```
### UPDATE
Run `kubectl get ingress -n dev` to achieve ui service ingress IP. Access app with link `https://INGRESS_IP`
## Debugging
1. Be sure you are in required docker environment and issued
   ```
   eval $(docker-machine env docker-host)
   ```
   ssh to docker-host to check containers are run there `docker-machine ssh docker-host "docker ps"`
2. Check logs and attach to container to verify all is run as expected.   
```
docker run -d --name=logtest --network=reddit -p 9292:9292 <your-login>/ui:2.2
docker logs logtest
docker attach logtest
```
3. Run some commands in running container `docker exec -ti microservices_post_1 sh -c "ifconfig"`
4. To rebuild images with docker-compose run `docker-compose build` and then `docker-compose up -d` to make changes.
## Monitoring services
- prometheus (available at 9090 port)
- cAdvisor (available at 8080 port)
- Grafana (available at 3000 port)
Admin username and password can be specified in grafana docker-copmpose section
```
environment:
  - GF_SECURITY_ADMIN_USER=admin
  - GF_SECURITY_ADMIN_PASSWORD=secret
```
Import dashboards from the directory with the same name
