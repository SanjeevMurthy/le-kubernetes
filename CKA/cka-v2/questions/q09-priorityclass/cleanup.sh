#!/bin/bash
# Q9 — PriorityClass Creation and Assignment: Cleanup
kubectl delete deployment critical-app -n production --ignore-not-found &>/dev/null
kubectl delete namespace production --ignore-not-found &>/dev/null
kubectl delete priorityclass high-priority --ignore-not-found &>/dev/null
