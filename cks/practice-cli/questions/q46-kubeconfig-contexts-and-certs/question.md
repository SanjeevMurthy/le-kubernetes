# Q46. Read the contexts and decode the certificate inside a kubeconfig

**Host:** any host with `kubectl` and `openssl`. Work in `/opt/course/46/` (or `$COURSE_DIR/46/` on this lab).

A kubeconfig for several clusters was handed over during an incident review. It is at `/opt/course/46/kubeconfig`. It is not your own kubeconfig and must not become it: do not copy it over `~/.kube/config` and do not change your current context.

1. Write the name of every context in that file to `/opt/course/46/contexts`, one per line and nothing else on each line.

2. Write the name of the file's own current context to `/opt/course/46/current`.

3. The user `green-restricted` authenticates with a client certificate embedded in the file. Decode it and write:

   - its Common Name to `/opt/course/46/cert-cn`
   - its Organization to `/opt/course/46/cert-group`

   Each file holds that one value alone, with no `CN=` or `O=` prefix around it.

Every answer is in the file. Nothing here talks to a cluster, and none of these clusters is reachable.
