#!/bin/bash
# Q10 systemd unit: provide the account and the application, and make sure no
# unit for it exists yet.
source "$(dirname "$0")/../../lib/env.sh"
require_root "$@"

systemctl disable --now inventory.service >/dev/null 2>&1
rm -f /etc/systemd/system/inventory.service
rm -rf /etc/systemd/system/inventory.service.d
rm -f /etc/systemd/system/multi-user.target.wants/inventory.service
systemctl daemon-reload

id inventory >/dev/null 2>&1 || useradd -r -M -d /opt/inventory -s /usr/sbin/nologin inventory

mkdir -p /opt/inventory
echo "inventory-ok" > /opt/inventory/index.html

cat > /opt/inventory/server.sh <<'SHEOF'
#!/bin/bash
# Lab application. Stays in the foreground and serves /opt/inventory on 9090.
exec python3 -m http.server 9090 --directory /opt/inventory
SHEOF

chmod 755 /opt/inventory/server.sh
chown -R inventory:inventory /opt/inventory

echo "Setup complete."
echo "  Application: /opt/inventory/server.sh, listens on TCP 9090, stays in the foreground"
echo "  Account:     inventory ($(id inventory 2>/dev/null))"
echo "  Units:       no inventory.service exists yet"
echo "  Port 9090:   $(ss -H -ltn 2>/dev/null | grep -c ':9090') listener(s) right now"
