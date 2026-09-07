# Q20. Reverse proxy in front of an application

An application on this host listens on `127.0.0.1:9000` and answers `backend-ok`. It is deliberately bound to loopback, so nothing outside the host can reach it directly.

nginx is installed but stopped and disabled, and its packaged default site has been taken out of the way.

Put nginx in front of the application:

1. `curl -s http://localhost/` must return `backend-ok`
2. nginx must forward to `http://127.0.0.1:9000`
3. nginx must start at boot
4. on Rocky the SELinux boolean that lets a web server open outbound connections must be on, and on across a reboot

Do not change the application. It stays on loopback, which is the point of putting a proxy in front of it.

Check the configuration with `nginx -t` before reloading. On Rocky a perfectly correct configuration returns `502 Bad Gateway` until the SELinux boolean is set, and the reason is in the audit log rather than the nginx error log.
