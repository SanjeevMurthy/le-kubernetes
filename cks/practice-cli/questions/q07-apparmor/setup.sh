#!/bin/bash
# Q7 — AppArmor on a pod: Setup (node-level)
echo "On the worker node, ensure the profile 'k8s-deny-write' is loaded:"
echo "  sudo apparmor_parser -q /etc/apparmor.d/k8s-deny-write ; sudo aa-status | grep k8s-deny-write"
echo "Then run pod 'secure-pod' confined by that profile (securityContext.appArmorProfile, type Localhost)."
