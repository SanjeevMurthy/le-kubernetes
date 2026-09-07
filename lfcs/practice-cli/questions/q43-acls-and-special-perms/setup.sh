#!/bin/bash
# Q43 ACLs: build the directory tree, the two accounts and the two groups, and
# leave every permission wrong so both the mode bits and the ACLs are real work.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

command -v setfacl >/dev/null 2>&1 || pkg_install acl
if ! command -v setfacl >/dev/null 2>&1 || ! command -v getfacl >/dev/null 2>&1; then
  echo "setfacl and getfacl are missing. Install the acl package and run setup again."
  exit 1
fi

getent group devs >/dev/null 2>&1 || groupadd devs
getent group qa   >/dev/null 2>&1 || groupadd qa
id ana    >/dev/null 2>&1 || useradd -m -s /bin/bash -g devs -c 'Ana Diaz' ana
id qauser >/dev/null 2>&1 || useradd -m -s /bin/bash -g qa   -c 'QA User'  qauser
usermod -g devs ana
usermod -g qa qauser

rm -rf /srv/projects
mkdir -p /srv/projects/alpha
echo 'alpha project notes' > /srv/projects/alpha/README

chown root:root /srv/projects
chmod 755 /srv/projects
chown root:devs /srv/projects/alpha
chmod 2750 /srv/projects/alpha
setfacl -b /srv/projects >/dev/null 2>&1
setfacl -b -R /srv/projects/alpha >/dev/null 2>&1

if ! setfacl -m u:root:rwx /srv/projects 2>/dev/null; then
  echo "This filesystem does not accept ACLs. Mount /srv with ACL support and run setup again."
  exit 1
fi
setfacl -b /srv/projects

echo "Setup complete."
echo "  Tree:     /srv/projects and /srv/projects/alpha"
echo "  Accounts: ana (primary group devs), qauser (primary group qa)"
echo "  /srv/projects is now $(stat -c '%A %a %U:%G' /srv/projects) with no ACL"
echo "  /srv/projects/alpha is now $(stat -c '%A %a %U:%G' /srv/projects/alpha) with no ACL"
echo "  qauser cannot reach anything under /srv/projects yet, and ana cannot write to alpha."
