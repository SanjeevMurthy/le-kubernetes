# CKS Exam-Day Playbook

Skim this the morning of the exam. Distilled from 12 first-hand passing debriefs. The exam is **2 h, ~16 tasks, 67% to pass** — and the thing that fails people is **time**, not knowledge. Speed + verification win.

---

## First 2 minutes — set up your shell (do this once on the base node)

```bash
# alias + completion
alias k=kubectl
source <(kubectl completion bash)
complete -F __start_kubectl k

# context / namespace
alias kcu="kubectl config use-context"
kn() { kubectl config set-context --current --namespace "$1"; }

# dry-run + force
export do="--dry-run=client -o yaml"
export now="--force --grace-period=0"

# quick gets
alias kgp="kubectl get pods"; alias kgn="kubectl get nodes"
alias kd="kubectl describe"; alias kl="kubectl logs"
```

`~/.vimrc`:
```vim
set number et ai
set sw=2 ts=2 sts=2
set pastetoggle=<F3>
```

> ⚠️ Aliases live only in the shell you set them in. Each `ssh <node>` is a fresh shell — most node tasks involve **editing existing files**, not generating YAML, so you rarely need `$do` there. Set aliases on the base node; don't waste time re-exporting on every hop.

---

## The golden rule — every single question

```bash
kubectl config use-context <CONTEXT_FROM_INFOBOX> && kubectl get nodes
```

**Run the provided context-switch command first, then verify with `get nodes`.** Wrong context silently invalidates your whole answer — this is the #1 way people lose points. A known platform bug can make the switch *appear* to work but not — the `get nodes` check catches it. Also set the namespace if the task names one.

---

## Time strategy — three passes

1. **Pass 1 (first ~50 min): quick wins.** Scan all ~16 tasks; in a scratch file mark each `fast / medium / skip`. Do all fast ones. Aim **>50% done before the 60-min mark.**
2. **Pass 2: medium.** Known-pattern tasks (manifest edits, tool runs, SSH).
3. **Pass 3: hard/unfamiliar.** Flagged tasks with whatever's left. *Expect not to finish one or two — that's fine at 67%.* A full easy answer beats 15 minutes sunk into one hard task.

**Multitask the waits:** after editing the apiserver manifest, start it restarting and **switch to another task** while it comes back (30–90 s). Don't sit and watch.

Scratch-file triage (Anson Lee, 88/100):
```
1  done  cluster upgrade
2  n     networkpolicy 3 policies / 2 ns
3  WAIT  apiserver audit (restarting)
```

---

## Safe apiserver edits (high-risk — practice until automatic)

```bash
# back up FIRST
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kube-apiserver.yaml.bak
# edit (moving it out + back in is a clean way to force a clean restart)
sudo vim /etc/kubernetes/manifests/kube-apiserver.yaml
# watch it come back
sudo crictl ps | grep kube-apiserver
# if it DOESN'T come back:
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}')
journalctl -u kubelet -f
```

**When adding audit / ImagePolicyWebhook / any file-backed flag, you must add the matching `volumes` + `volumeMounts`.** Forgetting the mount is the most common way to take down the API server in the exam.

---

## Per-domain gotchas (memorize)

- **NetworkPolicy deny-all:** add port-53 **UDP and TCP** egress or DNS breaks cluster-wide (and cascades into other tasks).
- **Audit policy:** **first match wins** → put specific rules *before* catch-all. Policy mount `readOnly: true`; log dir writable. 4 levels: None / Metadata / Request / RequestResponse.
- **Secrets encryption:** the provider only encrypts *new* writes → re-encrypt: `kubectl get secrets -A -o json | kubectl replace -f -`. Verify in etcd (`k8s:enc:aescbc:`).
- **Falco:** custom rules in `/etc/falco/falco_rules.local.yaml`; reload without full restart: `kill -1 $(cat /var/run/falco.pid)`; logs: `journalctl -fu falco`.
- **AppArmor:** load on the node (`apparmor_parser -q`) *before* referencing it in the pod; check `aa-status`. 1.30+ uses `securityContext.appArmorProfile`; older uses the annotation.
- **seccomp:** profiles at `/var/lib/kubelet/seccomp/profiles/`; `Localhost` type points at a path relative to that dir.
- **Capabilities:** `drop: ["ALL"]` then `add` — not the reverse.
- **Docker daemon.json:** creating the file does nothing unless dockerd is configured to read it — check `ps aux | grep dockerd`.
- **securityContext placement:** pod-level = `runAsUser/runAsGroup/fsGroup/seccompProfile`; container-level = `allowPrivilegeEscalation/readOnlyRootFilesystem/capabilities`.

