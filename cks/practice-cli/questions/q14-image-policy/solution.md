# Q14. Restrict Images via ImagePolicyWebhook/Registry (solution)

## Steps

Three files have to agree before this works, and the API server restarts on the last of them. This is the task that most often takes a cluster down in reported exams, so back the manifest up first.

```bash
ssh <control-plane>
sudo -i
hostname
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak
ls /etc/kubernetes/admission-controllers/
```

**1. Read the two files that already exist.** Both are provided; knowing what is in them tells you what is missing.

```bash
cat /etc/kubernetes/admission-controllers/admission-config.yaml
cat /etc/kubernetes/admission-controllers/kubeconfig.yaml
```

**2. Make the plugin fail closed.** One field. `defaultAllow: true` means that when the webhook cannot be reached, every image is admitted, which is an image policy that permits everything the moment it matters most.

```bash
vi /etc/kubernetes/admission-controllers/admission-config.yaml
```

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

**3. Check the webhook kubeconfig has a `server:`.** This is worth its own step because omitting it is the single mistake most often reported as having broken a candidate's cluster: the API server starts, admission is enabled, and every request fails on a webhook with nowhere to go.

```bash
grep -A3 'cluster:' /etc/kubernetes/admission-controllers/kubeconfig.yaml
```

```yaml
  cluster:
    certificate-authority: /etc/kubernetes/admission-controllers/ca.crt
    server: https://image-bouncer.default.svc:1323/image_policy
```

**4. Wire it into the API server.** Three separate edits in the manifest, and all three are required.

```bash
vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

The plugin, appended to the existing list rather than replacing it:

```yaml
    - --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook
    - --admission-control-config-file=/etc/kubernetes/admission-controllers/admission-config.yaml
```

The mount:

```yaml
    volumeMounts:
    - name: admission-config
      mountPath: /etc/kubernetes/admission-controllers
      readOnly: true
```

And the volume:

```yaml
  volumes:
  - name: admission-config
    hostPath:
      path: /etc/kubernetes/admission-controllers
      type: DirectoryOrCreate
```

The API server is a container. Without the mount it cannot read a config file that is plainly there on the node, and it exits on startup naming a path you are looking at.

**5. Wait for it, then prove the denial.**

```bash
until curl -sk https://127.0.0.1:6443/readyz | grep -q ok; do sleep 2; done

kubectl run ipw-probe --image=nginx --dry-run=server
```

The refusal should name the webhook:

```
Error from server (Forbidden): pods "ipw-probe" is forbidden:
Post "https://image-bouncer.default.svc:1323/image_policy?timeout=30s": dial tcp: ...
```

With `defaultAllow: false`, an unreachable backend denies. That is the correct behaviour and the point of the change in step 2. `--dry-run=server` runs admission without creating anything, which is the quickest way to test this.

## If the API server does not come back

```bash
crictl ps -a | grep kube-apiserver
crictl logs "$(crictl ps -a --name kube-apiserver -q | head -1)" 2>&1 | tail -30
tail -30 /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/*.log
```

The three failures worth recognising on sight:

- `no such file or directory` on the admission config: the volume or volumeMount is missing.
- `unknown admission plugin "ImagePolicyWebhook"`: the name is misspelled, or it replaced rather than joined the existing plugin list.
- a YAML parse error: indentation moved while editing.

```bash
cp /root/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml
```

## Gotchas

- `--enable-admission-plugins` is a replace, not an append. Read the existing value and add to it, or you silently switch `NodeRestriction` off.
- `defaultAllow: false` is what makes this a control. With `true` the question has no effect worth verifying.
- The `server:` field in the webhook kubeconfig is not optional and its absence is the reported cluster-killer.
- Both the volume and the volumeMount. Adding one and not the other is the usual half-edit.
- Test with `--dry-run=server`, not `--dry-run=client`. Client-side dry run never reaches admission and always appears to succeed.
- Q21 is the same mechanism with a deliberately broken kubeconfig, which is the variant reported to have failed a candidate outright.

## Docs

`kubernetes.io/docs` is allowed and carries the AdmissionConfiguration example in full, which is quicker to copy than to type.

- https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#imagepolicywebhook
- https://kubernetes.io/docs/reference/config-api/apiserver-config.v1/ for the `AdmissionConfiguration` schema
