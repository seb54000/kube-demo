## kube-demo deploy

*[Back to README.md](https://github.com/seb54000/kube-demo/tree/master/hello-app/README.md)*

### Write the data in a persistent volume claim

```bash
# Let's see the data written in log file in container
for i in {1..5}; do curl -ks https://hello-app. > /dev/null; done
kubectl exec -it $(kubectl get po -l app=hello-app -o jsonpath={.items..metadata.name}) -- tail /var/www/html/data/hello-app.log

# If we kill the pod, the data are lost
kubectl delete po $(kubectl get po -l app=hello-app -o jsonpath={.items..metadata.name})
kubectl exec -it $(kubectl get po -l app=hello-app -o jsonpath={.items..metadata.name}) -- tail /var/www/html/data/hello-app.log

# Create PVC
kubectl apply -f kube-pvc.yml
kubectl get pvc

# Update deployment to add Volume binding
kubectl apply -f hello-kube-v2-pvc.yml

# Now check again if data are lost ?
for i in {1..5}; do curl -ks https://hello-app > /dev/null; done
kubectl exec -it $(kubectl get po -l app=hello-app -o jsonpath={.items..metadata.name}) -- tail /var/www/html/data/hello-app.log
kubectl delete po $(kubectl get po -l app=hello-app -o jsonpath={.items..metadata.name})
kubectl exec -it $(kubectl get po -l app=hello-app -o jsonpath={.items..metadata.name}) -- tail /var/www/html/data/hello-app.log

# Roll back to previous version (no peristent volume)
kubectl rollout undo deploy/hello-app --to-revision=1
# Logs are gone
kubectl exec -it $(kubectl get po -l app=hello-app -o jsonpath={.items..metadata.name}) -- tail /var/www/html/data/hello-app.log
```

You can of course backup your data and restore them

```bash
# make a compressed archive
kubectl exec -it $(kubectl get po -l app=hello-app -o jsonpath={.items..metadata.name}) -- tar czf backup.tgz .
# Copy it locally
kubectl cp $(kubectl get po -l app=hello-app -o jsonpath={.items..metadata.name}):backup.tgz backup.tgz

# Create a new pod
kubectl delete pod $(kubectl get po -l app=hello-app -o jsonpath={.items..metadata.name})
# Copy archive to it
kubectl cp backup.tgz $(kubectl get po -l app=hello-app -o jsonpath={.items..metadata.name}):backup.tgz
# Restore files
kubectl exec -it $(kubectl get po -l app=hello-app -o jsonpath={.items..metadata.name}) -- tar xzf backup.tgz
```

*[Back to README.md](https://github.com/seb54000/kube-demo/tree/master/hello-app/README.md)*
