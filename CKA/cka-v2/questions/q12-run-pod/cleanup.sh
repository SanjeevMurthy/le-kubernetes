#!/bin/bash
# Q12 — Run a Single-Container Pod: Cleanup
kubectl delete pod nginx-pod --ignore-not-found &>/dev/null
