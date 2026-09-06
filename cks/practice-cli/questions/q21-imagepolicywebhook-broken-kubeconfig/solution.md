# Q21. ImagePolicyWebhook: complete the config and deny unverified images (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

Everything happens on the control-plane node, as root.

**1. Read what is already there before changing anything.**

```bash
cd /etc/kubernetes/admission-controllers
cat admission-config.yaml
cat kubeconfig.yaml
```

The `cluster` entry has a `certificate-authority` but no `server`, so the API server has no address to call. Wiring this file in as it stands kills the API server.

**2. Add the missing `server` line to the cluster entry.**

```bash
cat > /etc/kubernetes/admission-controllers/kubeconfig.yaml <<'EOF'
apiVersion: v1
kind: Config
clusters:
- name: bouncer_webhook
  cluster:
    certificate-authority: /etc/kubernetes/admission-controllers/webhook-ca.crt
    server: https://image-bouncer.default.svc:1323/image_policy
contexts:
- name: bouncer_validator
  context:
    cluster: bouncer_webhook
    user: api-server
current-context: bouncer_validator
preferences: {}
users:
- name: api-server
  user: {}
EOF
```

**3. Make the plugin fail closed.**

```bash
sed -i 's/defaultAllow: true/defaultAllow: false/' /etc/kubernetes/admission-controllers/admission-config.yaml
grep defaultAllow /etc/kubernetes/admission-controllers/admission-config.yaml
```

The file should now read:

```yaml
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
      defaultAllow: false
```

**4. Take a copy of the manifest before editing it.**

```bash
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak
```

**5. Edit the static pod manifest.** Three separate edits are needed, and missing any one of them is the usual way this question is lost.

```bash
vim /etc/kubernetes/manifests/kube-apiserver.yaml
```

Add `ImagePolicyWebhook` to the existing plugin list, or add the flag if there is none:

```yaml
    - --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook
    - --admission-control-config-file=/etc/kubernetes/admission-controllers/admission-config.yaml
```

Mount the directory into the container:

```yaml
    volumeMounts:
    - name: admission-config
      mountPath: /etc/kubernetes/admission-controllers
      readOnly: true
```

And declare the volume next to the other `hostPath` volumes:

```yaml
  volumes:
  - name: admission-config
    hostPath:
      path: /etc/kubernetes/admission-controllers
      type: DirectoryOrCreate
```

**6. Watch it restart.** The kubelet notices the changed manifest within about 20 seconds. Until the new pod is up, `kubectl` returns a connection error, which is normal.

```bash
watch crictl ps
```

When the container stays in `Running` rather than cycling, the API server accepted the configuration:

```bash
curl -sk https://127.0.0.1:6443/readyz
kubectl get nodes
```

If it never comes back, read the logs of the exited container and undo the change:

```bash
crictl ps -a | grep kube-apiserver
crictl logs <container-id>
cp /root/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml
```

**7. Test the effect.**

```bash
kubectl run ipw-probe --image=nginx --dry-run=server
```

The request is refused, and the message names the webhook URL. A namespace still creates normally, because the plugin only inspects pods:

```bash
kubectl create namespace ipw-control --dry-run=server
```

## Why

`ImagePolicyWebhook` is a built-in admission plugin, not a `ValidatingWebhookConfiguration` object. It is configured entirely on the API server through a file, which is why three things have to line up: the plugin has to be enabled, `--admission-control-config-file` has to point at the `AdmissionConfiguration` document, and the directory holding that document has to be visible inside the static pod. The API server runs as a container, so a path that exists on the node means nothing until a `hostPath` volume and a `volumeMount` put it inside.

`defaultAllow` decides what happens when the backend does not answer. With `true` the plugin fails open and an outage silently disables the control, which is the same as not having it. With `false` it fails closed, and a backend that is down stops all pod creation. That trade is the whole point of the setting, and an exam question that says "unverified images must be denied" is asking for `false`.

The missing `server` line is the reason this question is on the list of ways candidates lose a cluster. The kubeconfig looks complete, `kubectl` never reads it, and no validation runs until the API server itself parses it during plugin initialisation. At that moment the process exits, the static pod crash-loops, and every diagnostic that relies on `kubectl` is gone. The only tools left are the ones that talk to the container runtime directly, `crictl ps -a` and `crictl logs`, or the kubelet journal. Checking the file first costs ten seconds and skipping the check can cost the whole question.

## Verify

```bash
grep server: /etc/kubernetes/admission-controllers/kubeconfig.yaml
grep defaultAllow /etc/kubernetes/admission-controllers/admission-config.yaml
grep -E 'admission-control-config-file|ImagePolicyWebhook|admission-controllers' /etc/kubernetes/manifests/kube-apiserver.yaml
curl -sk --max-time 5 https://127.0.0.1:6443/readyz
kubectl create namespace ipw-control --dry-run=server   # still admitted
kubectl run ipw-probe --image=nginx --dry-run=server     # rejected
```

## Docs

**Allowed:** `https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/`. The `ImagePolicyWebhook` section carries a complete `AdmissionConfiguration` example and the kubeconfig layout, including the note that the `server` field is where the remote service goes. Search the page for "imagePolicy".

The static pod flags themselves are on `https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/`.
