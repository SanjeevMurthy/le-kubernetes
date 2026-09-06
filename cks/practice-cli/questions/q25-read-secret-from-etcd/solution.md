# Q25. Read a Secret straight from etcd (solution)

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
mkdir -p /opt/course/25
```

**1. Build the etcdctl command once.** etcd only accepts mutually authenticated clients, so all three certificate flags are required. Put them in a shell function so the rest of the task is short.

```bash
e() {
  ETCDCTL_API=3 etcdctl \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key "$@"
}
e endpoint health
```

The certificate paths are in the etcd static pod manifest if the names differ on your cluster:

```bash
grep -E 'cert-file|key-file|trusted-ca-file' /etc/kubernetes/manifests/etcd.yaml
```

**2. Read the key.** Every object lives under `/registry/<resource>/<namespace>/<name>`.

```bash
e get /registry/secrets/etcd-lab/vault-token > /tmp/25.raw
```

**3. Pull the value out.** The stored value is a protobuf-encoded Secret. The Secret's data is held as raw bytes, not base64, so the token appears verbatim in the middle of the binary. `strings` is the quickest way to see it.

```bash
strings /tmp/25.raw
```

The output shows the key name `token` and, next to it, the 16-character value. `hexdump -C /tmp/25.raw | head -40` shows the same thing with the surrounding bytes if the `strings` output is ambiguous.

Write it down, exactly as printed:

```bash
echo '<the 16 characters you just read>' > /opt/course/25/etcd.txt
```

**4. Read the same value through the API.** Here the value *is* base64, because that is how the API represents `data`.

```bash
kubectl -n etcd-lab get secret vault-token -o jsonpath='{.data.token}' \
  | base64 -d > /opt/course/25/kubectl.txt
echo >> /opt/course/25/kubectl.txt
```

**5. Compare.**

```bash
cat /opt/course/25/etcd.txt /opt/course/25/kubectl.txt
```

If the token is alphanumeric, as it is here, the extraction can also be done without reading the dump by hand:

```bash
e get /registry/secrets/etcd-lab/vault-token | strings | grep -A1 -w token | tail -1 \
  > /opt/course/25/etcd.txt
```

Check the result before trusting it. Reading the dump is the reliable method under exam conditions.

## Why

A Secret is not encrypted. It is base64-encoded, and base64 is an encoding, not a cipher. Unless the API server runs with `--encryption-provider-config`, every Secret sits in etcd exactly as it was written, which is why the raw bytes in step 3 are readable text.

That makes etcd read access equivalent to holding every credential in the cluster. It is the reason the CIS benchmark insists on client certificate authentication for etcd, file permissions of 0600 on the etcd data directory, and encryption at rest for the `secrets` resource.

The contrast between the two halves of this task is the lesson. Through the API you need RBAC on `secrets` in one namespace, and the request is audited. Through etcd you need one client certificate and there is no audit trail at all, for any namespace.

`/registry/<resource>/<namespace>/<name>` is worth memorising. `e get /registry --prefix --keys-only` lists everything etcd holds, which is a fast way to find the path when the resource name is not obvious.

## Verify

```bash
cat /opt/course/25/etcd.txt
cat /opt/course/25/kubectl.txt
kubectl -n etcd-lab get secret vault-token -o jsonpath='{.data.token}' | base64 -d; echo
```

All three print the same 16 characters.

## Docs

**Allowed:** `https://etcd.io/docs/` for `etcdctl get` and the transport security flags, and `https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/` for the fix, which is Q10 and Q26.

Worth memorising instead of looking up: the three certificate flags, `ETCDCTL_API=3`, and the `/registry/<resource>/<namespace>/<name>` key layout.
