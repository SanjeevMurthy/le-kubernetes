#!/bin/bash
# Q12 — RuntimeClass (gVisor): Setup
echo "The node should have the 'runsc' (gVisor) runtime in containerd."
echo "Create RuntimeClass 'gvisor' (handler: runsc) and pod 'sandboxed' using spec.runtimeClassName: gvisor."
