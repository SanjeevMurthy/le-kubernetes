#!/bin/bash
# Q38 SBOM: nothing to break here, only a clean directory to write into and the
# image name fixed so the verifier and the candidate agree on it.
set -e
source "$(dirname "$0")/../../lib/env.sh"
require_tool bom

IMAGE=registry.k8s.io/kube-proxy:v1.35.0

if ! command -v python3 >/dev/null 2>&1; then
  echo "warning: python3 is not installed. The verifier uses it to parse the SBOM."
fi

DIR=$(course_dir 38)
rm -f "$DIR/sbom.json" "$DIR/count.txt"

echo "Setup complete."
echo "  Image:        $IMAGE"
echo "  bom version:  $(bom version 2>/dev/null | head -1 || echo unknown)"
echo "  Deliverables: $DIR/sbom.json   (valid JSON, produced by bom)"
echo "                $DIR/count.txt   (the number of packages, nothing else)"
echo "  The directory is empty; nothing has been generated yet."
echo "  Generating the SBOM pulls the image, so this host needs registry.k8s.io."
