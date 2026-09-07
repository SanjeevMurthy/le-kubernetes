#!/bin/bash
# Q16 Falco: verify.
source "$(dirname "$0")/../../lib/checks.sh"; source "$(dirname "$0")/../../lib/env.sh"
RF=/etc/falco/falco_rules.local.yaml
RULE='Shell spawned in container'
W=$(worker_node)

falco_unit() {
  local u
  for u in falco-modern-bpf falco; do
    if on_worker systemctl is-active --quiet "$u"; then echo "$u"; return 0; fi
  done
  return 1
}

if ! on_worker test -f "$RF"; then
  echo "  FAIL: $RF not found on worker '$W'"; FAIL=$((FAIL + 1)); summary; exit
fi
TMP=$(mktemp); BLOCK=$(mktemp)
on_worker cat "$RF" > "$TMP" 2>/dev/null
awk '
  /^[[:space:]]*-[[:space:]]*rule:[[:space:]]*["'"'"']?Shell spawned in container["'"'"']?[[:space:]]*$/ {f=1; next}
  /^[[:space:]]*-[[:space:]]*(rule|macro|list):/ {f=0}
  f
' "$TMP" > "$BLOCK"

echo "Checking the custom rule in $RF on worker '$W'..."
check_file_has "the local rules file defines rule '$RULE'" '^[[:space:]]*-[[:space:]]*rule:[[:space:]]*"?'"$RULE" "$TMP"
check_file_has "the rule fires at priority WARNING" 'priority:[[:space:]]*WARNING' "$BLOCK"
check_file_has "the output text starts with '$RULE'" 'output:[[:space:]]*"?'"$RULE" "$BLOCK"
if grep -q '%container\.name' "$BLOCK" && grep -q '%proc\.name' "$BLOCK"; then
  echo "  PASS: the output names the container and the process"; PASS=$((PASS + 1))
else
  echo "  FAIL: the output must include container=%container.name and proc=%proc.name"; FAIL=$((FAIL + 1))
fi

COND=$(awk '
  /^[[:space:]]*condition:/ {f=1; print; next}
  f && /^[[:space:]]*[a-z_]+:/ {f=0}
  f
' "$BLOCK")
if echo "$COND" | grep -Eq 'container\.id[[:space:]]*!=[[:space:]]*host|(^|[^.[:alnum:]_])container([[:space:]]|$)'; then
  echo "  PASS: the condition is scoped to containers, not the host"; PASS=$((PASS + 1))
else
  echo "  FAIL: the condition must exclude the host (container.id != host, or the 'container' macro); got: ${COND:-<no condition found>}"; FAIL=$((FAIL + 1))
fi
shell_ok=0
if echo "$COND" | grep -Eq 'shell_binaries'; then
  shell_ok=1
elif echo "$COND" | grep -Eq 'proc\.name' && echo "$COND" | grep -Eq '(^|[^[:alnum:]_%.])(bash|sh|zsh|ash|dash|ksh)([^[:alnum:]_]|$)'; then
  shell_ok=1
fi
if echo "$COND" | grep -Eq 'spawned_process|evt\.type[[:space:]]*(=|in)'; then exec_ok=1; else exec_ok=0; fi
if [[ "$shell_ok" -eq 1 && "$exec_ok" -eq 1 ]]; then
  echo "  PASS: the condition matches a shell binary being executed"; PASS=$((PASS + 1))
else
  echo "  FAIL: the condition must match an exec (spawned_process or evt.type=execve) of a shell (proc.name in (bash, sh) or shell_binaries); got: ${COND:-<no condition found>}"; FAIL=$((FAIL + 1))
fi
rm -f "$TMP" "$BLOCK"

check "Falco is active on the worker (falco-modern-bpf or falco)" falco_unit

echo "Triggering a shell inside a container and reading the Falco journal (effect test)..."
jcount() { on_worker journalctl -u falco-modern-bpf -u falco --no-pager -n 3000 2>/dev/null | grep -c "$RULE"; }
before=$(jcount); before=${before:-0}
kubectl exec -n falco-lab deploy/shell-bot -- sh -c id >/dev/null 2>&1
sleep 12
after=$(jcount); after=${after:-0}
if [[ "$after" -gt "$before" ]]; then
  echo "  PASS: Falco logged a new '$RULE' alert ($before -> $after in the journal)"; PASS=$((PASS + 1))
elif [[ "$after" -gt 0 ]]; then
  echo "  FAIL: '$RULE' alerts exist but none arrived in the last 12 seconds; reload Falco after editing the rules"; FAIL=$((FAIL + 1))
else
  echo "  FAIL: no '$RULE' alert in journalctl -u falco-modern-bpf -u falco; the rule is not loaded (reload Falco) or its output text differs"; FAIL=$((FAIL + 1))
fi
summary
