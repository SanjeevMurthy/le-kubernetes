#!/bin/bash
# Q4 — Install Container Runtime and Prepare Node: Cleanup
# System configs (kernel modules, sysctl, containerd) should persist.
# Only remove the working directory.
rm -rf /root/node-prep
echo "Cleanup complete (system configs preserved)"
