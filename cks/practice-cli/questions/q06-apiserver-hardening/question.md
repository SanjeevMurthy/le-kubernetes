# Q6. Restrict the API Server (apiserver flags)

**Host:** the control-plane node named in the setup output (root shell: `sudo -i`).

The kube-apiserver static pod at `/etc/kubernetes/manifests/kube-apiserver.yaml` has been started with three insecure flags: `--anonymous-auth=true`, `--authorization-mode=AlwaysAllow` and `--profiling=true`. Back the manifest up before you edit it — a bad edit stops the control plane.

1. Set `--anonymous-auth=false` so unauthenticated callers are rejected.
2. Set `--authorization-mode=Node,RBAC` (no `AlwaysAllow`).
3. Set `--profiling=false`.
4. Bring the API server back: `curl -sk https://127.0.0.1:6443/readyz` must return `ok`, `kubectl get --raw=/version` must succeed, and an anonymous request `curl -sk -o /dev/null -w '%{http_code}' https://127.0.0.1:6443/api` must return `401` or `403`.
