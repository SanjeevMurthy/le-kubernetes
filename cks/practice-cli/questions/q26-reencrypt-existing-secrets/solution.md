# Q26. Encryption at rest: add a new key and re-encrypt (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

Everything happens on the control-plane node, as root.

```bash
ssh <control-plane>
sudo -i
```

**1. Look at what is already there.** The file has one key and identity last.

```bash
cat /etc/kubernetes/enc/enc.yaml
```

**2. Generate 32 bytes of new key material.**

```bash
head -c 32 /dev/urandom | base64
```

**3. Put the new key first.** Order inside the `keys` list decides which key encrypts. The first key of the first provider is the write key; every other key is only ever used to decrypt. So `key2` goes above `key1`, `key1` stays, and `identity` stays last.

```bash
cp /etc/kubernetes/enc/enc.yaml /etc/kubernetes/enc/enc.yaml.bak
vi /etc/kubernetes/enc/enc.yaml
```

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key2
              secret: <NEW_BASE64_KEY>
            - name: key1
              secret: <THE_EXISTING_KEY_UNCHANGED>
      - identity: {}
```

Copy the existing `key1` line across byte for byte. Losing it makes every Secret already in etcd unreadable.

**4. Restart the API server so it reads the new file.** The configuration is loaded at startup, so editing the file changes nothing on its own. Move the manifest out of the watched directory and back:

```bash
mv /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/
sleep 10
mv /etc/kubernetes/kube-apiserver.yaml /etc/kubernetes/manifests/
```

Wait for it to come back before touching anything else:

```bash
watch crictl ps | grep kube-apiserver
kubectl get nodes
```

**5. Re-encrypt.** Nothing rewrites existing rows by itself. Reading each Secret and writing it straight back is what moves it onto the new key.

```bash
kubectl -n enc-lab get secrets -o json | kubectl replace -f -
```

For the whole cluster, which is what a real key rotation means:

```bash
kubectl get secrets -A -o json | kubectl replace -f -
```

**6. Confirm in etcd.** The prefix names the key that encrypted the value, so this is the only check that distinguishes a correct configuration from a completed rotation.

```bash
ETCDCTL_API=3 etcdctl \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/enc-lab/s1 | hexdump -C | head -3
```

The value starts `k8s:enc:aescbc:v1:key2:`. If it still says `key1`, step 5 did not run or the API server had not restarted when it did.

## Why

An `EncryptionConfiguration` is an ordered list twice over. The provider list decides which provider writes, and inside a provider the key list decides which key writes. Both lists are searched top to bottom on read, so anything still readable stays readable as long as its key remains somewhere in the list. That is what makes rotation safe: add the new key above the old one, rotate the data, and only then remove the old key in a second edit.

Encryption applies to writes only. The API server never walks etcd rewriting rows, so a rotation that stops after editing the file leaves every existing Secret on the old key. `kubectl get ... -o json | kubectl replace -f -` is the standard trick: it is an ordinary update on each object, and an update is a write.

The restart matters for the same reason. Without `--encryption-provider-config-automatic-reload=true` the file is read once at startup, so a re-encryption run started before the restart completes writes everything back under `key1` again and looks like it did nothing.

Keeping `identity` last means Secrets that predate encryption still decrypt. Putting `identity` first would silently write everything in plain text, which is the classic way this configuration is got wrong.

## Verify

```bash
grep -n 'name: key' /etc/kubernetes/enc/enc.yaml     # key2 above key1
curl -sk https://127.0.0.1:6443/readyz               # ok
for s in s1 s2 s3; do
  ETCDCTL_API=3 etcdctl \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    get "/registry/secrets/enc-lab/$s" | head -c 60; echo
done
```

Each line begins `k8s:enc:aescbc:v1:key2`.

## Docs

**Allowed:** `https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/`. The page has the full provider list, the key-order rules and the exact `get ... | replace -f -` command under "Rotating a decryption key".

Worth memorising: the write key is the first key of the first provider, `identity` goes last, encryption applies to writes only, and the etcd prefix is `k8s:enc:<provider>:v1:<keyname>:`.
