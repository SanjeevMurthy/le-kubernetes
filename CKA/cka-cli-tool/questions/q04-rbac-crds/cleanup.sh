#!/bin/bash
# Q4 — RBAC for Custom Resources: Cleanup
kubectl delete rolebinding school-admin-binding --ignore-not-found
kubectl delete role school-admin --ignore-not-found
kubectl delete crd students.school.example.com --ignore-not-found
kubectl delete crd classes.school.example.com --ignore-not-found
echo "✅ Cleanup complete"
