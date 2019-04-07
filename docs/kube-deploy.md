## kube-demo deploy

*[Back to README.md](https://github.com/seb54000/kube-demo/tree/master/hello-app/README.md)*

### Build and deploy a simple App

We're going to "docker" build and deploy a simple App that will only display some informations

```bash
# Build and push our app
cd hello-app
sudo docker build --no-cache -t <your-docker-registry>/hello-app:v1 .
sudo docker push <your-docker-registry>/hello-app:v1

# Deploy our app on Kubernetes
kubectl apply -f hello-kube-v1.yml
```

The app will be available at : https://hello-app/


*[Back to README.md](https://github.com/seb54000/kube-demo/tree/master/hello-app/README.md)*
