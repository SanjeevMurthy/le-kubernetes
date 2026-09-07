#!/bin/bash
# Q13 Trivy: a deployment pinned to a knowingly vulnerable image, plus the
# directory the scan report has to land in.
set -e
source "$(dirname "$0")/../../lib/env.sh"

NS=trivy-lab
require_tool trivy

kubectl create namespace "$NS" 2>/dev/null || true
kubectl -n "$NS" create deployment web --image=nginx:1.18.0 2>/dev/null || true
# Reset the image on a rerun so the scenario always starts vulnerable.
kubectl -n "$NS" set image deploy/web nginx=nginx:1.18.0 >/dev/null 2>&1 || true

D=$(course_dir 13)
rm -f "$D/report.txt"

kubectl -n "$NS" rollout status deploy/web --timeout=120s >/dev/null 2>&1 || echo "warning: deployment web is not ready yet"

echo "Setup complete: namespace '$NS' runs deployment 'web' on image nginx:1.18.0, which has known CRITICALs."
echo "The scan report must be saved to $D/report.txt."
echo "The report directory exists and is empty; no scan has been run yet."
