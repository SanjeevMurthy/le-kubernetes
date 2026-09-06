# Q22. kube-bench: fix the kubelet findings (solution)

<!-- toc -->
## Table of Contents

- [Steps](#steps)
- [Why](#why)
- [Verify](#verify)
- [Docs](#docs)

<!-- toc stop -->

## Steps

Everything happens on the worker node, as root.

```bash
ssh <worker>
sudo -i
```

**1. Run the audit and read the remediation.** kube-bench prints the fix for every finding, so there is no need to remember the CIS wording.

```bash
kube-bench run --targets node --check 4.2.1,4.2.2,4.2.4
```

The three findings map onto three keys in one file. Confirm which file the kubelet actually uses before editing anything:

```bash
systemctl status kubelet | grep -i config
grep config /var/lib/kubelet/kubeadm-flags.env /etc/systemd/system/kubelet.service.d/*.conf
```

**2. Back the file up.** A kubelet that cannot parse its configuration does not start, and the node goes `NotReady`.

```bash
cp /var/lib/kubelet/config.yaml /root/kubelet-config.yaml.bak
```

**3. Edit the three keys.**

```bash
vim /var/lib/kubelet/config.yaml
```

The relevant parts of the file should end up like this:

```yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 2m0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 5m0s
    cacheUnauthorizedTTL: 30s
readOnlyPort: 0
```

Three points that decide the outcome:

- `authentication.anonymous.enabled: false` is what closes 4.2.1. The nearby `authentication.webhook.enabled` is a different key and must stay `true`.
- `authorization.mode: Webhook` is what closes 4.2.2. `AlwaysAllow` means the kubelet never asks the API server whether the caller may do what it is asking for.
- `readOnlyPort: 0` is what closes 4.2.4. Write the `0` rather than removing the line, so the intent is visible to the next person reading the file.

**4. Restart the kubelet and watch that it comes back.**

```bash
systemctl restart kubelet
systemctl is-active kubelet
journalctl -u kubelet -n 20 --no-pager
```

If the unit is not active, the file did not parse. Put the backup back and try again:

```bash
cp /root/kubelet-config.yaml.bak /var/lib/kubelet/config.yaml
systemctl restart kubelet
```

**5. Confirm the effect, not just the file.**

```bash
curl -s --max-time 3 http://127.0.0.1:10255/pods    # connection refused now
curl -sk --max-time 3 https://127.0.0.1:10250/pods  # 401 Unauthorized, so the kubelet is up
kubectl get nodes
```

**6. Re-run the audit.**

```bash
kube-bench run --targets node --check 4.2.1,4.2.2,4.2.4
```

All three lines should now start with `[PASS]`.

## Why

The kubelet is a second API surface on every node, and by default it is a weaker one than the API server. Port 10250 carries `exec`, `logs`, `run` and the full pod listing. If anonymous authentication is on, anyone who can reach that port is admitted as `system:anonymous`. If the authorization mode is `AlwaysAllow`, that anonymous caller is then permitted to do anything the kubelet can do, which includes running a command inside any container on the node. The two settings are only dangerous together, and that is why CIS lists them as separate checks.

`Webhook` mode makes the kubelet forward every request to the API server as a `SubjectAccessReview`, so node RBAC decides the outcome instead of the kubelet. That is the only mode that ties kubelet access back to cluster identity. It requires `authentication.webhook.enabled: true` as well, which is why that key must not be turned off while fixing the anonymous one.

The read-only port on 10255 is different in kind. It serves no writes, but it serves the whole pod list without any authentication at all, which hands an attacker the container images, the mounted secret names, the namespaces and the node layout. There is no way to authenticate it, so the only remediation is to close it.

The reason to check the effect rather than the file is that a kubelet reads its configuration once at start. An edited file with no restart passes a `grep` and changes nothing on the node. Checking that 10255 refuses the connection while 10250 still answers proves both halves: the port is really closed, and the kubelet is really running.

## Verify

```bash
grep -A2 anonymous /var/lib/kubelet/config.yaml
grep -A1 '^authorization' /var/lib/kubelet/config.yaml
grep '^readOnlyPort' /var/lib/kubelet/config.yaml
systemctl is-active kubelet
curl -s --max-time 3 http://127.0.0.1:10255/pods            # must fail
curl -sk --max-time 3 https://127.0.0.1:10250/healthz        # must connect
kubectl get nodes                                            # the node is Ready
kube-bench run --targets node --check 4.2.1,4.2.2,4.2.4 | grep -c '\[PASS\]'   # 3
```

## Docs

**Allowed:** `https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/` for the exact spelling and nesting of `authentication.anonymous.enabled`, `authorization.mode` and `readOnlyPort`. The kubelet page under `https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/` gives the equivalent command line flags for clusters that do not use a config file.

The CIS benchmark itself is not an allowed source, and it does not need to be. `kube-bench` prints the remediation for every finding it reports, so the tool is the reference during the exam. What has to be memorised is the command shape, `kube-bench run --targets node --check <ids>`, and the fact that the fix goes in `/var/lib/kubelet/config.yaml`.
