# Q21. ImagePolicyWebhook: complete the config and deny unverified images

`ssh` to the control-plane node and work as root.

This cluster is meant to admit only images that an external image bouncer has verified. Someone prepared the admission files under `/etc/kubernetes/admission-controllers/` and then stopped half way:

- `admission-config.yaml` names the `ImagePolicyWebhook` plugin, but it is currently fail-open, so a webhook that cannot be reached lets everything through.
- `kubeconfig.yaml` describes the backend and its certificate authority, but it is incomplete.
- Service `image-bouncer` in namespace `default` is the backend. It listens on port 1323 and the policy path is `/image_policy`. It has no endpoints in this lab, which is exactly what makes fail-closed behaviour visible.

The `kube-apiserver` static pod at `/etc/kubernetes/manifests/kube-apiserver.yaml` does not use any of this yet.

1. Complete `/etc/kubernetes/admission-controllers/kubeconfig.yaml` so that the webhook backend is reached at `https://image-bouncer.default.svc:1323/image_policy`.
2. Change `/etc/kubernetes/admission-controllers/admission-config.yaml` so that a webhook that cannot be reached denies the request instead of allowing it.
3. Wire the API server up: enable the `ImagePolicyWebhook` plugin, point it at `/etc/kubernetes/admission-controllers/admission-config.yaml`, and make the directory `/etc/kubernetes/admission-controllers` readable inside the static pod.
4. Bring the API server back to ready and confirm that `kubectl run ipw-probe --image=nginx --dry-run=server` is now rejected.

Read the kubeconfig before you wire it in. An API server started against an admission configuration it cannot load does not come up at all, and once it is down there is no `kubectl` left to tell you why.
