# Q6. Restrict the API Server (apiserver flags) (solution)

**Concept & Explanation:**

The kube-apiserver runs as a static pod; its flags live in `/etc/kubernetes/manifests/kube-apiserver.yaml`. Editing the file makes the kubelet recreate the pod. A bad edit takes down the control plane, so back up first and know how to diagnose a failed restart.

**Solution — Step by Step:**

```bash
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kas.bak

# Correct these three flags under spec.containers[0].command:
#   - --anonymous-auth=false      (was true)
#   - --authorization-mode=Node,RBAC   (was AlwaysAllow)
#   - --profiling=false           (was true)
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml

# Wait for restart, then verify health:
sudo crictl ps | grep kube-apiserver
kubectl get --raw='/readyz'
kubectl get --raw='/version'

# Effect check — an anonymous call must now be refused (401/403):
curl -sk -o /dev/null -w '%{http_code}\n' https://127.0.0.1:6443/api

# If it does NOT recover:
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}')
sudo journalctl -u kubelet -f
```

**Key Points to Remember:**

- **Back up first.** A typo in the manifest stops the API server entirely.
- `--authorization-mode` is an ordered, comma-separated list: `Node,RBAC`. `AlwaysAllow` anywhere in it authorizes everything.
- The pod restart takes 30–90s and the API may be briefly unreachable; confirm with `/readyz`.

**Official Documentation:**
- https://kubernetes.io/docs/concepts/security/controlling-access/
- https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/
---
