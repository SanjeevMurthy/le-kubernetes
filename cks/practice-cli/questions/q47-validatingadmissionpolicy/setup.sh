#!/bin/bash
# Q47 ValidatingAdmissionPolicy: two namespaces, so the binding's scope can be
# tested in both directions, and no policy of any kind to start from.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_tool kubectl

kubectl create namespace vap-lab >/dev/null 2>&1 || true
kubectl create namespace vap-other >/dev/null 2>&1 || true

# A previous solve leaves the policy behind, and the verifier would then pass
# before anything had been done this time.
kubectl delete validatingadmissionpolicybinding require-non-root-binding --ignore-not-found >/dev/null 2>&1 || true
kubectl delete validatingadmissionpolicy require-non-root --ignore-not-found >/dev/null 2>&1 || true

# Something already running that would not be admitted today. Existing Pods are
# never re-evaluated, which is the point of the last gotcha in the solution.
kubectl -n vap-lab delete pod legacy-root --ignore-not-found >/dev/null 2>&1 || true
kubectl -n vap-lab run legacy-root --image=nginx:1.27 --restart=Never >/dev/null 2>&1 || true

echo "Setup complete."
echo "  Namespaces:  vap-lab (must enforce) and vap-other (must not)"
echo "  Already running: pod/legacy-root in vap-lab, with no securityContext"
echo "  No ValidatingAdmissionPolicy exists yet:"
echo "    kubectl get validatingadmissionpolicy"
echo "  Right now this is accepted, and it must not be once you are done:"
echo "    kubectl -n vap-lab run probe --image=nginx:1.27 --dry-run=server"
