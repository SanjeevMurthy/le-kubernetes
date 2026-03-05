#!/bin/bash
# Q21 — CNI / Networking Troubleshooting: Cleanup

kubectl delete ns cni-debug --ignore-not-found &>/dev/null
sudo rm -rf /root/cni-troubleshoot
echo "Cleaned up cni-debug namespace and /root/cni-troubleshoot."
