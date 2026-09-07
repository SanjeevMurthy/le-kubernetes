# Q14. Restrict Images via ImagePolicyWebhook/Registry

**Host:** the control-plane node, as root (`ssh` to the control plane, then `sudo -i`).

Only images cleared by the image bouncer webhook may run on this cluster, but nothing
enforces that today. The admission configuration `/etc/kubernetes/admission-controllers/admission-config.yaml`
and its webhook kubeconfig `/etc/kubernetes/admission-controllers/kubeconfig.yaml` already
exist, yet the config is fail-open and `kube-apiserver` does not use it at all.

1. Edit `/etc/kubernetes/admission-controllers/admission-config.yaml` so the plugin fails
   closed: `defaultAllow: false`.
2. Wire the plugin into `kube-apiserver` in `/etc/kubernetes/manifests/kube-apiserver.yaml`:
   - add `ImagePolicyWebhook` to `--enable-admission-plugins`
   - add `--admission-control-config-file=/etc/kubernetes/admission-controllers/admission-config.yaml`
   - add the hostPath volume and volumeMount for `/etc/kubernetes/admission-controllers`,
     or the API server will not come back up.
3. Bring the API server back to ready and confirm the plugin now rejects pods:
   `kubectl run ipw-probe --image=nginx --dry-run=server` must be refused, because the
   webhook backend cannot clear the image.
