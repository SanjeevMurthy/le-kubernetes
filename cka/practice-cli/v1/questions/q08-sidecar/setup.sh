#!/bin/bash
# Q9 — Add Sidecar Container to Deployment: Setup
set -e

echo "Creating WordPress deployment (without sidecar or shared volume)..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  labels:
    app: wordpress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      containers:
      - name: wordpress
        image: wordpress:php8.2-apache
        command: ["/bin/sh", "-c", "while true; do echo 'WordPress is running...' >> /var/log/wordpress.log; sleep 5; done"]
        ports:
        - containerPort: 80
EOF

echo "Creating WordPress service..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: wordpress
spec:
  selector:
    app: wordpress
  ports:
  - port: 80
    targetPort: 80
EOF

echo ""
echo "Setup complete!"
echo ""
echo "Your tasks:"
echo "  1. Add a sidecar container named 'sidecar' using busybox:stable"
echo "  2. Sidecar command: /bin/sh -c tail -f /var/log/wordpress.log"
echo "  3. Use an emptyDir volume mounted at /var/log for both containers"
echo "  4. Pods should show 2/2 Ready after the change"
