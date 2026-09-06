# Q26. Encryption at rest: add a new key and re-encrypt

**Host:** the control-plane node, as root (`ssh` to the control plane, then `sudo -i`).

Encryption at rest is already working on this cluster. `kube-apiserver` runs with `--encryption-provider-config=/etc/kubernetes/enc/enc.yaml`, that file has one `aescbc` key named `key1`, and the Secrets `s1`, `s2` and `s3` in namespace `enc-lab` are already stored in etcd encrypted under it.

`key1` is being retired.

1. Add a second `aescbc` key named `key2` with fresh 32-byte key material, and make it the write key. Keep `key1` available for reading, and keep `identity` last.

2. Get `kube-apiserver` to load the new configuration and come back ready.

3. Re-encrypt every Secret in namespace `enc-lab` so that `s1`, `s2` and `s3` are stored in etcd under `key2`, not `key1`.

4. Confirm with `etcdctl` (client certificates under `/etc/kubernetes/pki/etcd/`) that the stored values now begin with `k8s:enc:aescbc:v1:key2`.

Do not delete `key1` from the configuration and do not delete the Secrets.
