#!/bin/bash
# Q2 — CNI Installation and Configuration - Calico: Cleanup
# CNI removal is complex and can break the cluster.
# Manual steps if needed:
#   kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
#   Or for the operator model:
#   kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
echo "CNI cleanup is not automated — removing CNI can destabilize the cluster."
echo "If you need to reset, consider reprovisioning the cluster without CNI."
echo "Cleanup skipped"
