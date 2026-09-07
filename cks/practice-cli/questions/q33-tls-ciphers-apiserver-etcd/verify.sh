#!/bin/bash
# Q33 TLS hardening: verify. The flag in the file only proves intent; the graded
# facts are the flags on the running pods and what the port actually negotiates.
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

ETCD_MANIFEST=/etc/kubernetes/manifests/etcd.yaml
SUITE=TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384

echo "Checking the manifests..."
check_file_has "kube-apiserver sets --tls-min-version=VersionTLS13" '--tls-min-version=VersionTLS13' "$KAS_MANIFEST"
check_file_has "etcd sets --cipher-suites including $SUITE" "--cipher-suites=.*$SUITE" "$ETCD_MANIFEST"

echo "Checking the flags reached the running static pods..."
KAS_CMD=$(kubectl get pods -n kube-system -l component=kube-apiserver -o jsonpath='{.items[0].spec.containers[0].command}' 2>/dev/null)
ETCD_CMD=$(kubectl get pods -n kube-system -l component=etcd -o jsonpath='{.items[0].spec.containers[0].command}' 2>/dev/null)
check_contains "the running API server carries --tls-min-version=VersionTLS13" "--tls-min-version=VersionTLS13" "$KAS_CMD"
check_contains "the running etcd carries $SUITE" "$SUITE" "$ETCD_CMD"

echo "Checking the control plane survived the change..."
check "the API server answers /readyz" bash -c 'curl -sk --max-time 5 https://127.0.0.1:6443/readyz | grep -q ok'
check "kubectl get nodes still answers" kubectl get nodes
check_eq "the etcd static pod is Running" "Running" \
  "$(kubectl get pods -n kube-system -l component=etcd -o jsonpath='{.items[0].status.phase}' 2>/dev/null)"

echo "Testing the API server port with openssl (effect test)..."
if ! command -v openssl >/dev/null 2>&1; then
  echo "  FAIL: openssl is not installed on this node, so the effect cannot be tested"; FAIL=$((FAIL + 1))
else
  T13=$(echo | timeout 10 openssl s_client -connect 127.0.0.1:6443 -tls1_3 2>&1)
  T12=$(echo | timeout 10 openssl s_client -connect 127.0.0.1:6443 -tls1_2 2>&1)

  # Control first: TLS 1.3 has to work, otherwise a refused 1.2 handshake would
  # only prove that nothing is listening on 6443.
  if echo "$T13" | grep -q 'TLSv1.3'; then
    echo "  PASS: the port negotiates TLSv1.3"; PASS=$((PASS + 1))
  else
    echo "  FAIL: openssl could not negotiate TLSv1.3 on 127.0.0.1:6443"; FAIL=$((FAIL + 1))
  fi

  if echo "$T12" | grep -qE 'Cipher *is *TLS_'; then
    echo "  FAIL: a TLS 1.2 handshake still succeeds, so --tls-min-version is not in effect"; FAIL=$((FAIL + 1))
  elif echo "$T12" | grep -qiE 'alert protocol version|no protocols available|wrong version number|handshake failure|unsupported protocol|alert number 70'; then
    echo "  PASS: a TLS 1.2 handshake is refused by the API server"; PASS=$((PASS + 1))
  else
    echo "  FAIL: the TLS 1.2 probe gave no clear answer: $(echo "$T12" | grep -m1 .)"; FAIL=$((FAIL + 1))
  fi
fi

summary
