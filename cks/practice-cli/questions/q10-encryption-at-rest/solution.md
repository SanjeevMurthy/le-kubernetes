# Q10. Encrypt Secrets at Rest (EncryptionConfiguration) (solution)

**Concept & Explanation:**

The apiserver encrypts resources before writing to etcd when given an `EncryptionConfiguration` via `--encryption-provider-config`. It only encrypts new writes, so existing Secrets must be rewritten. Encrypted etcd values are prefixed `k8s:enc:aescbc:`.

**Solution — Step by Step:**

```bash
# 1. 32-byte key
head -c 32 /dev/urandom | base64
```
```yaml
# 2. /etc/kubernetes/enc/enc.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources: ["secrets"]
  providers:
  - aescbc: {keys: [{name: key1, secret: <BASE64_KEY>}]}
  - identity: {}
```
```bash
# 3. apiserver: add flag + mount the dir, then it restarts
#   - --encryption-provider-config=/etc/kubernetes/enc/enc.yaml
#   volumeMount + hostPath volume for /etc/kubernetes/enc
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kas.bak
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml

# 4. Re-encrypt the secrets that already exist (the config only affects new writes)
kubectl get secrets -A -o json | kubectl replace -f -

# 5. Verify in etcd
sudo ETCDCTL_API=3 etcdctl get /registry/secrets/enc-lab/pre-existing \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key | hexdump -C | head   # k8s:enc:aescbc:
```

**Key Points to Remember:**

- **Re-encrypt** existing Secrets (`get … | replace -f -`) — new config only affects new writes.
- Keep `identity` as the last provider so reads of not-yet-encrypted data still work.
- Add the apiserver `volumes`/`volumeMounts` for `/etc/kubernetes/enc` or it can't read the config.

**Official Documentation:**
- https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/

---
