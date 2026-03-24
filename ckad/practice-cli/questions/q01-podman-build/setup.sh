#!/bin/bash
set -e
# Q1 — Build Container Image: Setup

# Check for container runtime
if command -v podman &>/dev/null; then
  RUNTIME="podman"
elif command -v docker &>/dev/null; then
  RUNTIME="docker"
else
  echo "ERROR: Neither podman nor docker found. Install one before continuing."
  exit 1
fi
echo "Detected container runtime: $RUNTIME"

# Clean prior state
$RUNTIME rmi my-app:1.0 &>/dev/null || true
rm -f /root/my-app.tar &>/dev/null || true
rm -rf /root/app-source &>/dev/null || true

# Create application source directory
mkdir -p /root/app-source

# Create index.html
cat > /root/app-source/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head><title>My App</title></head>
<body><h1>Hello from my-app:1.0</h1></body>
</html>
EOF

# Create Dockerfile
cat > /root/app-source/Dockerfile <<'EOF'
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
EOF

echo "Setup complete. Source files created in /root/app-source/"
