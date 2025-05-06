#!/bin/bash

echo "Setting up environment..."
./scripts/setup-cluster.sh

mkdir -p ai-application/backend
mkdir -p ai-application/frontend

cp chat-app/mysql/init.sql chat-app/mysql/

echo "Building chat components..."
./scripts/chat-build.sh

echo "Building AI components..."
./scripts/ai-build.sh

echo "Tagging images for local registry..."
./scripts/chat-tag.sh
./scripts/ai-tag.sh

echo "Pushing images to local registry..."
./scripts/chat-push.sh
./scripts/ai-push.sh

echo "Checking Kubernetes status..."
kubectl get nodes

echo "Applying Kubernetes manifests..."

kubectl apply -f kubernetes/secrets.yaml

kubectl apply -f kubernetes/persistent-volumes.yaml

kubectl apply -f kubernetes/chat-mysql.yaml
kubectl apply -f kubernetes/joomla-mysql.yaml

echo "Waiting for databases to be ready..."
sleep 30

kubectl apply -f kubernetes/chat-backend.yaml
kubectl apply -f kubernetes/chat-frontend.yaml
kubectl apply -f kubernetes/ai-backend.yaml
kubectl apply -f kubernetes/ai-frontend.yaml
kubectl apply -f kubernetes/joomla.yaml

echo "Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod --all --timeout=300s

echo "Service Information:"
kubectl get services

JOOMLA_IP=$(kubectl get service joomla -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$JOOMLA_IP" ]; then
  JOOMLA_IP=$(kubectl get service joomla -o jsonpath='{.spec.clusterIP}')
fi

echo ""
echo "======================================================"
echo "Deployment complete!"
echo "======================================================"
echo "Joomla CMS is available at: http://$JOOMLA_IP"
echo "Chat Service is available at: http://$JOOMLA_IP/chat.html"
echo "AI Service is available at: http://$JOOMLA_IP/ai.html"
echo "======================================================"
echo "You'll need to complete the Joomla setup through the web interface"
echo "and add iframes for the chat and AI applications."
echo "Chat iframe URL: http://chat-frontend:90"
echo "AI iframe URL: http://ai-frontend:94"
echo "======================================================"
