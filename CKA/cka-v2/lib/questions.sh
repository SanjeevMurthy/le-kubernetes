#!/usr/bin/env bash
# ─── Question Registry (v2 — 22 Questions) ───────────────────────
# Format: ID|Title|Domain|DomainShort|Difficulty|Folder

QUESTIONS=(
  "01|Helm Template Generation and Chart Installation|Cluster Architecture, Installation & Configuration|D1|Medium|q01-helm"
  "02|CNI Installation and Configuration (Calico)|Cluster Architecture, Installation & Configuration|D1|Medium|q02-cni-calico"
  "03|CRD Tasks — List, Query, and Manage CRDs|Cluster Architecture, Installation & Configuration|D1|Easy|q03-crds"
  "04|Install Container Runtime and Prepare Node|Cluster Architecture, Installation & Configuration|D1|Medium|q04-container-runtime"
  "05|kubeadm Cluster Installation with Custom Config|Cluster Architecture, Installation & Configuration|D1|Hard|q05-kubeadm-init"
  "06|Kustomize Deployment Tasks|Cluster Architecture, Installation & Configuration|D1|Medium|q06-kustomize"
  "07|Create a Horizontal Pod Autoscaler (HPA)|Workloads & Scheduling|D2|Medium|q07-hpa"
  "08|Add a Sidecar Log Container|Workloads & Scheduling|D2|Medium|q08-sidecar"
  "09|PriorityClass Creation and Assignment|Workloads & Scheduling|D2|Easy|q09-priorityclass"
  "10|Resource Requests/Limits for Pending Pods|Workloads & Scheduling|D2|Medium|q10-resource-requests"
  "11|NGINX ConfigMap TLS Configuration|Workloads & Scheduling|D2|Medium|q11-configmap-tls"
  "12|Run a Single-Container Pod|Workloads & Scheduling|D2|Easy|q12-run-pod"
  "13|Enforce Pod Security Standards|Workloads & Scheduling|D2|Medium|q13-pod-security"
  "14|Gateway API Migration with TLS|Services & Networking|D3|Hard|q14-gateway-api"
  "15|Create an Ingress Resource|Services & Networking|D3|Medium|q15-ingress"
  "16|Expose Deployment via NodePort|Services & Networking|D3|Easy|q16-nodeport"
  "17|Network Policy Configuration|Services & Networking|D3|Medium|q17-network-policy"
  "18|Create StorageClass and Set as Default|Storage|D4|Medium|q18-storageclass"
  "19|Create PVC and Bind to Existing PV|Storage|D4|Medium|q19-pvc-pv"
  "20|Control Plane Troubleshooting|Troubleshooting|D5|Hard|q20-control-plane-fix"
  "21|CNI / Networking Troubleshooting|Troubleshooting|D5|Hard|q21-cni-troubleshoot"
  "22|General Cluster Troubleshooting|Troubleshooting|D5|Medium|q22-cluster-repair"
)

# ─── Registry Helpers ─────────────────────────────────────────────

get_field() {
  local entry="$1" field="$2"
  echo "$entry" | cut -d'|' -f"$field"
}

get_question_by_num() {
  local num="$1"
  for q in "${QUESTIONS[@]}"; do
    if [[ "$(get_field "$q" 1)" == "$num" ]]; then
      echo "$q"
      return 0
    fi
  done
  return 1
}

get_question_id()         { get_field "$1" 1; }
get_question_title()      { get_field "$1" 2; }
get_question_domain()     { get_field "$1" 3; }
get_question_domain_short() { get_field "$1" 4; }
get_question_difficulty() { get_field "$1" 5; }
get_question_folder()     { get_field "$1" 6; }

get_difficulty_color() {
  case "$1" in
    Easy)   echo "${GREEN}" ;;
    Medium) echo "${YELLOW}" ;;
    Hard)   echo "${RED}" ;;
    *)      echo "${WHITE}" ;;
  esac
}

get_domain_color() {
  case "$1" in
    D1) echo "${BLUE}" ;;
    D2) echo "${MAGENTA}" ;;
    D3) echo "${CYAN}" ;;
    D4) echo "${YELLOW}" ;;
    D5) echo "${RED}" ;;
    *)  echo "${WHITE}" ;;
  esac
}
