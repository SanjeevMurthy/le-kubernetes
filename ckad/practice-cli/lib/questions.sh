#!/usr/bin/env bash
# ─── Question Registry (24 CKAD Questions) ──────────────────────
# Format: ID|Title|Domain|DomainShort|Difficulty|Folder

QUESTIONS=(
  "01|Build a Container Image with Podman and Save as Tarball|Application Design and Build|D1|Medium|q01-podman-build"
  "02|Create a CronJob with Schedule, History Limits, and Deadline|Application Design and Build|D1|Medium|q02-cronjob"
  "03|Create a One-Off Job from an Existing CronJob|Application Design and Build|D1|Easy|q03-job-from-cronjob"
  "04|Create a PVC and Mount in a Pod|Application Design and Build|D1|Medium|q04-pvc-mount"
  "05|Canary Deployment with Manual Replica-Based Traffic Split|Application Deployment|D2|Medium|q05-canary-deploy"
  "06|Perform a Rolling Update and Rollback|Application Deployment|D2|Easy|q06-rolling-update"
  "07|Fix a Broken Deployment YAML with Deprecated API Version|Application Deployment|D2|Medium|q07-fix-deprecated-api"
  "08|Extract Hardcoded Credentials into a Secret and Inject via secretKeyRef|Application Environment, Configuration and Security|D3|Medium|q08-secret-keyref"
  "09|Create a Secret and Mount as an Environment Variable in a Named Container|Application Environment, Configuration and Security|D3|Easy|q09-secret-env"
  "10|Create a Secret from a File and Mount as a Volume|Application Environment, Configuration and Security|D3|Medium|q10-secret-volume"
  "11|Create a ConfigMap from a File and Mount at a Specific Path|Application Environment, Configuration and Security|D3|Medium|q11-configmap-mount"
  "12|Create SA, Role, and RoleBinding from Pod Log Error|Application Environment, Configuration and Security|D3|Hard|q12-rbac-from-logs"
  "13|Fix a Broken Pod by Finding the Correct Existing ServiceAccount|Application Environment, Configuration and Security|D3|Hard|q13-fix-serviceaccount"
  "14|Configure Pod and Container Security Context with Capabilities|Application Environment, Configuration and Security|D3|Medium|q14-security-context"
  "15|Create a Pod with Resource Requests/Limits Under a Namespace Quota|Application Environment, Configuration and Security|D3|Medium|q15-resource-quota"
  "16|Create a NodePort Service|Services and Networking|D4|Easy|q16-nodeport"
  "17|Fix a Service Selector Mismatch|Services and Networking|D4|Easy|q17-fix-service-selector"
  "18|Create an Ingress Resource with Host-Based Routing|Services and Networking|D4|Medium|q18-ingress-host"
  "19|Fix a Broken Ingress Returning 404|Services and Networking|D4|Medium|q19-fix-ingress"
  "20|Fix NetworkPolicy by Correcting Pod Labels|Services and Networking|D4|Medium|q20-fix-netpol-labels"
  "21|Create a NetworkPolicy Allowing Specific Pod-to-Pod Traffic|Services and Networking|D4|Hard|q21-netpol-pod-to-pod"
  "22|Create a NetworkPolicy with CIDR Exception|Services and Networking|D4|Medium|q22-netpol-cidr"
  "23|Add a Readiness Probe to an Existing Deployment|Application Observability and Maintenance|D5|Easy|q23-readiness-probe"
  "24|Debug CrashLoopBackOff and Export Events to File|Application Observability and Maintenance|D5|Medium|q24-crashloop-debug"
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
