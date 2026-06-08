#!/bin/bash
kubectl delete pod sandboxed --ignore-not-found &>/dev/null
kubectl delete runtimeclass gvisor --ignore-not-found &>/dev/null
echo "Cleanup complete"
