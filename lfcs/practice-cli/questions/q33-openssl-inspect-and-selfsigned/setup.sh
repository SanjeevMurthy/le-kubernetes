#!/bin/bash
# Q33 openssl: hand over a certificate to be read, and make sure no lab
# certificate exists yet so part two is really done by the candidate.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

DIR=$(course_dir 33)

command -v openssl >/dev/null 2>&1 || pkg_install openssl
if ! has_needs "tool:openssl"; then
  echo "openssl is still missing. Install the openssl package and run setup again."
  exit 1
fi

rm -rf /etc/ssl/lab
rm -f "$DIR/answer.txt" "$DIR/server.crt" "$DIR/server.key"

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout "$DIR/server.key" -out "$DIR/server.crt" \
  -subj "/C=IN/ST=KA/L=Bengaluru/O=Shop Ltd/CN=shop.example" >/dev/null 2>&1

if [[ ! -s "$DIR/server.crt" ]]; then
  echo "Could not generate the sample certificate with openssl. Setup failed."
  exit 1
fi
chmod 600 "$DIR/server.key"
chmod 644 "$DIR/server.crt"

echo "Setup complete."
echo "  Certificate to read: $DIR/server.crt"
echo "  Report to write:     $DIR/answer.txt (common name and notAfter date)"
echo "  /etc/ssl/lab does not exist yet"
echo "  New pair to issue:   /etc/ssl/lab/lab.crt and /etc/ssl/lab/lab.key, CN lab.local, 365 days, key mode 600"
