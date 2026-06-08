# CKS Study Notes — System Hardening (10%)

> Part of the CKS study-notes set; order follows the official CKS curriculum (v1.34, Kubernetes 1.34).
> Goal: understand each topic well enough to do the task fast under exam time pressure — not exhaustively.

**What the examiner tests here:** Given a node or cluster, reduce the attack surface by removing unused services/packages, restricting kernel modules, applying AppArmor/seccomp profiles to pods, and locking down Linux capabilities in pod specs.

---

## Reduce Host OS Footprint

**Why it matters:** Every running service or open port is a potential entry point. Examiners will ask you to stop/remove services and close ports to minimize the attack surface of a node.

**Concepts**
- Disable services that shouldn't be running (e.g., snapd, avahi-daemon, cups)
- Remove unnecessary packages entirely with apt
- Verify only expected ports are listening with `ss` or `lsof`
- Closed ports reduce lateral movement opportunity if a pod is compromised

**Commands & examples**
```bash
# List all active services
systemctl list-units --type=service --state=active

# Disable and stop a service immediately
systemctl disable --now snapd.service
systemctl disable --now avahi-daemon.service

# Remove an unneeded package
apt remove --purge -y snapd
apt autoremove -y

# Check listening ports
ss -tlnp          # TCP listeners with process names
lsof -i -n -P     # All open network files (ports)

# Check which process owns a specific port
ss -tlnp | grep :8080
lsof -i :8080
```

**Exam tips:** The exam often has you SSH into a node. Run `ss -tlnp` first to see what's open, then trace each port back to a service. Use `systemctl disable --now` (not just `stop`) so the service won't restart after a reboot.

---

## Restrict Kernel Modules

**Why it matters:** Kernel modules can expose dangerous capabilities (e.g., `sctp` enables certain network attacks). Blacklisting prevents them from loading even if a container tries to trigger them.

**Concepts**
- `lsmod` — list currently loaded modules
- `modprobe <module>` — load a module manually
- `modprobe -r <module>` — unload a module (if no users)
- Blacklist file in `/etc/modprobe.d/` persists across reboots
- `install <module> /bin/true` — alternative: silently succeed without actually loading

**Commands & examples**
```bash
# List loaded modules
lsmod

# Check if a specific module is loaded
lsmod | grep sctp

# Blacklist a module (create a .conf file in /etc/modprobe.d/)
echo "blacklist sctp" >> /etc/modprobe.d/blacklist-cks.conf
echo "blacklist dccp" >> /etc/modprobe.d/blacklist-cks.conf

# Use 'install /bin/true' to silently block loading via modprobe
echo "install sctp /bin/true" >> /etc/modprobe.d/blacklist-cks.conf

# Force unload a currently loaded module
modprobe -r sctp

# Verify it's gone
lsmod | grep sctp
```

**Exam tips:** Blacklisting alone does NOT unload an already-loaded module — you need `modprobe -r` for immediate effect. The `install /bin/true` trick is more robust than `blacklist` because it intercepts modprobe attempts.

---

## Least-Privilege Identity & SSH

**Why it matters:** Service accounts and OS users with unnecessary login shells or sudo access are prime escalation vectors. Hardening identity at the OS level reduces the blast radius of a compromised process.

**Concepts**
- Shell `/bin/nologin` or `/bin/false` prevents interactive login for a user
- Remove users from privileged groups (e.g., `sudo`, `docker`)
- Restrict sudo via `/etc/sudoers` (use `visudo` to edit safely)
- UFW (Uncomplicated Firewall) allows simple allow/deny rules by port

**Commands & examples**
```bash
# Prevent a user from logging in interactively
usermod -s /bin/nologin username

# Remove a user from a group
gpasswd -d username sudo
gpasswd -d username docker

# Check which groups a user belongs to
groups username
id username

# View sudoers file (always use visudo, not direct edit)
visudo                          # opens with validation
cat /etc/sudoers                # read-only review
ls /etc/sudoers.d/              # drop-in files

# UFW basics
ufw status
ufw allow 6443/tcp              # allow kube-apiserver
ufw deny 2379/tcp               # block etcd from external
ufw enable
ufw delete allow 8080/tcp       # remove a rule
```

**Exam tips:** Use `usermod -s /bin/nologin` not `userdel` — the question usually says "disable login", not "delete the user". Always check `/etc/sudoers.d/` — sudoers rules can be split across multiple files.

---

## AppArmor

