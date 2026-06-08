#!/bin/bash
# Q16 — Verify (node)
PASS=0; FAIL=0
RF=/etc/falco/falco_rules.local.yaml
if [ ! -f "$RF" ]; then echo "  FAIL: $RF not found — run on the node with Falco installed"; echo "Results: 0 passed, 1 failed"; exit 1; fi
echo "Checking a custom rule detects a shell (bash/sh) in a container..."
if grep -Eq 'proc\.name' "$RF" && grep -Eq 'bash|sh' "$RF"; then echo "  PASS: shell-detection condition present"; ((PASS++)); else echo "  FAIL: no proc.name bash/sh condition in local rules"; ((FAIL++)); fi
echo "Checking rule priority WARNING..."
if grep -Eqi 'priority:[[:space:]]*WARNING' "$RF"; then echo "  PASS"; ((PASS++)); else echo "  FAIL: rule priority WARNING not set"; ((FAIL++)); fi
echo ""; echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
