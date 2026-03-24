#!/bin/bash
# Q1 — Build Container Image: Cleanup
if command -v podman &>/dev/null; then
  podman rmi my-app:1.0 &>/dev/null || true
elif command -v docker &>/dev/null; then
  docker rmi my-app:1.0 &>/dev/null || true
fi
rm -f /root/my-app.tar || true
rm -rf /root/app-source || true
echo "Cleanup complete"