**Why it matters:** AppArmor is a Linux MAC (Mandatory Access Control) system that confines a process to only the filesystem paths, network operations, and capabilities defined in its profile. The exam tests both loading profiles on nodes and applying them to pods.

**Concepts**
- Profiles are loaded per node — **the profile MUST be loaded on the node before a pod references it**
- `enforce` mode: violations are blocked and logged
- `complain` mode: violations are only logged, not blocked
- Profile stored in `/etc/apparmor.d/` (convention, not required)
- Kubernetes 1.30+ uses `securityContext.appArmorProfile` (GA field)
- Legacy (pre-1.30) uses the pod annotation `container.apparmor.security.beta.kubernetes.io/<container-name>`

**Commands & examples**
```bash
# Load a profile onto the node (run on the node, not in the pod)
apparmor_parser -q /etc/apparmor.d/my-profile     # quiet load
apparmor_parser -r /etc/apparmor.d/my-profile     # reload (replace)

# Check loaded profiles and their modes
aa-status
aa-status | grep my-profile

# Verify a profile is in enforce mode
aa-status | grep -A1 "enforce"

# --- Kubernetes 1.30+ (GA, securityContext) ---
# Apply to a container in a pod spec:
cat <<EOF
spec:
  containers:
  - name: myapp
    securityContext:
      appArmorProfile:
        type: Localhost
        localhostProfile: my-profile   # name as shown in aa-status
EOF

# type: RuntimeDefault  — use the container runtime's default profile
# type: Unconfined      — disable AppArmor for this container

# --- Legacy annotation (pre-1.30 clusters) ---
# Annotation key: container.apparmor.security.beta.kubernetes.io/<container-name>
cat <<EOF
metadata:
  annotations:
    container.apparmor.security.beta.kubernetes.io/myapp: localhost/my-profile
EOF

# Switch a loaded profile to complain mode (for debugging)
aa-complain /etc/apparmor.d/my-profile

# Switch back to enforce
aa-enforce /etc/apparmor.d/my-profile
```

**Exam tips:**
- Profile must be loaded on EVERY node that could schedule the pod — if the pod lands on a node without the profile, it will fail to start with an AppArmor error.
- In 1.30+, `securityContext.appArmorProfile.type: Localhost` requires `localhostProfile` to match the profile name exactly as shown by `aa-status` (not the file path).
- If the exam cluster is on 1.29 or earlier, use the annotation form — check `kubectl version` first.
- Don't confuse `apparmor_parser -q` (load) with `apparmor_parser -r` (reload/replace existing).

---

## seccomp

**Why it matters:** seccomp (secure computing mode) restricts which Linux syscalls a container can make. RuntimeDefault is a safe baseline; custom profiles let you lock down further or allow specific syscalls for privileged workloads.

**Concepts**
- `RuntimeDefault` — uses the container runtime's built-in seccomp profile (blocks ~40% of syscalls)
- `Localhost` — reference a JSON profile you placed on the node
- `Unconfined` — no seccomp filtering (default if not set)
- Custom profiles live at `/var/lib/kubelet/seccomp/profiles/` on the node
- Profile JSON has a `defaultAction` and a list of `syscalls` with actions (SCMP_ACT_ALLOW, SCMP_ACT_ERRNO)

**Commands & examples**
```bash
# Apply RuntimeDefault to a pod (applies to all containers)
cat <<EOF
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
EOF

# Apply a custom (Localhost) profile to a specific container
cat <<EOF
spec:
  containers:
  - name: myapp
    securityContext:
      seccompProfile:
        type: Localhost
        localhostProfile: profiles/audit.json   # relative to /var/lib/kubelet/seccomp/
EOF

# The full path on the node would be:
# /var/lib/kubelet/seccomp/profiles/audit.json

# Minimal custom profile that audits all syscalls
cat <<'EOF' > /var/lib/kubelet/seccomp/profiles/audit.json
{
  "defaultAction": "SCMP_ACT_LOG",
  "syscalls": []
}
EOF

# Verify seccomp profile applied to a running container
crictl inspect <container-id> | grep -i seccomp

# Get container ID from pod
crictl ps | grep <pod-name>
```

**Exam tips:**
- The `localhostProfile` path is relative to `/var/lib/kubelet/seccomp/` — do NOT include the base path in the field value.
- `seccompProfile` can be set at pod-level (`spec.securityContext`) or container-level (`spec.containers[*].securityContext`) — container-level overrides pod-level.
- RuntimeDefault is almost always the right answer when the exam says "apply a secure seccomp profile" without specifying a custom one.

