#!/usr/bin/env bash
# Shared verify helpers for CKS question scripts.
# Source from a verify.sh:  source "$(dirname "$0")/../../lib/checks.sh"
#
# Every check prints one "  PASS: <label>" or "  FAIL: <label> (...)" line and
# updates the counters. End with `summary`, which returns non-zero on any failure.
PASS=0; FAIL=0

# check "label" cmd args...        PASS when the command exits 0
check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  PASS: $label"; PASS=$((PASS + 1))
  else
    echo "  FAIL: $label"; FAIL=$((FAIL + 1))
  fi
}

# check_not "label" cmd args...    PASS when the command exits non-zero
check_not() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  FAIL: $label (the command unexpectedly succeeded)"; FAIL=$((FAIL + 1))
  else
    echo "  PASS: $label"; PASS=$((PASS + 1))
  fi
}

# check_eq "label" expected actual
check_eq() {
  if [[ "$2" == "$3" ]]; then
    echo "  PASS: $1"; PASS=$((PASS + 1))
  else
    echo "  FAIL: $1 (expected '$2', got '$3')"; FAIL=$((FAIL + 1))
  fi
}

# check_contains "label" needle haystack
# Matches a whitespace-delimited word or a plain substring, which covers both
# jsonpath list output and free text.
check_contains() {
  if [[ " $3 " == *" $2 "* || "$3" == *"$2"* ]]; then
    echo "  PASS: $1"; PASS=$((PASS + 1))
  else
    echo "  FAIL: $1 (expected to contain '$2', got '$3')"; FAIL=$((FAIL + 1))
  fi
}

# check_file_has "label" 'extended-regex' file
check_file_has() {
  if [[ -f "$3" ]] && grep -Eq -- "$2" "$3"; then
    echo "  PASS: $1"; PASS=$((PASS + 1))
  else
    if [[ ! -f "$3" ]]; then
      echo "  FAIL: $1 (no such file: $3)"
    else
      echo "  FAIL: $1 (pattern '$2' not found in $3)"
    fi
    FAIL=$((FAIL + 1))
  fi
}

# kjp kind name namespace jsonpath      namespace "" for cluster-scoped resources
kjp() {
  if [[ -n "$3" ]]; then
    kubectl get "$1" "$2" -n "$3" -o jsonpath="$4" 2>/dev/null
  else
    kubectl get "$1" "$2" -o jsonpath="$4" 2>/dev/null
  fi
}

# check_pod_running "label" pod namespace
check_pod_running() {
  check_eq "$1" Running "$(kjp pod "$2" "$3" '{.status.phase}')"
}

summary() {
  echo ""
  echo "Results: $PASS passed, $FAIL failed"
  [[ $FAIL -eq 0 ]]
}
