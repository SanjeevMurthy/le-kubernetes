#!/bin/bash
# Q16 — Create StorageClass + Set Default: Setup
# No specific setup needed — this question uses the playground cluster as-is.

echo "No additional setup needed for this question."
echo ""
echo "Current StorageClasses in the cluster:"
kubectl get sc 2>/dev/null || echo "  (unable to list — cluster may not be ready)"
echo ""
echo "Your tasks:"
echo "  1. Create StorageClass 'local-storage' with provisioner rancher.io/local-path"
echo "     and VolumeBindingMode WaitForFirstConsumer"
echo "  2. Patch it to be the default StorageClass"
echo "  3. Ensure it is the ONLY default StorageClass"
