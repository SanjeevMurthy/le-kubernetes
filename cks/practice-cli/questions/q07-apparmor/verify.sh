#!/bin/bash
source "$(dirname "$0")/../../lib/checks.sh"; source "$(dirname "$0")/../../lib/env.sh"
W=$(worker_node)
echo "Checking the profile is loaded in enforce mode on $W..."
check_contains "profile k8s-deny-write enforced on the worker" "k8s-deny-write" "$(on_worker aa-status 2>/dev/null | grep -A200 'enforce mode' | grep k8s-deny-write)"
echo "Checking pod secure-pod uses the profile..."
prof=$(kjp pod secure-pod apparmor-lab '{.spec.containers[0].securityContext.appArmorProfile.localhostProfile}')
[[ -z "$prof" ]] && prof=$(kjp pod secure-pod apparmor-lab '{.spec.securityContext.appArmorProfile.localhostProfile}')
[[ -z "$prof" ]] && prof=$(kjp pod secure-pod apparmor-lab '{.metadata.annotations.container\.apparmor\.security\.beta\.kubernetes\.io/secure-pod}' | sed 's/^localhost\///')
check_eq "pod references profile k8s-deny-write" "k8s-deny-write" "$prof"
check_pod_running "pod secure-pod is Running" secure-pod apparmor-lab
echo "Checking writes are denied inside the container (effect test)..."
if kubectl exec -n apparmor-lab secure-pod -- sh -c 'touch /tmp/apparmor-probe' >/dev/null 2>&1; then echo "  FAIL: write succeeded; profile not enforced"; FAIL=$((FAIL + 1)); else echo "  PASS: write denied by AppArmor"; PASS=$((PASS + 1)); fi
summary
