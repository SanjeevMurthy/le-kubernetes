#!/bin/bash
# Q43 ACLs: Verify
source "$(dirname "$0")/../../lib/checks.sh"
source "$(dirname "$0")/../../lib/env.sh"

# acl_eff <getfacl output> <entry prefix>
# Prints the permission that is actually in force for one entry, which is the
# granted permission capped by the mask. getfacl spells that out with
# "#effective:" whenever the mask reduces the entry.
acl_eff() {
  local out="$1" pfx="$2" line
  line=$(printf '%s\n' "$out" | grep -E "^${pfx}" | head -1)
  [[ -z "$line" ]] && return 0
  if [[ "$line" == *"#effective:"* ]]; then
    printf '%s' "${line##*#effective:}" | tr -d '[:space:]'
  else
    printf '%s' "${line%%#*}" | awk -F: '{print $NF}' | tr -d '[:space:]'
  fi
}

echo "Checking the mode bits on /srv/projects..."
check_eq "/srv/projects is mode 2770" "2770" "$(stat -c %a /srv/projects 2>/dev/null)"
check_eq "/srv/projects shows SGID and nothing for others" "drwxrws---" \
  "$(stat -c %A /srv/projects 2>/dev/null)"
check_eq "/srv/projects belongs to group devs" "devs" "$(stat -c %G /srv/projects 2>/dev/null)"

FACL_P=$(getfacl -p /srv/projects 2>/dev/null)
FACL_A=$(getfacl -p /srv/projects/alpha 2>/dev/null)

echo "Checking the ACLs, mask included..."
check_eq "group qa has r-x in effect on /srv/projects itself" "r-x" \
  "$(acl_eff "$FACL_P" 'group:qa:')"
check_eq "group qa has r-x in the default ACL, so new entries inherit it" "r-x" \
  "$(acl_eff "$FACL_P" 'default:group:qa:')"
check_eq "ana has rwx in effect on /srv/projects/alpha" "rwx" \
  "$(acl_eff "$FACL_A" 'user:ana:')"
check_not "group qa was not given write access" \
  grep -qE '^(default:)?group:qa:.w' <<< "$FACL_P"

echo "Checking what the accounts can actually do..."
PROBE="/srv/projects/.lfcs-probe"
rm -f "$PROBE"
echo "probe" > "$PROBE"
check "a new file appears inside /srv/projects" test -f "$PROBE"
check_eq "a new file inside /srv/projects inherits group devs" "devs" \
  "$(stat -c %G "$PROBE" 2>/dev/null)"
check "qauser can traverse /srv/projects" runuser -u qauser -- test -x /srv/projects
check "qauser can read a file created inside /srv/projects" runuser -u qauser -- test -r "$PROBE"
check_not "qauser cannot write inside /srv/projects" runuser -u qauser -- test -w /srv/projects
check "ana can write inside /srv/projects/alpha" runuser -u ana -- test -w /srv/projects/alpha
rm -f "$PROBE"

echo ""
echo "Note: an ACL and the SGID bit live in the filesystem itself, not in a"
echo "configuration file, so the getfacl and stat checks above are the"
echo "persistence check. Nothing here needs reapplying after a reboot."

summary
