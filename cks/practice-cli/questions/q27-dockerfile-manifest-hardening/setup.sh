#!/bin/bash
# Q27 Dockerfile and manifest hardening: write the two files with exactly two
# planted problems each, and record their line counts so the verifier can tell
# a surgical edit from a rewrite.
set -e
source "$(dirname "$0")/../../lib/env.sh"

[[ "$(uname -s)" == "Linux" ]] || { echo "This question needs a Linux shell (needs=linux)."; exit 1; }

DIR=$(course_dir 27)
DF="$DIR/Dockerfile"
MF="$DIR/deploy.yaml"

# Rewritten on every run: these files are the starting state, not the answer.
cat > "$DF" <<'EOF'
FROM ubuntu:16.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --uid 10001 --create-home appuser

COPY app /usr/local/bin/app
RUN chmod 0755 /usr/local/bin/app

USER root

ENTRYPOINT ["/usr/local/bin/app"]
EOF

cat > "$MF" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: supply-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: nginx:1.27
          ports:
            - containerPort: 80
          securityContext:
            privileged: true
            runAsUser: 0
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
EOF

D_LINES=$(wc -l < "$DF" | tr -d ' ')
M_LINES=$(wc -l < "$MF" | tr -d ' ')
printf 'dockerfile=%s\nmanifest=%s\n' "$D_LINES" "$M_LINES" > "$CKS_STATE_DIR/q27.lines"

echo "Setup complete."
echo "  Dockerfile:  $DF ($D_LINES lines, two security problems)"
echo "  Manifest:    $MF ($M_LINES lines, two security problems)"
echo "  Nothing is applied to a cluster; both files are graded as text."
echo "  Line counts are recorded. A rewrite that drifts more than 2 lines from"
echo "  the original fails, so change only what the task asks for."
