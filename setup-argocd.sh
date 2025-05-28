#!/bin/bash

# Set namespace
NAMESPACE="argocd"

# Create namespace
echo "Creating namespace: $NAMESPACE"
kubectl create namespace $NAMESPACE

# Install ArgoCD
echo "Installing ArgoCD"
kubectl apply -n $NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD components to be ready
echo "Waiting for ArgoCD components to be ready..."
kubectl rollout status deployment/argocd-server -n $NAMESPACE
kubectl rollout status deployment/argocd-repo-server -n $NAMESPACE
kubectl rollout status deployment/argocd-application-controller -n $NAMESPACE
kubectl rollout status deployment/argocd-dex-server -n $NAMESPACE

# Change the service type to LoadBalancer
echo "Updating argocd-server service to use LoadBalancer"
kubectl patch svc argocd-server -n $NAMESPACE -p '{"spec": {"type": "LoadBalancer"}}'

# Wait for LoadBalancer to get an external IP
echo "Waiting for LoadBalancer to get an external IP..."
while true; do
  EXTERNAL_IP=$(kubectl get svc argocd-server -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  if [ -n "$EXTERNAL_IP" ]; then
    break
  fi
  echo "Waiting for external IP..."
  sleep 10
done

echo "ArgoCD is accessible at: http://$EXTERNAL_IP"

# Retrieve initial admin password
echo "Retrieving initial admin password..."
ADMIN_PASSWORD=$(kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Initial admin password: $ADMIN_PASSWORD"

echo "Setup complete. Please log in to ArgoCD using the external IP and initial admin password."
