#!/usr/bin/env bash
# ─── Question Registry (CKS — 18 Questions) ───────────────────────
# Format: ID|Title|Domain|DomainShort|Difficulty|Folder
# Domains follow the official CKS curriculum order (v1.34).

QUESTIONS=(
  "01|NetworkPolicy: Default-Deny + Selective Allow|Cluster Setup|D1|Medium|q01-networkpolicy-default-deny"
  "02|CIS Benchmark Remediation with kube-bench|Cluster Setup|D1|Medium|q02-kube-bench-cis"
  "03|Ingress TLS Termination|Cluster Setup|D1|Medium|q03-ingress-tls"
  "04|RBAC Least-Privilege Role + Binding|Cluster Hardening|D2|Medium|q04-rbac-least-privilege"
  "05|ServiceAccount Token Hardening|Cluster Hardening|D2|Easy|q05-serviceaccount-hardening"
  "06|Restrict the API Server (apiserver flags)|Cluster Hardening|D2|Hard|q06-apiserver-hardening"
  "07|AppArmor Profile on a Pod|System Hardening|D3|Medium|q07-apparmor"
  "08|Seccomp RuntimeDefault + Custom Profile|System Hardening|D3|Medium|q08-seccomp"
  "09|Enforce Pod Security Admission (restricted)|Minimize Microservice Vulnerabilities|D4|Medium|q09-pod-security-admission"
  "10|Encrypt Secrets at Rest (EncryptionConfiguration)|Minimize Microservice Vulnerabilities|D4|Hard|q10-encryption-at-rest"
  "11|Admission Policy with Kyverno/Gatekeeper|Minimize Microservice Vulnerabilities|D4|Medium|q11-admission-policy"
  "12|Runtime Sandbox with RuntimeClass (gVisor)|Minimize Microservice Vulnerabilities|D4|Medium|q12-runtimeclass-gvisor"
  "13|Scan Images with Trivy and Remediate|Supply Chain Security|D5|Medium|q13-trivy-scan"
  "14|Restrict Images via ImagePolicyWebhook/Registry|Supply Chain Security|D5|Hard|q14-image-policy"
  "15|Static Analysis & Manifest Hardening (kubesec)|Supply Chain Security|D5|Medium|q15-static-analysis"
  "16|Detect Threats with Falco Rules|Monitoring, Logging and Runtime Security|D6|Medium|q16-falco"
  "17|API Server Audit Logging Policy|Monitoring, Logging and Runtime Security|D6|Hard|q17-audit-logging"
  "18|Immutable Containers (readOnlyRootFilesystem)|Monitoring, Logging and Runtime Security|D6|Easy|q18-immutable-containers"
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

get_question_id()           { get_field "$1" 1; }
get_question_title()        { get_field "$1" 2; }
get_question_domain()       { get_field "$1" 3; }
get_question_domain_short() { get_field "$1" 4; }
get_question_difficulty()   { get_field "$1" 5; }
get_question_folder()       { get_field "$1" 6; }

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
    D6) echo "${GREEN}" ;;
    *)  echo "${WHITE}" ;;
  esac
}
