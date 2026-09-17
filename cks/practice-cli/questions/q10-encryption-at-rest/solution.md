# Q10. Encrypt Secrets at Rest (EncryptionConfiguration) (solution)

## Steps

Four stages, and the fourth is the one people forget: turning encryption on does nothing to Secrets that already exist.

```bash
ssh <control-plane>
sudo -i
hostname
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak
```

**1. Generate a key and write the configuration.** The key must be exactly 32 random bytes, base64 encoded. Anything else and the API server refuses to start with a length complaint.

```bash
mkdir -p /etc/kubernetes/enc
head -c 32 /dev/urandom | base64
```

```bash
cat > /etc/kubernetes/enc/enc.yaml <<EOF
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: $(head -c 32 /dev/urandom | base64)
  - identity: {}
EOF
chmod 600 /etc/kubernetes/enc/enc.yaml
```

Provider order is the entire design of this file:

- The **first** provider is what everything is **written** with.
- **All** providers are tried, in order, when **reading**.

So `aescbc` first means new writes are encrypted, and `identity` last means the plaintext Secrets already in etcd can still be read. Put `identity` first and you have written a configuration that decrypts fine and encrypts nothing, which looks correct in every way except the one that matters.

**2. Wire it into the API server.** The flag plus a volume and a volumeMount, as always with anything the API server must read from the node.

```bash
vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

```yaml
    - --encryption-provider-config=/etc/kubernetes/enc/enc.yaml
```

```yaml
    volumeMounts:
    - name: enc
      mountPath: /etc/kubernetes/enc
      readOnly: true
```

```yaml
  volumes:
  - name: enc
    hostPath:
      path: /etc/kubernetes/enc
      type: DirectoryOrCreate
```

**3. Wait for it to come back.**

```bash
until curl -sk https://127.0.0.1:6443/readyz | grep -q ok; do sleep 2; done
kubectl get --raw=/version
```

**4. Re-encrypt what already exists.** Encryption applies at write time, so `enc-lab/pre-existing` is still sitting in etcd in the clear. Reading every Secret and writing it straight back is what re-encrypts them.

```bash
kubectl get secrets -A -o json | kubectl replace -f -
```

That is the whole trick, and it is worth recognising on sight: `get` decrypts through whichever provider can read it, `replace` writes back through the first provider, which is now `aescbc`.

**5. Prove it in etcd.** The API server will happily show you a decrypted Secret whether or not it is encrypted on disk, so the only honest check reads the raw bytes.

```bash
ETCDCTL_API=3 etcdctl \
  --cacert /etc/kubernetes/pki/etcd/ca.crt \
  --cert   /etc/kubernetes/pki/etcd/server.crt \
  --key    /etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/enc-lab/pre-existing | hexdump -C | head -5
```

```
00000000  2f 72 65 67 69 73 74 72  79 2f 73 65 63 72 65 74  |/registry/secret|
00000010  73 2f 65 6e 63 2d 6c 61  62 2f 70 72 65 2d 65 78  |s/enc-lab/pre-ex|
00000020  69 73 74 69 6e 67 0a 6b  38 73 3a 65 6e 63 3a 61  |isting.k8s:enc:a|
00000030  65 73 63 62 63 3a 76 31  3a 6b 65 79 31 3a ...     |escbc:v1:key1:..|
```

The `k8s:enc:aescbc:v1:key1:` prefix is the pass. Plain `k8s\x00\n\x0f` followed by readable text means it is still in the clear. The three certificate flags are not optional and are worth having in your fingers; there is no shortcut and `etcdctl` without them just hangs.

## Gotchas

- 32 bytes exactly, base64 encoded. `head -c 32 /dev/urandom | base64` produces it; typing a passphrase does not.
- The first provider writes; all providers read. `identity` belongs last.
- `identity: {}` needs the empty braces. `identity:` alone is a null value and is rejected.
- Turning encryption on encrypts nothing retroactively. The `get | replace` step is the task, not an optional extra.
- Volume and volumeMount, both. The API server is a container and cannot see the node's filesystem without them.
- Verify in etcd, not with `kubectl get secret`. The API server decrypts on read, so it always looks the same.
- `aesgcm` is the faster provider but requires key rotation discipline; `aescbc` is what these questions ask for and `secretbox` also appears. Read which one the question names.
- Q25 reads a Secret straight out of etcd with these same flags, and Q26 adds a second key and re-encrypts. The `etcdctl` invocation is the same in all three.

## Docs

`kubernetes.io/docs` is allowed and carries the full configuration example, and `etcd.io/docs` is allowed too, which is unusual and worth remembering when you need the `etcdctl` flags.

- https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
- https://kubernetes.io/docs/reference/config-api/apiserver-encryption.v1/ for the schema
- https://etcd.io/docs/ for `etcdctl get` and its TLS options
