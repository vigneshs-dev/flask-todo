#!bin/bash/

# exit when any command fails
set -e

# This script is used to deploy the application to a Kubernetes cluster.
kubectl apply -f k8s-manifests/mysql-configmap.yml
kubectl apply -f k8s-manifests/mysql-deployment.yml


# Apply k8s-manifest/flash-deployment.yml file, once the mysql-deployment is up and running
# Wait for mysql-deployment to be up and running
while [[ $(kubectl get pods -l app=mysql -o jsonpath='{.items[0].status.phase}') != "Running" ]]; do
  echo "Waiting for mysql-deployment to be up and running..."
  sleep 5
done

# Sleep for 10 seconds to ensure mysql is up and running
echo "mysql-deployment is up and running, sleeping for 10 seconds..."
sleep 10

# Apply the flash-deployment.yml file
echo "mysql-deployment is up and running, applying flash-deployment.yml..."
# Apply the flash-deployment.yml file
kubectl apply -f k8s-manifests/flask-deployment.yml

# Once the flash-deployment is up and running, port-forward the flash-deployment to localhost:5000
while [[ $(kubectl get pods -l app=flask-todo -o jsonpath='{.items[0].status.phase}') != "Running" ]]; do
  echo "Waiting for flask-deployment to be up and running..."
  sleep 5
done

# Sleep for 10 seconds to ensure flask is up and running
echo "flask-deployment is up and running, sleeping for 10 seconds..."
sleep 10

# Port-forward the flash-deployment to localhost:5000
echo "flask-deployment is up and running, port-forwarding to localhost:5000..."
kubectl port-forward svc/flask-service 5000:5000