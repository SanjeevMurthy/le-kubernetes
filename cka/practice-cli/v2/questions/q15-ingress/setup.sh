#!/bin/bash
set -e
# Q15 — Create an Ingress Resource: Setup

# Create namespace
kubectl create namespace echo-app &>/dev/null

# Create deployment with echoserver image
kubectl create deployment api-server --image=registry.k8s.io/echoserver:1.10 --port=8080 -n echo-app &>/dev/null

# Create service
kubectl expose deployment api-server --name=api-service --port=8080 --target-port=8080 -n echo-app &>/dev/null
