#!/bin/bash
# Q16 sshd hardening: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

STATE="$LFCS_STATE_DIR/q16"
DIR="$COURSE_DIR/16"
KEY="$DIR/id_deploy"
SSHD=$(cat "$STATE/sshd" 2>/dev/null)
[[ -n "$SSHD" ]] || { SSHD=$(command -v sshd 2>/dev/null); [[ -n "$SSHD" ]] || SSHD=/usr/sbin/sshd; }
UNIT=$(cat "$STATE/unit" 2>/dev/null)
[[ -n "$UNIT" ]] || { UNIT=ssh; systemctl list-unit-files 2>/dev/null | grep -q '^sshd\.service' && UNIT=sshd; }

echo "Control test: the configuration parses and the daemon is listening..."
check "sshd -t reports no syntax error" "$SSHD" -t
check_contains "something is listening on port 22" ":22" "$(ss -H -ltn 2>/dev/null)"
check "the deploy user exists" id deploy

echo "Checking the effective configuration with sshd -T..."
EFF=$("$SSHD" -T 2>/dev/null)
check_contains "permitrootlogin is no" "permitrootlogin no" "$EFF"
check_contains "passwordauthentication is no" "passwordauthentication no" "$EFF"
check_contains "maxauthtries is 3" "maxauthtries 3" "$EFF"

echo "Checking the exception for user deploy..."
MATCH=$("$SSHD" -T -C user=deploy,host=lab,addr=127.0.0.1 2>/dev/null)
check_contains "passwordauthentication is yes for user deploy" "passwordauthentication yes" "$MATCH"

echo "Checking the key for deploy..."
check "the public key is still in $DIR" test -f "$KEY.pub"
if [[ -f "$KEY.pub" ]]; then
  PUB=$(awk '{print $2}' "$KEY.pub" 2>/dev/null)
  check_contains "the public key is in /home/deploy/.ssh/authorized_keys" "$PUB" \
    "$(cat /home/deploy/.ssh/authorized_keys 2>/dev/null)"
fi
check_eq "authorized_keys is mode 600 and owned by deploy" "600 deploy" \
  "$(stat -c '%a %U' /home/deploy/.ssh/authorized_keys 2>/dev/null)"
check_eq "/home/deploy/.ssh is mode 700" "700" \
  "$(stat -c '%a' /home/deploy/.ssh 2>/dev/null)"

echo "Effect test: a real ssh connection as deploy, using the key only..."
check "ssh -i $KEY deploy@localhost logs in without a password" \
  ssh -i "$KEY" -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 deploy@localhost true

echo "Checking the settings survive a reboot..."
check_persisted "PermitRootLogin no is written to disk" \
  '^[[:space:]]*PermitRootLogin[[:space:]]+no' \
  /etc/ssh/sshd_config.d/*.conf /etc/ssh/sshd_config
check_persisted "PasswordAuthentication no is written to disk" \
  '^[[:space:]]*PasswordAuthentication[[:space:]]+no' \
  /etc/ssh/sshd_config.d/*.conf /etc/ssh/sshd_config
check_persisted "MaxAuthTries 3 is written to disk" \
  '^[[:space:]]*MaxAuthTries[[:space:]]+3[[:space:]]*$' \
  /etc/ssh/sshd_config.d/*.conf /etc/ssh/sshd_config
check_persisted "the Match block for deploy is written to disk" \
  '^[[:space:]]*Match[[:space:]]+User[[:space:]]+deploy' \
  /etc/ssh/sshd_config.d/*.conf /etc/ssh/sshd_config
check_eq "$UNIT starts at boot" "enabled" "$(systemctl is-enabled "$UNIT" 2>/dev/null)"

summary
