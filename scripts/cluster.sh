#!/bin/bash

echo "Checking if Kubernetes is running..."
if ! kubectl get nodes &> /dev/null; then
    echo "Starting Kubernetes cluster..."
    minikube start --driver=docker
fi

echo "Setting up local Docker registry..."
if ! docker ps | grep -q registry; then
    docker run -d -p 5000:5000 --restart=always --name registry registry:2
fi

echo "Configuring Kubernetes to access local registry..."
if ! kubectl get service registry &> /dev/null; then
    kubectl create service clusterip registry --tcp=5000:5000
    kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
spec:
  selector:
    matchLabels:
      app: registry
  replicas: 1
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
      - name: registry
        image: registry:2
        ports:
        - containerPort: 5000
        volumeMounts:
        - name: registry-data
          mountPath: /var/lib/registry
      volumes:
      - name: registry-data
        emptyDir: {}
EOF
fi

echo "Cluster setup completed successfully!"
