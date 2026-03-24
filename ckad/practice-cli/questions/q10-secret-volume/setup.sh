#!/bin/bash
set -e
# Q10 — Secret as Volume Mount: Setup

# Clean prior state
kubectl delete pod secret-vol-pod &>/dev/null || true
kubectl delete secret credentials-secret &>/dev/null || true
rm -rf /opt/credentials &>/dev/null || true

# Create source credentials file
mkdir -p /opt/credentials
cat > /opt/credentials/credentials.txt <<'EOF'
username=admin
password=s3cure!
EOF

echo "Setup complete. Credentials file created at /opt/credentials/credentials.txt"
