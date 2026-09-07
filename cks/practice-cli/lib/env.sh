#!/usr/bin/env bash
# Environment detection, safety guards and node helpers shared by the CKS CLI
# and by question scripts. Source it; do not execute it.

CKS_STATE_DIR="${CKS_STATE_DIR:-$HOME/.cks-practice}"
mkdir -p "$CKS_STATE_DIR/backup" 2>/dev/null
KAS_MANIFEST=/etc/kubernetes/manifests/kube-apiserver.yaml

# Deliverables mirror the exam's /opt/course/<n>/ convention, falling back to the
# home directory on hosts where /opt is not writable (minikube on a Mac, for one).
if [[ -z "${COURSE_DIR:-}" ]]; then
  if [[ -w /opt/course ]] || { [[ -w /opt ]] && mkdir -p /opt/course 2>/dev/null; }; then
    COURSE_DIR=/opt/course
  else
    COURSE_DIR="$HOME/cks-course"
  fi
fi
export CKS_STATE_DIR COURSE_DIR KAS_MANIFEST

course_dir() { mkdir -p "$COURSE_DIR/$1" && echo "$COURSE_DIR/$1"; }

# ─── safety ────────────────────────────────────────────────────────
# These questions edit RBAC, admission control, node files and static pod
# manifests. Running them against a real cluster would be destructive, so the
# context has to be on an allow-list before anything happens.
require_context_allowed() {
  local ctx
  ctx=$(kubectl config current-context 2>/dev/null) || { echo "No kubectl context is set."; return 1; }
  [[ "${CKS_ALLOW_CONTEXT:-0}" == "1" ]] && return 0
  case "$ctx" in
    *aks*|*eks*|*gke*|*prod*)
      echo "Refusing context '$ctx': it looks like a real cluster."
      echo "Set CKS_ALLOW_CONTEXT=1 only if you are certain this is disposable."
      return 1 ;;
    minikube|cks*|kubernetes-admin@kubernetes|kind-*|default|killercoda*)
      return 0 ;;
  esac
  echo "Context '$ctx' is not on the allow-list (minikube, cks*, kubernetes-admin@kubernetes, kind-*, default, killercoda*)."
  echo "Set CKS_ALLOW_CONTEXT=1 to override."
  return 1
}

# ─── environment detection ─────────────────────────────────────────
detect_cni() {
  local ds
  ds=$(kubectl get ds -n kube-system -o name 2>/dev/null)
  case "$ds" in
    *cilium*) echo cilium ;;
    *calico-node*) echo calico ;;
    *) echo none ;;
  esac
}

is_node_root() { [[ $EUID -eq 0 && -d /etc/kubernetes/manifests ]]; }

require_node_root() {
  is_node_root && return 0
  echo "This question needs a root shell on a kubeadm node (sudo -i)."
  echo "Use the Killercoda Killer Shell CKS playground or a KodeKloud lab; minikube cannot provide it."
  return 1
}

require_tool() {
  command -v "$1" >/dev/null 2>&1 && return 0
  echo "Missing tool: $1. Install it with: sudo bash tools/install-tools.sh $1"
  return 1
}

# has_needs "kubectl cni-netpol tool:trivy"   returns 0 when every tag is satisfied
has_needs() {
  local n
  for n in $1; do
    case "$n" in
      kubectl)              kubectl version --request-timeout=5s >/dev/null 2>&1 || return 1 ;;
      linux)                [[ "$(uname -s)" == Linux ]] || return 1 ;;
      cni-netpol)           [[ "$(detect_cni)" != none ]] || return 1 ;;
      cni-cilium)           [[ "$(detect_cni)" == cilium ]] || return 1 ;;
      ingress)              kubectl get pods -A -o name 2>/dev/null | grep -q ingress-nginx || return 1 ;;
      admission:kyverno)    kubectl get crd clusterpolicies.kyverno.io >/dev/null 2>&1 || return 1 ;;
      admission:gatekeeper) kubectl get crd constrainttemplates.templates.gatekeeper.sh >/dev/null 2>&1 || return 1 ;;
      istio)                kubectl get crd peerauthentications.security.istio.io >/dev/null 2>&1 || return 1 ;;
      node-root)            is_node_root || return 1 ;;
      tool:*)               command -v "${n#tool:}" >/dev/null 2>&1 || return 1 ;;
      "")                   ;;
      *)                    echo "unknown need tag: $n" >&2; return 1 ;;
    esac
  done
  return 0
}

# ─── file backups ──────────────────────────────────────────────────
# Setups back up anything they modify; cleanups restore it. Backups live outside
# the repo so a cleanup still works after a git checkout.
backup_file() {
  local f="$1" q="$2" b
  mkdir -p "$CKS_STATE_DIR/backup/$q"
  b="$CKS_STATE_DIR/backup/$q/$(echo "$f" | tr / _)"
  [[ -f "$f" && ! -f "$b" ]] && cp -p "$f" "$b"
  return 0
}

restore_file() {
  local f="$1" q="$2" b
  b="$CKS_STATE_DIR/backup/$q/$(echo "$f" | tr / _)"
  if [[ -f "$b" ]]; then cp -p "$b" "$f" && rm -f "$b"; fi
  return 0
}

# ─── control plane helpers ─────────────────────────────────────────
# The kubelet rescans the manifest directory roughly every 20 seconds, so give
# the API server up to two minutes to come back before declaring failure.
wait_apiserver() {
  local i
  for i in $(seq 1 60); do
    if curl -sk --max-time 3 https://127.0.0.1:6443/readyz 2>/dev/null | grep -q ok; then
      return 0
    fi
    sleep 2
  done
  echo "apiserver did not become ready within 120 seconds" >&2
  return 1
}

worker_node() {
  kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.metadata.labels.node-role\.kubernetes\.io/control-plane}{"\n"}{end}' 2>/dev/null \
    | awk '$2=="" {print $1; exit}'
}

# on_worker cmd args...   runs locally when this host is the worker, else over ssh
on_worker() {
  local w
  w=$(worker_node)
  [[ -n "$w" ]] || { echo "no worker node found" >&2; return 1; }
  if [[ "$(hostname)" == "$w" ]]; then
    "$@"
  else
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$w" "$@"
  fi
}
