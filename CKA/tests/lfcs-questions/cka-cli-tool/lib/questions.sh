#!/usr/bin/env bash
# ─── Question Registry ────────────────────────────────────────────
# Format: ID|Title|Domain|DomainShort|Difficulty|Folder

QUESTIONS=(
  "01|Install cri-dockerd + Configure Sysctl|Cluster Architecture, Installation & Configuration|D1|Medium|q01-cri-dockerd"
  "02|Install CNI Plugin (Calico)|Cluster Architecture, Installation & Configuration|D1|Medium|q02-cni-calico"
  "03|List cert-manager CRDs + Extract Docs|Cluster Architecture, Installation & Configuration|D1|Easy|q03-crds"
  "04|RBAC for Custom Resources (CRDs)|Cluster Architecture, Installation & Configuration|D1|Medium|q04-rbac-crds"
  "05|Create PriorityClass + Patch Deployment|Cluster Architecture, Installation & Configuration|D1|Easy|q04-priorityclass"
  "06|Helm Template ArgoCD|Cluster Architecture, Installation & Configuration|D1|Medium|q05-argocd-helm"
  "07|Create HPA with Downscale Stabilization|Workloads & Scheduling|D2|Medium|q06-hpa"
  "08|Fix Pending Pods — Resource Requests|Workloads & Scheduling|D2|Medium|q07-resources"
  "09|Add Sidecar Container to Deployment|Workloads & Scheduling|D2|Easy|q08-sidecar"
  "10|Taints and Tolerations|Workloads & Scheduling|D2|Easy|q09-taints"
  "11|Expose Deployment with NodePort|Services & Networking|D3|Easy|q10-nodeport"
  "12|Create an Ingress Resource|Services & Networking|D3|Medium|q11-ingress"
  "13|Migrate Ingress to Gateway API + TLS|Services & Networking|D3|Hard|q12-gateway-api"
  "14|Select Correct NetworkPolicy|Services & Networking|D3|Medium|q13-network-policy"
  "15|Update ConfigMap TLS + Make Immutable|Services & Networking|D3|Medium|q14-tls-config"
  "16|Create StorageClass + Set Default|Storage|D4|Medium|q15-storageclass"
  "17|PVC Bind to PV + Restore MariaDB|Storage|D4|Medium|q16-mariadb-pv"
  "18|Fix kube-apiserver (etcd Port Fix)|Troubleshooting|D5|Hard|q17-etcd-fix"
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
