#!/bin/bash
# Q15 — Update NGINX ConfigMap to Add TLSv1.2 + Make Immutable: Setup
set -e

echo "Creating namespace: nginx-static"
kubectl create namespace nginx-static --dry-run=client -o yaml | kubectl apply -f -

echo "Creating self-signed TLS certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=ckaquestion.k8s.local" 2>/dev/null
kubectl -n nginx-static create secret tls nginx-tls \
  --cert=/tmp/tls.crt --key=/tmp/tls.key \
  --dry-run=client -o yaml | kubectl apply -f -
rm -f /tmp/tls.crt /tmp/tls.key

echo "Creating ConfigMap with TLSv1.3 only..."
cat <<EOF | kubectl -n nginx-static apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    events {}
    http {
      server {
        listen 443 ssl;
        ssl_certificate /etc/nginx/tls/tls.crt;
        ssl_certificate_key /etc/nginx/tls/tls.key;
        ssl_protocols TLSv1.3;
        location / {
          return 200 "Hello TLS\n";
        }
      }
    }
EOF

echo "Deploying nginx with ConfigMap and TLS mounts..."
cat <<EOF | kubectl -n nginx-static apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-static
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-static
  template:
    metadata:
      labels:
        app: nginx-static
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
        - name: tls
          mountPath: /etc/nginx/tls
      volumes:
      - name: config
        configMap:
          name: nginx-config
      - name: tls
        secret:
          secretName: nginx-tls
EOF

echo "Creating ClusterIP service..."
cat <<EOF | kubectl -n nginx-static apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx-static
  ports:
  - port: 443
    targetPort: 443
EOF

echo ""
echo "Setup complete!"
echo "  - Namespace: nginx-static"
echo "  - ConfigMap: nginx-config (TLSv1.3 only)"
echo "  - Secret: nginx-tls"
echo "  - Deployment: nginx-static"
echo "  - Service: nginx-service (ClusterIP:443)"
echo ""
echo "Your tasks:"
echo "  1. Add TLSv1.2 support to the ConfigMap (keep TLSv1.3)"
echo "  2. Make the ConfigMap immutable"
echo "  3. Add the service IP to /etc/hosts as ckaquestion.k8s.local"
echo "  4. Verify with curl commands"
