## kube-demo deploy

*[Back to README.md](https://github.com/seb54000/kube-demo/blob/master/README.md)*

### Build and deploy a simple App

We're going to "docker" build and deploy a simple App that will only display some informations

```bash
# Build and push our app
cd hello-app
sudo docker login -u <you-user> -p <your-pwd>
sudo docker build --no-cache -t <your-docker-registry>/hello-app:v1 .
sudo docker push <your-docker-registry>/hello-app:v1

# Create Namespace
kubectl create ns kube-kubedemo
# Deploy our app on Kubernetes
kubectl apply -f hello-kube-v1.yml
```

The app will be available at Service LoadBalancer Endpoint, you can get it this way :

```bash
kubectl get service -n kube-kubedemo hello-app-svc -o json | jq -r '.status.loadBalancer.ingress[].hostname'
```

Point you browser to this adress (prefix it with http://)
Cloud provider LoadBalancer may take some time to start (don't hesitate to check the cloud provider API to verify state)

*[Back to README.md](https://github.com/seb54000/kube-demo/blob/master/README.md)*
