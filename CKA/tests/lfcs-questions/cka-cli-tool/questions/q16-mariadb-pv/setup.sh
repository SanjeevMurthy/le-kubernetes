#!/bin/bash
# Q17 — PVC Bind to PV + Restore MariaDB Deployment: Setup
set -e

echo "Creating namespace: mariadb"
kubectl create ns mariadb --dry-run=client -o yaml | kubectl apply -f -

echo "Creating PersistentVolume: mariadb-pv"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mariadb-pv
  labels:
    app: mariadb
spec:
  capacity:
    storage: 250Mi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data/mariadb
EOF

echo "Creating initial PVC and deployment..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb
  namespace: mariadb
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 250Mi
EOF

cat <<'DEPLOY' > ~/mariadb-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
  namespace: mariadb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
      - name: mariadb
        image: mariadb:10.6
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: rootpass
        volumeMounts:
        - name: mariadb-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mariadb-storage
        persistentVolumeClaim:
          claimName: mariadb
DEPLOY

kubectl apply -f ~/mariadb-deploy.yaml

echo "Waiting for MariaDB pod to start..."
kubectl wait --for=condition=Available deployment/mariadb -n mariadb --timeout=60s 2>/dev/null || true

echo "Simulating accidental deletion of deployment and PVC..."
kubectl delete deployment mariadb -n mariadb --ignore-not-found
kubectl delete pvc mariadb -n mariadb --ignore-not-found

echo "Resetting PV for reuse (clearing stale claimRef)..."
claim_ref=$(kubectl get pv mariadb-pv -o jsonpath='{.spec.claimRef.name}' 2>/dev/null || true)
if [ -n "$claim_ref" ]; then
  kubectl patch pv mariadb-pv --type=json -p '[{"op":"remove","path":"/spec/claimRef"}]'
fi

# Overwrite deployment manifest with empty claimName for student to fill
cat <<'DEPLOY' > ~/mariadb-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
  namespace: mariadb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
      - name: mariadb
        image: mariadb:10.6
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: rootpass
        volumeMounts:
        - name: mariadb-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mariadb-storage
        persistentVolumeClaim:
          claimName: ""
DEPLOY

echo ""
echo "Setup complete!"
echo "  - PV retained and Available for reuse"
echo "  - Namespace: mariadb"
echo "  - Deployment manifest at ~/mariadb-deploy.yaml (claimName is empty)"
echo ""
echo "Your tasks:"
echo "  1. Create PVC 'mariadb' (250Mi, ReadWriteOnce) in mariadb namespace"
echo "  2. Edit ~/mariadb-deploy.yaml to set the correct claimName"
echo "  3. Apply the deployment and ensure it is running"
