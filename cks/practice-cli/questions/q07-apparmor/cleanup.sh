#!/bin/bash
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete namespace apparmor-lab --ignore-not-found >/dev/null 2>&1
on_worker bash -c 'apparmor_parser -R /etc/apparmor.d/k8s-deny-write 2>/dev/null; rm -f /etc/apparmor.d/k8s-deny-write' 2>/dev/null
echo "Cleanup complete"
