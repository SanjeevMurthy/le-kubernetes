#!/usr/bin/env bash
# ─── Setup Script Mapping ─────────────────────────────────────────
# Maps CLI question folder → cka-prep-2025-v2 LabSetUp.bash path
# This avoids duplicating setup scripts.

CLI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
V2_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../cka-prep-2025-v2" && pwd)"

declare -A SETUP_MAP=(
  ["q01-cri-dockerd"]="Question-9 Cri-Dockerd"
  ["q02-cni-calico"]="Question-8 CNI & Network Policy"
  ["q03-crds"]="Question-6 CRDs"
  ["q04-priorityclass"]="Question-7 PriorityClass"
  ["q05-argocd-helm"]="Question-2 ArgoCD"
  ["q06-hpa"]="Question-5 HPA"
  ["q07-resources"]="Question-4 Resource-Allocation"
  ["q08-sidecar"]="Question-3 Sidecar"
  ["q09-taints"]="Question-10 Taints-Tolerations"
  ["q10-nodeport"]="Question-16 NodePort"
  ["q11-ingress"]="Question-12 Ingress"
  ["q12-gateway-api"]="Question-11 Gateway-API"
  ["q13-network-policy"]="Question-13 Network-Policy"
  ["q14-tls-config"]="Question-17 TLS-Config"
  ["q15-storageclass"]="Question-14 Storage-Class"
  ["q16-mariadb-pv"]="Question-1 MariaDB-Persistent volume"
  ["q17-etcd-fix"]="Question-15 Etcd-Fix"
)

get_setup_path() {
  local folder="$1"
  local v2_folder="${SETUP_MAP[$folder]}"
  if [[ -n "$v2_folder" ]]; then
    echo "$V2_DIR/$v2_folder/LabSetUp.bash"
  else
    echo ""
  fi
}
