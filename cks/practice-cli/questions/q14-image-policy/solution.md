# Q14. Restrict Images via ImagePolicyWebhook/Registry (solution)

**Concept & Explanation:**

`ImagePolicyWebhook` makes the apiserver consult an external service to allow or deny every image; it needs an `AdmissionConfiguration` file, a webhook kubeconfig, the plugin enabled, and the hostPath volume mount that lets the static pod read both files. `defaultAllow` decides what happens when the backend is unreachable: `false` fails closed, so an unavailable bouncer blocks every new pod.

**Solution — Step by Step:**

```yaml
# /etc/kubernetes/admission-controllers/admission-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/admission-controllers/kubeconfig.yaml
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: false        # fail closed
```
```yaml
# /etc/kubernetes/manifests/kube-apiserver.yaml (back it up first)
    - --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook
    - --admission-control-config-file=/etc/kubernetes/admission-controllers/admission-config.yaml
    volumeMounts:
    - {name: admission, mountPath: /etc/kubernetes/admission-controllers, readOnly: true}
  volumes:
  - {name: admission, hostPath: {path: /etc/kubernetes/admission-controllers, type: DirectoryOrCreate}}
```
```bash
# The kubelet restarts the static pod; wait for readiness, then probe admission
sudo crictl ps | grep kube-apiserver
curl -sk https://127.0.0.1:6443/readyz
kubectl run ipw-probe --image=nginx --dry-run=server   # refused by ImagePolicyWebhook
```

**Key Points to Remember:**

- ImagePolicyWebhook = config file + webhook kubeconfig + apiserver flags + **volume mounts**; `defaultAllow: false` fails closed.
- Back up the apiserver manifest; a wrong path here breaks the control plane.
- Without the volume mount the apiserver cannot read the config and refuses to start — check `/var/log/pods` or `crictl logs` when it stays down.

**Official Documentation:**
- https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#imagepolicywebhook

---
