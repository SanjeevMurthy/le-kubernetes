# Q09. Serve a custom document root on a custom port under SELinux enforcing

SELinux is a RHEL family technology, so this question runs on the Rocky host only. The Ubuntu host uses AppArmor and the CLI skips this question there.

Apache is installed. `/etc/httpd/conf.d/lab-site.conf` already sets `Listen 8081`, `DocumentRoot /srv/site` and a matching `<Directory>` block, and `/srv/site/index.html` already exists. The Apache configuration is correct and needs no edits. Even so, `systemctl start httpd` fails.

Make all of the following true, without turning SELinux off.

1. SELinux is in enforcing mode now, and is still in enforcing mode after a reboot.
2. `httpd` is running and starts at boot.
3. `curl http://localhost:8081/` returns the page.
4. `/srv/site` and its contents carry the `httpd_sys_content_t` type, in a way that survives a relabel.
5. TCP port 8081 is known to SELinux as an http port.
6. The `httpd_can_network_connect` boolean is on, permanently.
7. Port 8081/tcp is open in firewalld, now and after a reboot.

`ausearch -m avc -ts recent` is the fastest way to see what SELinux denied.
