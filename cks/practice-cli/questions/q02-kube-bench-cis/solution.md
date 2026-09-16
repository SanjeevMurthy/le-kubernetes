# Q2. CIS Benchmark Remediation with kube-bench (solution)

## Steps

Both fixes are on the control-plane node. One restarts the API server, the other restarts the kubelet, so do them one at a time and confirm each before starting the next.

```bash
ssh <control-plane>
sudo -i
hostname
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak
cp /var/lib/kubelet/config.yaml /root/kubelet-config.yaml.bak
```

**1. See the failures for yourself.** Running the whole suite prints hundreds of lines. Ask for the two checks you were given.

```bash
kube-bench run --targets master --check 1.2.1
kube-bench run --targets node   --check 4.2.4
```

Each `[FAIL]` block carries a `Remediation:` paragraph naming the file and the setting. That paragraph is the answer, and reading it is faster than remembering which file a check lives in.

**2. CIS 1.2.1, the API server.** It is a flag in the static pod manifest.

```bash
vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Find the line under `spec.containers[0].command` and change it:

```yaml
    - --anonymous-auth=false
```

Save, and the kubelet restarts the API server within about twenty seconds. Wait for it rather than assuming:

```bash
until curl -sk https://127.0.0.1:6443/readyz | grep -q ok; do sleep 2; done
echo "apiserver is back"
```

**3. CIS 4.2.4, the kubelet.** A different file, and a YAML field rather than a flag.

```bash
vi /var/lib/kubelet/config.yaml
```

```yaml
readOnlyPort: 0
```

The kubelet does not watch this file. It has to be restarted, and unlike the API server nothing does it for you:

```bash
systemctl restart kubelet
systemctl is-active kubelet
```

**4. Prove the port is actually shut,** rather than that the file says so.

```bash
curl -s --max-time 3 http://127.0.0.1:10255/pods; echo "exit=$?"
ss -tlpn | grep 10255          # should print nothing
```

A connection refused, or a non-zero exit from curl, is the pass.

**5. Re-check the two findings.** Re-run the single checks rather than the whole suite. The suite takes long enough to be worth avoiding when the clock is running.

```bash
kube-bench run --targets master --check 1.2.1
kube-bench run --targets node   --check 4.2.4
```

Both should now read `[PASS]`.

## Which file fixes which check

The mapping is the part worth memorising, because kube-bench's own numbering does not say it out loud and the exam expects you to go straight to the right file:

| Check range | Component | File |
|---|---|---|
| 1.1.x | file permissions | the manifests and PKI files themselves |
| 1.2.x | API server | `/etc/kubernetes/manifests/kube-apiserver.yaml` |
| 1.3.x | controller manager | `/etc/kubernetes/manifests/kube-controller-manager.yaml` |
| 1.4.x | scheduler | `/etc/kubernetes/manifests/kube-scheduler.yaml` |
| 2.x | etcd | `/etc/kubernetes/manifests/etcd.yaml` |
| 4.1.x | kubelet service files | `/etc/systemd/system/kubelet.service.d/` |
| 4.2.x | kubelet configuration | `/var/lib/kubelet/config.yaml` |

The 1.x and 2.x files are static pod manifests: edit and the component restarts itself. The 4.2.x file is plain configuration: edit and restart the kubelet by hand.

## If the API server does not come back

`kubectl` is unavailable, so ask the node.

```bash
crictl ps -a | grep kube-apiserver
crictl logs "$(crictl ps -a --name kube-apiserver -q | head -1)" 2>&1 | tail -30
tail -30 /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/*.log
```

An `unknown flag` line means a typo in the flag name. Anything about YAML means the indentation moved. Restore and retry:

```bash
cp /root/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml
```

## Gotchas

- `--anonymous-auth=false` on the API server is a different setting from `authentication.anonymous.enabled: false` in the kubelet config. Check which component the finding is about.
- The kubelet needs an explicit restart. Nothing watches `/var/lib/kubelet/config.yaml`.
- Editing the manifest with `kubectl edit` does not work. Static pods are owned by the file on the node.
- Do not remediate every finding you can see. Fix the ones the question names; a cluster with `--profiling=false` everywhere and a broken API server scores worse.
- kube-bench's documentation is **not** allowed in the exam. The tool itself is the documentation: `kube-bench run --targets <master|node|etcd|controlplane>` and `--check <id>` are worth having in your fingers.
- Some clusters need `kube-bench run --targets master` and others `controlplane`, depending on version. If one returns nothing, try the other rather than assuming the checks passed.

## Docs

No allowed domain documents kube-bench or the CIS Benchmark. `kubernetes.io/docs` documents the flags themselves, which is usually what you actually need.

- https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/
- https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/ for `readOnlyPort` and the `authentication` block
- `kube-bench --help`, and the `Remediation:` text in the tool's own output