---

## Verify every task (60 seconds — non-negotiable)

People fail on tasks they *thought* were done. Quick checks:
```bash
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa>
aa-status                                   # AppArmor loaded?
sudo crictl inspect <id> | grep -i seccomp  # profile applied?
kubectl get pod <p> -o wide                 # Running? right node?
kubectl run test --image=busybox ... # NetworkPolicy allow/deny behaves?
```

---

## PSI environment do's & don'ts

- **Never reboot the base node** — it breaks the exam session.
- **`Ctrl+W` closes the browser tab** → use **`Ctrl+Alt+W`**. Terminal paste: `Ctrl+Shift+V`. `INSERT` key blocked → use `i` in vim.
- All work is over `ssh <nodename>` from the base node; **no nested SSH**; `sudo -i` for root; `exit` back to base before the next task.
- Pre-installed: `kubectl` (+`k` alias, completion), `yq`, `curl`, `wget`, `man`.
- Single monitor, webcam, clear desk, bare walls, ID ready. Do the PSI system check the day before (Day 43).

---

## Top 15 lessons (ranked by impact)

1. **Context-switch + `get nodes` verify on every question.** #1 silent point-loss.
2. **Set aliases + `.vimrc` in the first 2 minutes.**
3. **Don't skip Falco** — near-guaranteed; know rules file, output edit, reload.
4. **After apiserver edits, move on while it restarts;** know how to diagnose a failed restart.
5. **Flag + volumeMounts together** when adding file-backed apiserver flags.
6. **killer.sh ≥60% within time ≈ ready.** It's harder than the real exam by design.
7. **Trivy + audit policy are near-guaranteed** — drill each to <3 min.
8. **Deny-all NetworkPolicy ⇒ always add port-53 egress.**
9. **Three-pass triage:** easy first, flag the hard, partial-credit the rest.
10. **Audit rule order is first-match** — specific before catch-all.
11. **Memorize the file paths** (apiserver manifest, kubelet config, seccomp dir, AppArmor dir, Falco local rules, audit dir, etcd pki).
12. **Verify every task (60 s).**
13. **Navigate docs in <60 s** — bookmark the allowed domains; `Ctrl+F` to the snippet.
14. **Linux fundamentals are tested too** — `systemctl`, `journalctl`, `usermod`, `gpasswd`, `modprobe`, `ss`, `ufw`.
15. **Don't stop studying mid-prep** — procedural memory (paths/flags) fades fast; keep momentum to exam day.

---

## High-value command cheats

```bash
# RBAC check
kubectl auth can-i create pods --as=system:serviceaccount:dev:app -n dev

# AppArmor
cat /sys/module/apparmor/parameters/enabled   # expect Y
apparmor_parser -q /etc/apparmor.d/<profile>; aa-status

# Falco
journalctl -fu falco; kill -1 $(cat /var/run/falco.pid)

# Trivy
trivy image --severity HIGH,CRITICAL <image>
trivy image --severity CRITICAL --format json <image> > scan.json
trivy config <manifest.yaml>

# kubesec / kube-bench
kubesec scan pod.yaml
kube-bench run --targets master,node | grep -C5 FAIL

# etcd: is a secret encrypted?
ETCDCTL_API=3 etcdctl get /registry/secrets/default/mysecret \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key | hexdump -C | head

# audit list of all images in cluster
kubectl get pods -A -o=custom-columns='NS:.metadata.namespace,NAME:.metadata.name,IMG:.spec.containers[*].image'

# pods missing seccomp
kubectl get pods -A -o json | jq '.items[] | select(.spec.securityContext.seccompProfile==null) | .metadata.name'

# node hardening
systemctl disable --now <svc>; apt-get remove -y <pkg>; ss -tlnp
usermod -s /bin/nologin <user>; gpasswd -d <user> <group>
echo "blacklist <mod>" > /etc/modprobe.d/<mod>.conf; lsmod | grep <mod>

# debug a broken apiserver
sudo crictl ps -a | grep api; sudo crictl logs <id>; journalctl -u kubelet -f
```
