#!/bin/bash
# Q35 Cilium L7: an HTTP service that answers /health with 200 and every other
# path with 404, a client that has curl, and no policy at all to start with.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_tool kubectl

NS=cilium-lab

CNI=$(detect_cni)
if [[ "$CNI" != cilium ]]; then
  echo "This question needs Cilium as the CNI; this cluster reports '$CNI'."
  echo "Layer 7 rules are a Cilium feature, so Calico and kindnet cannot run it."
  echo "Use the Killercoda Killer Shell CKS playground, which ships Cilium."
  exit 1
fi

kubectl create namespace "$NS" 2>/dev/null || true

# Start from an empty policy set so a rerun really resets the scenario.
kubectl delete ciliumnetworkpolicy --all -n "$NS" >/dev/null 2>&1 || true
kubectl delete networkpolicy --all -n "$NS" >/dev/null 2>&1 || true

kubectl apply -n "$NS" -f - >/dev/null <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata: {name: api-conf}
data:
  default.conf: |
    server {
      listen 80;
      location = /health {
        add_header Content-Type text/plain;
        return 200 "ok\n";
      }
      location / {
        return 404;
      }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: api}
spec:
  replicas: 1
  selector: {matchLabels: {app: api}}
  template:
    metadata: {labels: {app: api}}
    spec:
      containers:
      - name: api
        image: nginx:1.27
        ports:
        - containerPort: 80
        volumeMounts:
        - name: conf
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: conf
        configMap: {name: api-conf}
---
apiVersion: v1
kind: Service
metadata: {name: api}
spec:
  selector: {app: api}
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: client}
spec:
  replicas: 1
  selector: {matchLabels: {app: client}}
  template:
    metadata: {labels: {app: client}}
    spec:
      containers:
      - name: client
        image: curlimages/curl:8.11.1
        command: ["sleep", "3600"]
EOF

# A config change on a rerun only reaches the pods after a restart.
kubectl -n "$NS" rollout restart deploy/api >/dev/null 2>&1 || true
kubectl -n "$NS" rollout status deploy/api --timeout=120s >/dev/null 2>&1 \
  || echo "warning: deployment api is not ready yet"
kubectl -n "$NS" rollout status deploy/client --timeout=120s >/dev/null 2>&1 \
  || echo "warning: deployment client is not ready yet"

code() {
  kubectl exec -n "$NS" deploy/client -- \
    curl -s -o /dev/null -m 10 -w '%{http_code}' "$1" 2>/dev/null || echo "n/a"
}

echo "Setup complete."
echo "  Namespace:    $NS"
echo "  Server:       deployment api, pod label app=api, service api on port 80"
echo "  Client:       deployment client, pod label app=client, curl is installed"
echo "  Policies:     none, so every path is reachable right now"
echo "  CNI:          $CNI"
echo "  Right now:    http://api/health   -> $(code http://api/health)"
echo "                http://api/anything -> $(code http://api/anything)   (nginx, not the policy)"
echo "  Deliverable:  a CiliumNetworkPolicy in $NS that leaves /health at 200"
echo "                and turns every other path into 403."
