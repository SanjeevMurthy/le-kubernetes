# Q33. Restrict TLS versions and ciphers (solution)

## Steps

Everything happens on the control-plane node, as root.

**1. Back both manifests up outside `/etc/kubernetes/manifests/`.** The kubelet reads every file in that directory, so a `.bak` left beside the original starts a second copy of the Pod.

```bash
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak
cp /etc/kubernetes/manifests/etcd.yaml /root/etcd.yaml.bak
```

**2. Pin the API server to TLS 1.3.**

```bash
vim /etc/kubernetes/manifests/kube-apiserver.yaml
```

```yaml
spec:
  containers:
  - command:
    - kube-apiserver
    - --tls-min-version=VersionTLS13
```

Wait for it to come back before touching anything else:

```bash
watch crictl ps | grep kube-apiserver
curl -sk https://127.0.0.1:6443/readyz
kubectl get nodes
```

**3. Restrict the etcd cipher suites.**

```bash
vim /etc/kubernetes/manifests/etcd.yaml
```

```yaml
spec:
  containers:
  - command:
    - etcd
    - --cipher-suites=TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
```

etcd validates the names at start-up and exits on an unknown one, so check the container came up:

```bash
crictl ps | grep etcd
kubectl get pods -n kube-system -l component=etcd
```

If etcd does not come back, read why and fix the name:

```bash
crictl ps -a | grep etcd
crictl logs <container-id> 2>&1 | tail -20
```

**4. Confirm the flags are live, not just written.** The mirror Pod in the API shows the command the kubelet actually started.

```bash
kubectl get pods -n kube-system -l component=kube-apiserver \
  -o jsonpath='{.items[0].spec.containers[0].command}' | tr ' ' '\n' | grep tls
kubectl get pods -n kube-system -l component=etcd \
  -o jsonpath='{.items[0].spec.containers[0].command}' | tr ' ' '\n' | grep cipher
```

**5. Test the effect from outside the process.**

```bash
echo | openssl s_client -connect 127.0.0.1:6443 -tls1_2 2>&1 | head -5
echo | openssl s_client -connect 127.0.0.1:6443 -tls1_3 2>&1 | grep -E 'Protocol|Cipher'
```

The first prints an alert such as `tlsv1 alert protocol version` and negotiates `Cipher is (NONE)`. The second prints `Protocol  : TLSv1.3`.

## Why

The API server and etcd both terminate TLS themselves, and both fall back to the Go runtime defaults when no flag says otherwise. Those defaults still allow TLS 1.2 with cipher suites that an auditor will flag, including CBC-mode suites that have a long history of padding oracle attacks. Neither component reads a system-wide crypto policy, so the only place to fix this is the flag on the process.

`--tls-min-version` takes the Go constant name, not a number: `VersionTLS12` or `VersionTLS13`. A value like `1.3` is rejected and the API server will not start, which is the usual way this task is failed.

TLS 1.3 removes cipher negotiation as it existed in 1.2. Its three suites are fixed and Go does not let a program choose among them, which is why `--tls-cipher-suites` on the API server has no effect once the minimum is 1.3, and why the cipher part of this task lands on etcd, which still speaks 1.2 to its peers.

The reason to change one manifest at a time is recovery. Both Pods are static Pods started by the kubelet from the manifest directory. If both are edited at once and the cluster goes dark, there is no `kubectl` left to tell you which file was wrong, and `crictl logs` on two crash-looping containers is a slower path than reverting one known change.

## Verify

```bash
grep tls-min-version /etc/kubernetes/manifests/kube-apiserver.yaml
grep cipher-suites /etc/kubernetes/manifests/etcd.yaml
curl -sk https://127.0.0.1:6443/readyz
kubectl get nodes
kubectl get pods -n kube-system -l component=etcd
echo | openssl s_client -connect 127.0.0.1:6443 -tls1_2 2>&1 | grep -i 'alert\|Cipher is'
echo | openssl s_client -connect 127.0.0.1:6443 -tls1_3 2>&1 | grep 'Protocol'
```

## Docs

**Allowed:** `https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/` for `--tls-min-version` and `--tls-cipher-suites`, including the accepted constant names.

etcd's flags are not in the allowed set, so `--cipher-suites` and the suite names have to come from memory or from `etcd --help` on the node. The suite names are the Go names, in the form `TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384`, and etcd prints the full list of what it accepts when it rejects one.
