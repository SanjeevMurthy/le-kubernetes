# CKS Study Notes: System Hardening (10%)

> Exam environment: Kubernetes **v1.35**. The published curriculum PDF is versioned v1.34, the cluster you get is newer.
> This domain is the one where the work happens on the node, not in the API. Almost every task starts with `ssh <node>` followed by `sudo -i`.

Most of the recipes below have no allowed documentation at all. AppArmor, Trivy, kube-bench and kubesec documentation are outside the allowed set, so the AppArmor commands and the Linux hardening commands have to come out of memory, with `man` on the task host and `/usr/share/doc` as the only in-exam reference. The allowed sources are kubernetes.io/docs, kubernetes.io/blog, falco.org/docs, kubernetes-sigs.github.io/bom, etcd.io/docs, the ingress-nginx user guide, docs.cilium.io and istio.io/latest/docs. Nothing else, and no bookmarks.

<!-- toc -->
## Table of Contents

- [What the exam asks](#what-the-exam-asks)
- [Recipe 1: Reduce the host OS footprint](#recipe-1-reduce-the-host-os-footprint)
- [Recipe 2: Least-privilege users, sudo and SSH](#recipe-2-least-privilege-users-sudo-and-ssh)
- [Recipe 3: Minimise external access with the host firewall](#recipe-3-minimise-external-access-with-the-host-firewall)
- [Recipe 4: Block kernel modules](#recipe-4-block-kernel-modules)
- [Recipe 5: AppArmor, load the profile on the node and enforce it on a pod](#recipe-5-apparmor-load-the-profile-on-the-node-and-enforce-it-on-a-pod)
- [Recipe 6: seccomp profile on the node, referenced by a pod](#recipe-6-seccomp-profile-on-the-node-referenced-by-a-pod)
- [Recipe 7: Capabilities, securityContext placement, and strace](#recipe-7-capabilities-securitycontext-placement-and-strace)
- [Quick reference](#quick-reference)
- [Memorise](#memorise)

<!-- toc stop -->

## What the exam asks

| Task type | Sources | Drill |
|---|---|---|
| AppArmor: load a profile on the node, enforce it on a pod | 12 | Q7, Q34 |
| Manual static analysis and securityContext fixes on a manifest | 8 | Q15 |
| Container immutability: read-only root filesystem, no privileged | 6 | Q15 |
| strace and syscall investigation of a running container | 5 | Q43 |
| seccomp: profile on the node, referenced by the pod | 5 | Q8, Q30 |
| Linux host hardening: users, groups, services, ports, packages, SSH | 4 | Q41, Q42 |

Counts are distinct candidate sources reporting that task type in the exam research table, not a share of the exam. AppArmor at 12 sources sits in the top tier with Falco, audit logging, ImagePolicyWebhook, kube-bench, NetworkPolicy, RBAC and gVisor, so plan on seeing it.

## Recipe 1: Reduce the host OS footprint

**Goal.** A named service on a worker node is stopped, disabled so it does not return after a reboot, and its listening port is gone.
**Frequency.** 4 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q41.
**Commands.**
```bash
ssh cks-node1
sudo -i

# what is running and what is listening
systemctl list-units --type=service --state=running
ss -tlpn
lsof -i :8888

# identify the unit behind the port, then read what it is
ss -tlpn | grep ':8888'
systemctl status rogue-app.service

# stop it now and keep it stopped across reboots
systemctl disable --now rogue-app.service
systemctl mask rogue-app.service          # only if it keeps coming back

# package removal, when the task says remove and not just stop
apt list --installed | grep -i nginx
apt-get remove --purge -y nginx
```
**Verify.**
```bash
systemctl is-active rogue-app.service     # inactive
systemctl is-enabled rogue-app.service    # disabled or masked
ss -tlpn | grep ':8888' || echo "port closed"
```
**Gotchas.**
- `systemctl stop` on its own leaves the unit enabled, and the grader reboots or checks `is-enabled`. Use `disable --now`.
- Socket activated services restart on the next connection. Disable the matching `.socket` unit as well, and `mask` the unit when it still returns.
- `ss -tlpn` prints the owning process only for root. Run `sudo -i` before anything else on the node.
- Read the verb in the task. Stop, disable, remove and purge are four different end states, and purging config files when the task only said stop can cost the point.
- The task names the node. The `base` host is never the target, and nested ssh from one node to another is not available.

**Docs.** None allowed: memorise. On the node, `man systemctl`, `man ss`, `man lsof`.

## Recipe 2: Least-privilege users, sudo and SSH

**Goal.** A named OS user can no longer log in interactively, has lost its privileged group membership and its passwordless sudo rule, and root SSH plus password SSH are off.
**Frequency.** 4 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q42.
**Commands.**
```bash
ssh cks-node1
sudo -i

# who can log in, and with what group rights
grep -E '/bin/(ba)?sh$' /etc/passwd
id devuser

# take away the interactive shell and lock the password
usermod -s /usr/sbin/nologin devuser
usermod -L devuser

# drop privileged group membership
gpasswd -d devuser sudo
gpasswd -d devuser docker
chgrp appgrp /opt/app/config

# sudo rules live in two places
grep -RnE 'NOPASSWD|ALL=\(ALL' /etc/sudoers /etc/sudoers.d/
export EDITOR=vim
visudo                                # main file
visudo -f /etc/sudoers.d/devuser      # drop-in file
visudo -c                             # syntax check both

# sshd hardening
vim /etc/ssh/sshd_config              # PermitRootLogin no
                                      # PasswordAuthentication no
sshd -t && systemctl restart sshd
```
**Verify.**
```bash
getent passwd devuser | cut -d: -f7        # /usr/sbin/nologin
passwd -S devuser                          # L in the second field means locked
sudo -l -U devuser
grep -E '^(PermitRootLogin|PasswordAuthentication)' /etc/ssh/sshd_config
```
**Gotchas.**
- The task nearly always says disable the login, not delete the account. Reach for `usermod`, not `userdel`.
- Sudo rights are split across `/etc/sudoers` and every file under `/etc/sudoers.d/` pulled in by the `#includedir` line. Removing the user from the `sudo` group does nothing if a drop-in file still names the user.
- `usermod -L` locks the password but leaves SSH key authentication working. Set the nologin shell too when the task says the user must not log in at all.
- Always run `sshd -t` before restarting sshd. A bad directive plus a restart makes the task host unreachable and there is no console.
- `visudo` opens whatever `$EDITOR` points at. Export it before you start rather than fighting nano under time pressure.
- Verify with `sudo -l -U <user>`, which reads the effective rules, instead of reading files back.

**Docs.** None allowed: memorise. On the node, `man 5 sudoers`, `man usermod`, `man sshd_config`.

## Recipe 3: Minimise external access with the host firewall

**Goal.** Only the ports the task lists are reachable on the node, and the control plane ports stay reachable from the cluster network.
**Frequency.** 4 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q41.
**Commands.**
```bash
ssh cks-node1
sudo -i

ufw status verbose

# allow SSH before anything else, or the session dies on enable
ufw allow 22/tcp
ufw allow from 10.0.0.0/8 to any port 6443 proto tcp
ufw deny 8888/tcp
ufw enable

ufw status numbered
ufw insert 1 deny from 192.168.1.0/24 to any port 10250 proto tcp
ufw delete 3

# when ufw is not installed
iptables -L INPUT -n --line-numbers
iptables -A INPUT -p tcp --dport 8888 -j DROP
```
**Verify.**
```bash
ufw status numbered
ss -tlpn | grep ':6443'
curl -m 3 -k https://127.0.0.1:6443/readyz          # still ok on the control plane
```
**Gotchas.**
- `ufw enable` applies a default deny on incoming traffic. Allow 22/tcp first or the SSH session drops and the task is unrecoverable.
- Rules are evaluated in order. A broad allow placed earlier beats a deny added later. Read `ufw status numbered` and use `ufw insert 1 ...` to put a deny in front.
- Host firewall rules are not a substitute for NetworkPolicy. Pod to pod traffic is handled by the CNI and does not traverse these rules.
- On a control plane node keep 6443 (apiserver), 2379 and 2380 (etcd), 10250 (kubelet) and 10259/10257 open to the cluster, otherwise the node goes NotReady.

**Docs.** None allowed: memorise. On the node, `man ufw`, `man iptables`.

## Recipe 4: Block kernel modules

**Goal.** A named kernel module is not loaded now and cannot be loaded again, including by an explicit `modprobe`.
**Frequency.** No source reports this as a standalone task. It rides inside the host hardening family, 4 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md), and the curriculum bullet "minimize host OS footprint" covers it. Drill: Q42.
**Commands.**
```bash
ssh cks-node1
sudo -i

lsmod
lsmod | grep -E 'sctp|dccp'
modinfo sctp

cat > /etc/modprobe.d/blacklist-cks.conf <<'EOF'
blacklist sctp
install sctp /bin/true
blacklist dccp
install dccp /bin/true
EOF

# blacklisting does not unload anything, do that explicitly
modprobe -r sctp
modprobe -r dccp
```
**Verify.**
```bash
lsmod | grep -c sctp                 # 0
modprobe --showconfig | grep sctp    # shows the blacklist and install lines
modprobe -n -v sctp                  # dry run resolves to /bin/true
modprobe sctp && lsmod | grep sctp   # still nothing loaded
```
**Gotchas.**
- `blacklist` only stops the module being autoloaded by alias. A direct `modprobe sctp` still loads it. The `install <module> /bin/true` line is what blocks the explicit load, so write both.
- Neither line unloads a module that is already in memory. `modprobe -r` gives the immediate effect the grader looks for, and the exam does not want a reboot.
- The file has to live under `/etc/modprobe.d/` and end in `.conf`, otherwise modprobe ignores it.
- `modprobe -r` fails with "in use" when something holds the module. The third column of `lsmod` names the users.

**Docs.** None allowed: memorise. On the node, `man modprobe`, `man modprobe.d`.

## Recipe 5: AppArmor, load the profile on the node and enforce it on a pod

**Goal.** A profile file that is present on a worker node is loaded in enforce mode, and a pod scheduled to that node runs confined by it.
**Frequency.** 12 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q7, Q34.
**Commands.**
```bash
ssh cks-node1
sudo -i

# 1. READ THE PROFILE NAME OUT OF THE FILE. It is not the file name.
apparmor_parser -N /etc/apparmor.d/nginx_apparmor    # prints the profile names
head -3 /etc/apparmor.d/nginx_apparmor               # e.g. profile very-secure flags=(attach_disconnected) {

# 2. load it, or reload it after an edit
apparmor_parser -q /etc/apparmor.d/nginx_apparmor    # load, quiet
apparmor_parser -r /etc/apparmor.d/nginx_apparmor    # replace an already loaded profile

# 3. confirm the name and the mode
aa-status
aa-status | grep very-secure
aa-enforce /etc/apparmor.d/nginx_apparmor            # enforce mode
aa-complain /etc/apparmor.d/nginx_apparmor           # log only, debugging
```

Pod side, Kubernetes 1.30 and later, the field form:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: apparmor-pod
  namespace: default
spec:
  nodeName: cks-node1
  containers:
  - name: c1
    image: nginx:1.27.1
    securityContext:
      appArmorProfile:
        type: Localhost
        localhostProfile: very-secure
EOF
```

The legacy annotation still works and still appears in seeded manifests:

```bash
cat <<'EOF'
metadata:
  annotations:
    container.apparmor.security.beta.kubernetes.io/c1: localhost/very-secure
EOF
```

A running pod cannot have its securityContext edited, so replace it:

```bash
kubectl get pod apparmor-pod -o yaml > /tmp/pod.yaml
vim /tmp/pod.yaml
kubectl replace --force -f /tmp/pod.yaml
```
**Verify.**
```bash
kubectl get pod apparmor-pod -o jsonpath='{.spec.containers[0].securityContext.appArmorProfile}{"\n"}'
kubectl exec apparmor-pod -- touch /tmp/x          # expect Permission denied
kubectl describe pod apparmor-pod | tail -20       # AppArmor errors land in the events
ssh cks-node1 "sudo aa-status | grep -c very-secure"
ssh cks-node1 "sudo dmesg | grep -i apparmor | tail -5"
```
**Gotchas.**
- **The profile name declared inside the file is what the pod references, and it is usually different from the file name.** `/etc/apparmor.d/nginx_apparmor` commonly declares `profile very-secure { ... }`, so the pod needs `localhostProfile: very-secure`. This is the single most reported trap on this task. Run `apparmor_parser -N <file>` or read the first line before writing any YAML.
- `aa-status` is the source of truth for the loaded name. If the name you typed is not in that list, the pod will not start.
- The profile is loaded per node. A pod scheduled to a node without it fails, so pin the pod with `nodeName`, or load the profile on every worker the pod could land on.
- The annotation value carries the `localhost/` prefix. The `localhostProfile` field must not have it.
- `type` has three values: `Localhost` with `localhostProfile`, `RuntimeDefault` and `Unconfined`. Only `Localhost` takes a name, and the field is per container under `spec.containers[].securityContext`.
- A pod that fails the AppArmor check shows `Blocked` or `CreateContainerError`, and the reason is in `kubectl describe`, not in the container logs.
- After editing the profile file, `apparmor_parser -r` is needed. Loading with `-q` a second time errors on an existing profile.

**Docs.** None allowed: memorise. AppArmor project documentation is not on the allowed list. On the node, `man apparmor_parser`, `man aa-status`, `man apparmor.d`, and `/usr/share/doc/apparmor/`.

## Recipe 6: seccomp profile on the node, referenced by a pod

**Goal.** A JSON seccomp profile exists under `/var/lib/kubelet/seccomp/profiles/` on the node and a pod runs with it, either logging syscalls or denying a named one.
**Frequency.** 5 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q8, Q30.
**Commands.**
```bash
ssh cks-node1
sudo -i
mkdir -p /var/lib/kubelet/seccomp/profiles

# audit everything, block nothing
cat > /var/lib/kubelet/seccomp/profiles/audit.json <<'EOF'
{
  "defaultAction": "SCMP_ACT_LOG"
}
EOF

# allow everything except a named syscall
cat > /var/lib/kubelet/seccomp/profiles/deny-mkdir.json <<'EOF'
{
  "defaultAction": "SCMP_ACT_ALLOW",
  "syscalls": [
    {
      "names": ["mkdir", "mkdirat"],
      "action": "SCMP_ACT_ERRNO"
    }
  ]
}
EOF
```

Pod side. The path is relative to `/var/lib/kubelet/seccomp/`:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-pod
spec:
  nodeName: cks-node1
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/deny-mkdir.json
  containers:
  - name: c1
    image: busybox:1.36
    command: ["sleep", "3600"]
EOF
```

When the task just says apply a secure seccomp profile, the answer is the runtime default:

```bash
cat <<'EOF'
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
EOF
```
**Verify.**
```bash
kubectl exec seccomp-pod -- mkdir /tmp/blocked      # expect Operation not permitted
kubectl get pod seccomp-pod -o jsonpath='{.spec.securityContext.seccompProfile}{"\n"}'

# on the node
CID=$(crictl ps --name c1 -q)
PID=$(crictl inspect --output go-template --template '{{.info.pid}}' "$CID")
grep Seccomp /proc/$PID/status                      # Seccomp: 2 means filter mode
```
**Gotchas.**
- `localhostProfile` is relative to `/var/lib/kubelet/seccomp/`, so write `profiles/deny-mkdir.json`. An absolute path or a leading slash makes the kubelet refuse to create the container.
- The file must exist on the node the pod actually lands on. A missing file gives `CreateContainerError` with a "cannot load seccomp profile" message in `kubectl describe`.
- A container-level `seccompProfile` overrides the pod-level one. Check both places when a profile appears not to apply.
- `SCMP_ACT_ERRNO` returns an error to the process, `SCMP_ACT_LOG` only writes an audit record on the node. Audit style tasks want `SCMP_ACT_LOG`, deny style tasks want `SCMP_ACT_ERRNO`.
- Name both `mkdir` and `mkdirat`. Modern libc calls the `at` variant, so blocking only `mkdir` looks like it did nothing.
- `Unconfined` is the effective default when no profile is set, unless the kubelet runs with `--seccomp-default`.
- `crictl` needs root. Run `sudo -i` before it, and use the go-template output because there is no `jq` on the exam hosts.

**Docs.** kubernetes.io: "Restrict a Container's Syscalls with seccomp", "Configure a Security Context for a Pod or Container".

## Recipe 7: Capabilities, securityContext placement, and strace

**Goal.** A workload runs with dropped capabilities, a read-only root filesystem and no privilege escalation, and you can name the syscalls a suspicious container is making.
**Frequency.** strace investigation is reported by 5 candidate sources, manual static analysis of a manifest by 8, container immutability by 6 (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q15, Q43.
**Commands.**
```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: hardened
spec:
  securityContext:                 # pod level
    runAsNonRoot: true
    runAsUser: 10001
    fsGroup: 20001
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: c1
    image: nginx:1.27.1
    securityContext:               # container level
      privileged: false
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
        add: ["NET_BIND_SERVICE"]
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
EOF
```

Where each field is allowed to live:

| Field | Pod level `spec.securityContext` | Container level `spec.containers[].securityContext` |
|---|---|---|
| `runAsUser`, `runAsGroup` | yes, default for all containers | yes, overrides the pod value |
| `runAsNonRoot` | yes | yes, overrides |
| `fsGroup` | yes only | no |
| `seccompProfile` | yes | yes, overrides |
| `appArmorProfile` | no | yes only |
| `capabilities` | no | yes only |
| `privileged` | no | yes only |
| `allowPrivilegeEscalation` | no | yes only |
| `readOnlyRootFilesystem` | no | yes only |

Syscall investigation on the node:

```bash
ssh cks-node1
sudo -i

crictl ps --name suspicious
CID=$(crictl ps --name suspicious -q)
PID=$(crictl inspect --output go-template --template '{{.info.pid}}' "$CID")

strace -p "$PID" -f -c                       # summary of every syscall used
strace -p "$PID" -f -e trace=kill 2>&1 | head -20
ls -l /proc/$PID/root/etc/passwd             # read the container filesystem from the node
```
**Verify.**
```bash
kubectl get pod hardened -o jsonpath='{.spec.containers[0].securityContext.capabilities.drop[*]}{"\n"}'
kubectl exec hardened -- grep CapEff /proc/1/status
kubectl exec hardened -- touch /x            # expect Read-only file system
kubectl exec hardened -- id                  # uid=10001

# decode the capability mask on the node, capsh is often missing in the image
capsh --decode=0000000000000400
```
**Gotchas.**
- `capabilities`, `privileged`, `allowPrivilegeEscalation` and `readOnlyRootFilesystem` are container level only. Put any of them at pod level and the API server rejects the manifest, it does not silently ignore them.
- `fsGroup` is the mirror image: pod level only.
- `drop: ["ALL"]` then add back exactly what the task names. Adding anything extra is a lost point on a least-privilege question.
- `runAsNonRoot: true` on an image whose `USER` is root fails at container start with `CreateContainerConfigError`. The reason is in `kubectl describe pod`, not in the logs.
- `readOnlyRootFilesystem: true` breaks nginx until the paths it writes have `emptyDir` mounts, typically `/tmp`, `/var/cache/nginx` and `/var/run`.
- On a static analysis task, change only the fields the task lists. Do not tidy up the rest of the manifest.
- `strace` needs root on the node and the host PID from `crictl inspect`. The pod IP or node name from `kubectl get pod -o wide` will not get you there.
- `-f` follows threads, `-c` prints the summary table. "Which syscalls does this container use" is answered by `-c`, not by a raw trace.

**Docs.** kubernetes.io: "Configure a Security Context for a Pod or Container", "Set capabilities for a Container", "Pod Security Standards". For `strace` and `capsh`, none allowed: memorise, `man strace` on the node.

## Quick reference

```bash
# host footprint
systemctl list-units --type=service --state=running
systemctl disable --now <unit>
ss -tlpn ; lsof -i :<port>
apt-get remove --purge -y <pkg>

# users, sudo, ssh
usermod -s /usr/sbin/nologin <user> ; usermod -L <user>
gpasswd -d <user> sudo
grep -RnE 'NOPASSWD' /etc/sudoers /etc/sudoers.d/
sshd -t && systemctl restart sshd

# firewall
ufw allow 22/tcp ; ufw allow from 10.0.0.0/8 to any port 6443 proto tcp
ufw enable ; ufw status numbered ; ufw delete <n>

# kernel modules
echo -e "blacklist sctp\ninstall sctp /bin/true" >> /etc/modprobe.d/blacklist-cks.conf
modprobe -r sctp ; modprobe --showconfig | grep sctp

# apparmor
apparmor_parser -N /etc/apparmor.d/<file>     # the NAME, not the file
apparmor_parser -q /etc/apparmor.d/<file>     # load
apparmor_parser -r /etc/apparmor.d/<file>     # reload after an edit
aa-status | grep <name> ; aa-enforce /etc/apparmor.d/<file>

# seccomp
ls /var/lib/kubelet/seccomp/profiles/
CID=$(crictl ps --name <c> -q)
PID=$(crictl inspect --output go-template --template '{{.info.pid}}' "$CID")
grep Seccomp /proc/$PID/status                # 2 means a filter is active

# capabilities and syscalls
kubectl exec <pod> -- grep CapEff /proc/1/status
capsh --decode=<mask>
strace -p "$PID" -f -c
strace -p "$PID" -f -e trace=kill
```

## Memorise

- AppArmor: the profile **name** declared inside the file is what `localhostProfile` references, and it is usually not the file name. `apparmor_parser -N <file>` prints it, `aa-status` confirms it is loaded.
- AppArmor pod field since 1.30: `securityContext.appArmorProfile` with `type: Localhost` and `localhostProfile: <profile-name>`, per container. The legacy annotation `container.apparmor.security.beta.kubernetes.io/<container>: localhost/<profile-name>` still works and needs the `localhost/` prefix.
- AppArmor profiles are per node. Pin the pod with `nodeName` to the node where the profile is loaded.
- seccomp profiles live in `/var/lib/kubelet/seccomp/profiles/`, and the pod writes `localhostProfile: profiles/<file>.json`, relative to `/var/lib/kubelet/seccomp/`.
- seccomp actions: `SCMP_ACT_LOG` audits, `SCMP_ACT_ERRNO` denies, `SCMP_ACT_ALLOW` permits. `RuntimeDefault` is the answer when no custom profile is named.
- Container level only: `capabilities`, `privileged`, `allowPrivilegeEscalation`, `readOnlyRootFilesystem`, `appArmorProfile`. Pod level only: `fsGroup`.
- Container PID for `strace`, with no `jq` available:
  `crictl inspect --output go-template --template '{{.info.pid}}' "$CID"`.
- `blacklist <mod>` stops autoload, `install <mod> /bin/true` stops the explicit `modprobe`, `modprobe -r <mod>` unloads it now. Write all three.
- `ufw allow 22/tcp` before `ufw enable`, every time.
- `systemctl disable --now` rather than `stop`, and `mask` when a unit keeps returning.
- Editing securityContext on a running pod is rejected. Use `kubectl replace --force -f pod.yaml`.
- Every host task starts with `ssh <node>` then `sudo -i`. Skipping `sudo -i` is what makes `crictl`, `strace` and `ss -tlpn` look broken.
