#!/bin/bash
# Q1 — Install cri-dockerd + Configure Sysctl: Setup
set -e

echo "Downloading CRI-Dockerd Debian package to /root/cri-dockerd.deb..."
wget -q https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.20/cri-dockerd_0.3.20.3-0.debian-bullseye_amd64.deb -O /root/cri-dockerd.deb

echo ""
echo "CRI-Dockerd package downloaded to /root/cri-dockerd.deb"
echo ""
echo "Your tasks:"
echo "  1. Install the .deb package using dpkg"
echo "  2. Enable and start the cri-docker service"
echo "  3. Configure the required sysctl parameters persistently"