---

## Linux Capabilities

**Why it matters:** Containers inherit a default set of Linux capabilities (e.g., `CHOWN`, `NET_BIND_SERVICE`). Dropping all and adding back only what's needed is a key principle of least privilege — and a direct exam question.

**Concepts**
- Default container capabilities include: `CHOWN`, `DAC_OVERRIDE`, `FOWNER`, `SETUID`, `SETGID`, `NET_BIND_SERVICE`, `KILL`, `NET_RAW` (varies by runtime)
- `drop: ["ALL"]` removes everything — then `add` only specific ones
- Dangerous capabilities: `NET_ADMIN` (routing, iptables), `SYS_ADMIN` (almost root), `NET_RAW` (raw sockets, ARP spoofing)
- Capabilities are container-level only (not pod-level)

**Commands & examples**
```bash
# Drop all capabilities and add nothing (most restrictive)
cat <<EOF
spec:
  containers:
  - name: myapp
    securityContext:
      capabilities:
        drop: ["ALL"]
EOF

# Drop all, then add back only what the app needs
cat <<EOF
spec:
  containers:
  - name: myapp
    securityContext:
      capabilities:
        drop: ["ALL"]
        add: ["NET_BIND_SERVICE"]
EOF

# Remove a single dangerous capability from the defaults
cat <<EOF
spec:
  containers:
  - name: myapp
    securityContext:
      capabilities:
        drop: ["NET_RAW", "SYS_ADMIN"]
EOF

# Verify capabilities inside a running container
kubectl exec -it <pod> -- cat /proc/1/status | grep Cap
# Decode with capsh:
capsh --decode=00000000a80425fb
```

**Exam tips:**
- Capabilities are CONTAINER-level — you cannot set them at `spec.securityContext` (pod level). Put them under `spec.containers[*].securityContext`.
- `drop: ["ALL"]` is the idiomatic exam answer for "remove all unnecessary capabilities".
- If asked to remove a specific capability (e.g., `NET_RAW`), only drop that one — `drop: ["ALL"]` may break the app.

---

## securityContext: Pod-Level vs Container-Level

**Why it matters:** Putting a field in the wrong place either silently does nothing or causes a validation error. The exam will test both placements.

**Concepts**

| Field | Pod-level (`spec.securityContext`) | Container-level (`spec.containers[*].securityContext`) |
|---|---|---|
| `runAsUser` / `runAsGroup` | Yes (default for all containers) | Yes (overrides pod-level) |
| `fsGroup` | Yes | No |
| `runAsNonRoot` | Yes | Yes |
| `seccompProfile` | Yes | Yes (overrides) |
| `appArmorProfile` | No (1.30+ per-container) | Yes |
| `capabilities` | No | Yes only |
| `readOnlyRootFilesystem` | No | Yes only |
| `allowPrivilegeEscalation` | No | Yes only |

**Commands & examples**
```bash
# Correct placement example
cat <<EOF
spec:
  securityContext:            # pod-level
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: myapp
    securityContext:          # container-level
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
      appArmorProfile:
        type: RuntimeDefault
EOF
```

**Exam tips:** If you put `capabilities` or `readOnlyRootFilesystem` at the pod level, kubectl will reject the manifest with a validation error — it won't silently ignore it. Always put capability and filesystem settings at the container level.

---

## Quick Command Reference
```bash
# --- OS Footprint ---
systemctl list-units --type=service --state=active
systemctl disable --now <service>
ss -tlnp
lsof -i -n -P

# --- Kernel Modules ---
lsmod | grep <module>
echo "blacklist <module>" >> /etc/modprobe.d/blacklist-cks.conf
echo "install <module> /bin/true" >> /etc/modprobe.d/blacklist-cks.conf
modprobe -r <module>

# --- User Hardening ---
usermod -s /bin/nologin <user>
gpasswd -d <user> sudo

# --- AppArmor ---
apparmor_parser -q /etc/apparmor.d/<profile>
aa-status | grep <profile>
aa-enforce /etc/apparmor.d/<profile>

# --- seccomp ---
crictl inspect <container-id> | grep -i seccomp

# --- Capabilities inside container ---
kubectl exec -it <pod> -- cat /proc/1/status | grep Cap
```

## Docs to Bookmark
- [AppArmor for Pods](https://kubernetes.io/docs/tutorials/security/apparmor/)
- [seccomp for Pods](https://kubernetes.io/docs/tutorials/security/seccomp/)
- [Configure a Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [Linux Capabilities](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container)
