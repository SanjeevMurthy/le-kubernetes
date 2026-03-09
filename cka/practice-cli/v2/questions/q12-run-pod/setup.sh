#!/bin/bash
set -e
# Q12 — Run a Single-Container Pod: Setup
# Minimal setup - this question tests basic kubectl run.
# Clean up any prior state silently.
kubectl delete pod nginx-pod --ignore-not-found &>/dev/null
