# Q20. Reverse proxy in front of an application (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

**1. Prove the backend works before proxying to it.**

```bash
ss -H -ltn | grep 9000
curl -s http://127.0.0.1:9000/        # backend-ok
```

**2. Write a server block.**

```bash
vim /etc/nginx/conf.d/app.conf
```

```
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:9000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

On Ubuntu the file can also go in `/etc/nginx/sites-available/app` with a symlink into `sites-enabled/`. Both directories are included from `nginx.conf`.

**3. Check the syntax, then start and enable.**

```bash
nginx -t
systemctl enable --now nginx
systemctl reload nginx
ss -H -ltn | grep ':80'
```

**4. Rocky only: let the web server make outbound connections.**

```bash
getsebool httpd_can_network_connect
setsebool -P httpd_can_network_connect on
systemctl restart nginx
```

**5. Test.**

```bash
curl -s http://localhost/            # backend-ok
```

## Why

A reverse proxy exists so the application can stay on loopback. The application then has exactly one way in, through a server that terminates the connection, applies whatever policy is configured, and opens a second connection to the backend. That second connection is what SELinux objects to on Rocky: the `httpd_t` domain is not allowed to open arbitrary network connections, so `proxy_pass` fails with a permission error the client sees as `502 Bad Gateway`, while `nginx -t` reports the configuration is fine and the nginx error log says only "connect() failed". `setsebool -P httpd_can_network_connect on` is the fix, and the `-P` is what makes it survive a reboot. Without `-P` the boolean is set in the running policy only, which is exactly the trap this domain is full of.

`proxy_pass` has one detail worth memorising. Written as `proxy_pass http://127.0.0.1:9000;` with no trailing path, nginx passes the request URI through unchanged. Written as `proxy_pass http://127.0.0.1:9000/;` with a trailing slash, nginx replaces the part of the URI that matched the `location` prefix. For `location /` the two look the same, and for `location /api/` they behave completely differently.

Most backends also need `proxy_set_header Host $host`, because nginx otherwise sends the upstream name in the `Host` header, and a backend that routes by virtual host then answers the wrong site or refuses.

The packaged default site is the other thing that gets in the way. Ubuntu ships a site in `sites-enabled/default` that listens on port 80 with `default_server`, and Rocky ships an equivalent server block inside `nginx.conf`. Whichever server is the default one answers any request whose `Host` header matches no `server_name`, so a new block is quietly ignored until the packaged one is removed or demoted.

`systemctl reload` re-reads the configuration without dropping connections, and `restart` drops them. Neither one has anything to do with the next boot: only `enable` does.

## Verify

```bash
curl -s http://127.0.0.1:9000/       # backend-ok, the backend itself
curl -s http://localhost/            # backend-ok, through the proxy
nginx -t
ss -H -ltn | grep ':80'
grep -R proxy_pass /etc/nginx/

systemctl is-enabled nginx
getsebool httpd_can_network_connect 2>/dev/null                       # Rocky, expect on
semanage boolean -l 2>/dev/null | grep httpd_can_network_connect      # the persistent value
```

## Docs

- `man 8 nginx` for the command line, and `/usr/share/doc/nginx` for the packaged example configuration
- `/usr/share/nginx/html` and `/etc/nginx/nginx.conf` for where the packaged default server lives
- `man 8 setsebool` and `man 8 getsebool` for the boolean and what `-P` does
- `man 8 semanage-boolean` for reading the persistent value back
- `man 1 systemctl` for the difference between `reload`, `restart` and `enable`
