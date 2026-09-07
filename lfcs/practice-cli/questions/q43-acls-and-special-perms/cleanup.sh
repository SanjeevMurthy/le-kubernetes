#!/bin/bash
# Q43 ACLs: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

rm -rf /srv/projects

userdel -r ana >/dev/null 2>&1
userdel -r qauser >/dev/null 2>&1
groupdel devs >/dev/null 2>&1
groupdel qa >/dev/null 2>&1

echo "Cleanup complete. /srv/projects, the ana and qauser accounts and the devs and qa groups are gone."
