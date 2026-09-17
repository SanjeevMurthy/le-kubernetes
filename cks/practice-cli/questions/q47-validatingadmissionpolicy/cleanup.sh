#!/bin/bash
# Q47 ValidatingAdmissionPolicy: the binding goes first. Removing the policy
# while its binding still refers to it leaves admission refusing Pods in
# vap-lab with a dangling reference under failurePolicy: Fail.
source "$(dirname "$0")/../../lib/env.sh"
kubectl delete validatingadmissionpolicybinding require-non-root-binding --ignore-not-found >/dev/null 2>&1
kubectl delete validatingadmissionpolicy require-non-root --ignore-not-found >/dev/null 2>&1
kubectl delete namespace vap-lab vap-other --ignore-not-found >/dev/null 2>&1
echo "Cleanup complete"
