# Q08. Run a web container with limits and a restart policy that survives reboot

The image `docker.io/library/nginx:1.27` is already pulled and the directory `/srv/web` exists and is empty.

Run a container that meets all of the following.

1. It is named `web` and runs that nginx image.
2. Port `8080` on the host reaches port `80` in the container.
3. Its memory is capped at 256 MB.
4. `/srv/web` on the host is mounted read-only at `/usr/share/nginx/html` in the container.
5. `/srv/web/index.html` contains the single word `hello`, so `curl localhost:8080` returns it.
6. Its restart policy is `always`.
7. The container comes back by itself after the host reboots.

Requirement 7 is not the same as requirement 6. A restart policy is honoured by the container engine while the engine is running, and nothing starts the engine after a reboot on its own.

The grader reads `curl localhost:8080`, `podman inspect web`, and whatever you put in place for requirement 7.
