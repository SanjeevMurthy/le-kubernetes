#!/bin/bash
# Q16 — Falco custom rule: Setup (node-level)
echo "Falco should be running on the node."
echo "Add a custom rule to /etc/falco/falco_rules.local.yaml that fires at WARNING when bash/sh"
echo "starts in a container, then reload: sudo kill -1 \$(cat /var/run/falco.pid)"
