#!/bin/bash
# Q48 Gatekeeper: the template and the constraint both exist already, matching
# the exam's shape. Gatekeeper is never installed here; the question is what a
# constraint says, not how to deploy a policy engine.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_tool kubectl

if ! kubectl get crd constrainttemplates.templates.gatekeeper.sh >/dev/null 2>&1; then
  echo "Gatekeeper is not installed on this cluster, so this question cannot run here."
  echo "Install it once on a lab cluster with the upstream manifest, then re-run setup:"
  echo "  kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.17/deploy/gatekeeper.yaml"
  exit 1
fi

kubectl create namespace supply-lab >/dev/null 2>&1 || true
kubectl create namespace supply-other >/dev/null 2>&1 || true

kubectl apply -f - >/dev/null <<'EOF'
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sallowedrepos
spec:
  crd:
    spec:
      names:
        kind: K8sAllowedRepos
      validation:
        openAPIV3Schema:
          type: object
          properties:
            repos:
              type: array
              items:
                type: string
  targets:
  - target: admission.k8s.gatekeeper.sh
    rego: |
      package k8sallowedrepos

      violation[{"msg": msg}] {
        container := input.review.object.spec.containers[_]
        satisfied := [good | repo = input.parameters.repos[_] ; good = startswith(container.image, repo)]
        not any(satisfied)
        msg := sprintf("container <%v> has an invalid image repo <%v>, allowed repos are %v", [container.name, container.image, input.parameters.repos])
      }
EOF

# The CRD the template generates takes a moment to register. Applying the
# constraint before it exists fails with "no matches for kind", which looks like
# a broken question rather than a race.
for _ in $(seq 1 30); do
  kubectl get crd k8sallowedrepos.constraints.gatekeeper.sh >/dev/null 2>&1 && break
  sleep 2
done

# The starting state: permissive in exactly the way the task asks you to fix.
kubectl apply -f - >/dev/null <<'EOF'
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: allowed-registries
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
    namespaces: ["supply-lab"]
  parameters:
    repos:
    - "docker.io/"
    - "registry.k8s.io/"
EOF

echo "Setup complete."
echo "  Gatekeeper:  already installed, do not touch it"
echo "  Template:    constrainttemplate/k8sallowedrepos  (do not edit)"
echo "  Constraint:  k8sallowedrepos/allowed-registries  (this is the one to fix)"
echo "  Namespaces:  supply-lab (enforced) and supply-other (must stay open)"
echo "  Right now Docker Hub is allowed, and it must not be:"
echo "    kubectl -n supply-lab run probe --image=nginx:1.27 --dry-run=server"
