#!/bin/bash
kubectl delete deployment mariadb -n mariadb --ignore-not-found
kubectl delete pvc mariadb -n mariadb --ignore-not-found
kubectl delete pv mariadb-pv --ignore-not-found
kubectl delete ns mariadb --ignore-not-found
echo "✅ Cleanup complete"
