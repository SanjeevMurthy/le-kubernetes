# Q33. Restrict TLS versions and ciphers

**Host:** the control-plane node, root shell (`sudo -i`).

Both `kube-apiserver` and `etcd` currently accept whatever their Go runtime defaults allow, which includes TLS 1.2 and a long list of cipher suites. An auditor wants the control plane pinned down.

1. Configure `kube-apiserver` so that it refuses anything below TLS 1.3, using `--tls-min-version=VersionTLS13` in `/etc/kubernetes/manifests/kube-apiserver.yaml`.

2. Configure `etcd` so that it offers a restricted cipher list, using `--cipher-suites=` in `/etc/kubernetes/manifests/etcd.yaml`. The list must include `TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384`.

3. Both static Pods must come back and the cluster must keep working: `kubectl get nodes` has to answer.

4. Prove the effect on the API server port with `openssl`:

   ```
   openssl s_client -connect 127.0.0.1:6443 -tls1_2 </dev/null    # must fail the handshake
   openssl s_client -connect 127.0.0.1:6443 -tls1_3 </dev/null    # must negotiate TLSv1.3
   ```

Editing a static Pod manifest restarts the Pod. Give the kubelet up to a minute for each one, and change one file at a time so that a mistake is easy to attribute.
