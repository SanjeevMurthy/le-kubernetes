# Q25. Read a Secret straight from etcd

**Host:** the control-plane node, as root (`ssh` to the control plane, then `sudo -i`).

Namespace `etcd-lab` holds the Secret `vault-token`, which has a single key `token`. Encryption at rest is not configured on this cluster, so etcd stores the value in the clear.

Show that anyone with read access to etcd owns that value, without going through the API server for the first half of the task.

1. Read the key `/registry/secrets/etcd-lab/vault-token` directly from etcd with `etcdctl`, using the client certificates under `/etc/kubernetes/pki/etcd/`. Write the plain-text value of `token`, and nothing else, to `/opt/course/25/etcd.txt` (or `$COURSE_DIR/25/etcd.txt` on this lab).

2. Read the same value the ordinary way, through `kubectl`, and write it to `/opt/course/25/kubectl.txt` (or `$COURSE_DIR/25/kubectl.txt` on this lab).

The two files must hold the same string. Do not change or delete the Secret.

The value is generated fresh every time this question is set up, so it cannot be memorised.
