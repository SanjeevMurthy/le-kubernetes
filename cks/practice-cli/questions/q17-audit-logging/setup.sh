#!/bin/bash
# Q17 — API server audit logging: Setup (control-plane node)
echo "On the control-plane node: write an audit Policy at /etc/kubernetes/audit/policy.yaml"
echo "(secrets at RequestResponse; drop get/list/watch; everything else Metadata),"
echo "and wire --audit-policy-file + --audit-log-path into the apiserver (with volume mounts)."
