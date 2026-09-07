#!/bin/bash
# Q38 port conflict: Cleanup
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

systemctl unmask legacy.service >/dev/null 2>&1
systemctl disable --now legacy.service >/dev/null 2>&1
systemctl disable --now webapp.service >/dev/null 2>&1
rm -f /etc/systemd/system/legacy.service /usr/lib/systemd/system/legacy.service
rm -f /etc/systemd/system/webapp.service
rm -f /etc/systemd/system/multi-user.target.wants/legacy.service
rm -f /etc/systemd/system/multi-user.target.wants/webapp.service
systemctl daemon-reload
systemctl reset-failed legacy.service webapp.service >/dev/null 2>&1

pkill -f 'http.server 8090' >/dev/null 2>&1
rm -rf /srv/legacy /srv/webapp
rm -rf "${COURSE_DIR:?}/38"

echo "Cleanup complete. Both units, the mask, /srv/legacy, /srv/webapp and $COURSE_DIR/38 are gone."
