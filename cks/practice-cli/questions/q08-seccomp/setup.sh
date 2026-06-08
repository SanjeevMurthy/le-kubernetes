#!/bin/bash
# Q8 — Seccomp: Setup (node-level for custom profile)
echo "Run pod 'audited' with seccompProfile RuntimeDefault."
echo "Place a custom profile at /var/lib/kubelet/seccomp/profiles/audit.json on the node,"
echo "then run pod 'custom' with seccompProfile type Localhost, localhostProfile profiles/audit.json."
