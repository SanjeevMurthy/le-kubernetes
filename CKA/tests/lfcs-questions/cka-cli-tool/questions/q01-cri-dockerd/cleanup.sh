#!/bin/bash
# Q1 — cri-dockerd: Cleanup
echo "⚠️  cri-dockerd and sysctl changes are system-level. Manual cleanup:"
echo "  sudo systemctl stop cri-docker.service"
echo "  sudo dpkg -r cri-dockerd"
echo "  sudo rm /etc/sysctl.d/kube.conf"
echo "  sudo sysctl --system"
