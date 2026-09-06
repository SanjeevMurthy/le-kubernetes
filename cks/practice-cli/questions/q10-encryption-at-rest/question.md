# Q10. Encrypt Secrets at Rest (EncryptionConfiguration)

**Host:** the control-plane node, as root (`ssh` to the control plane, then `sudo -i`).

Secrets are stored in etcd in plain text: `kube-apiserver` runs with no
`--encryption-provider-config`. Namespace `enc-lab` already contains the Secret
`pre-existing`, which was written before encryption was configured.

1. Write an `EncryptionConfiguration` to `/etc/kubernetes/enc/enc.yaml` that encrypts
   `secrets` with an `aescbc` provider (a 32-byte base64 key) and keeps `identity` as the
   last provider.
2. Wire it into `kube-apiserver` in `/etc/kubernetes/manifests/kube-apiserver.yaml` with
   `--encryption-provider-config=/etc/kubernetes/enc/enc.yaml`, plus a hostPath volume and
   volumeMount for `/etc/kubernetes/enc`, and bring the API server back to ready.
3. Re-encrypt the Secrets that already exist, so that `enc-lab/pre-existing` is stored
   encrypted too.
4. Confirm with `etcdctl` (certs under `/etc/kubernetes/pki/etcd/`) that
   `/registry/secrets/enc-lab/pre-existing` is stored with the `k8s:enc:aescbc` prefix.
