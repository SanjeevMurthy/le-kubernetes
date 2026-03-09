#!/bin/bash
set -e
# Q11 — ConfigMap Volume Mount: Setup

# Clean prior state
kubectl delete pod web-pod &>/dev/null || true
kubectl delete configmap web-config &>/dev/null || true
rm -f /opt/index.html &>/dev/null || true

# Create source HTML file
cat > /opt/index.html <<'EOF'
<h1>Hello from ConfigMap</h1>
EOF

echo "Setup complete. HTML file created at /opt/index.html"
