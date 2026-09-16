#!/bin/bash
# Q45 binary verification: four "release binaries" and the checksum list that
# shipped with them. One file on disk is not the file the list describes.
set -e
source "$(dirname "$0")/../../lib/env.sh"

DIR=$(course_dir 45)
BIN="$DIR/binaries"

rm -rf "$BIN"
rm -f "$DIR/tampered"
mkdir -p "$BIN"

for f in kubectl kubeadm kubelet kube-proxy; do
  head -c 4096 /dev/urandom > "$BIN/$f"
  chmod 755 "$BIN/$f"
done

# Pick the odd one out at random so that repeating the question does not
# reward remembering last time's answer.
BAD=$(printf '%s\n' kubectl kubeadm kubelet kube-proxy | shuf -n 1)

: > "$BIN/checksums.txt"
for f in kubectl kubeadm kubelet kube-proxy; do
  if [[ "$f" == "$BAD" ]]; then
    # The published hash of content this file does not have. That is what a
    # swapped binary looks like: the list is honest, the file is not.
    printf '%s  %s\n' "$(head -c 4096 /dev/urandom | sha512sum | cut -d' ' -f1)" "$f" >> "$BIN/checksums.txt"
  else
    printf '%s  %s\n' "$(sha512sum "$BIN/$f" | cut -d' ' -f1)" "$f" >> "$BIN/checksums.txt"
  fi
done
chmod 644 "$BIN/checksums.txt"

# The verifier cannot re-derive the answer once the file has been deleted, so
# record it outside the working directory where the candidate is not reading.
mkdir -p "$CKS_STATE_DIR/backup/q45"
echo "$BAD" > "$CKS_STATE_DIR/backup/q45/expected"

echo "Setup complete."
echo "  Binaries:    $BIN   (kubectl, kubeadm, kubelet, kube-proxy)"
echo "  Published:   $BIN/checksums.txt"
echo "  Deliverable: $DIR/tampered   (the file name of the one that fails)"
echo "  Exactly one binary disagrees with the list. The list is not the problem."
