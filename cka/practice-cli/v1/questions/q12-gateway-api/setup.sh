#!/bin/bash
# Q13 — Migrate Ingress to Gateway API + TLS: Setup
set -e

echo "Installing Gateway API CRDs (v1.1.0)..."
kubectl apply -k "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.1.0" >/dev/null

echo "Creating web deployment..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx
        ports:
        - containerPort: 80
EOF

echo "Creating web service..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web
  ports:
  - name: http
    port: 80
    targetPort: 80
EOF

echo "Creating TLS certificate and secret..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/tls.key -out /tmp/tls.crt \
  -subj "/CN=gateway.web.k8s.local/O=web" >/dev/null 2>&1
kubectl create secret tls web-tls --cert=/tmp/tls.crt --key=/tmp/tls.key \
  --dry-run=client -o yaml | kubectl apply -f - >/dev/null
rm -f /tmp/tls.crt /tmp/tls.key

echo "Creating existing Ingress resource (to migrate from)..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  tls:
  - hosts:
    - gateway.web.k8s.local
    secretName: web-tls
  rules:
  - host: gateway.web.k8s.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
EOF

echo "Creating GatewayClass: nginx-class"
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx-class
spec:
  controllerName: example.net/nginx-gateway-controller
EOF

echo ""
echo "Setup complete!"
echo "  - Deployment: web-deployment"
echo "  - Service: web-service"
echo "  - Secret: web-tls"
echo "  - Ingress: web (existing, to migrate from)"
echo "  - GatewayClass: nginx-class"
echo ""
echo "Your tasks:"
echo "  1. Create Gateway 'web-gateway' with TLS using web-tls secret"
echo "  2. Create HTTPRoute 'web-route' pointing to web-service"
