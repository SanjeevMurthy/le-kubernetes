# CKS Study Notes — Monitoring, Logging and Runtime Security (20%)

> Part of the CKS study-notes set; order follows the official CKS curriculum (v1.34, Kubernetes 1.34).
> Goal: understand each topic well enough to do the task fast under exam time pressure — not exhaustively.

**What the examiner tests here:** Writing/modifying Falco rules and reading its alerts, configuring API-server audit policy + logging, recognizing malicious behavior, and enforcing container immutability. A 20% domain — Falco is on nearly every exam, so do not skip it.

---

## Falco — Runtime Threat Detection

**Why it matters:** Falco watches kernel syscalls and fires alerts on suspicious behavior (shell in a container, writing to system dirs, unexpected network). It's the headline runtime tool and a near-guaranteed task — failing to prepare Falco is the single most common "I skipped it and failed" story.

**Concepts**
- Rules live in `/etc/falco/falco_rules.yaml` (defaults) and `/etc/falco/falco_rules.local.yaml` (your overrides/additions).
- A rule has: `rule`, `desc`, `condition`, `output`, `priority` (and optional `tags`).
- The `condition` uses Falco fields: `evt.type`, `proc.name`, `fd.name`, `container.id`, `container.name`, `user.name`, `container.image.repository`.
- Output fields use `%`: e.g. `%evt.time %container.id %proc.name`.

**Commands & examples**

```yaml
# /etc/falco/falco_rules.local.yaml — detect a shell launched inside a container
- rule: Shell In Container
  desc: A shell was spawned inside a container
  condition: container.id != host and proc.name in (bash, sh, zsh)
  output: "Shell in container (user=%user.name container=%container.name proc=%proc.name)"
  priority: WARNING
```
```bash
# Reload rules WITHOUT a full restart (preferred when asked to keep Falco running):
sudo kill -1 $(cat /var/run/falco.pid)      # SIGHUP reloads config/rules
# or, depending on install:
sudo systemctl reload falco

# Watch alerts:
sudo journalctl -fu falco
sudo tail -f /var/log/falco/events.txt      # if file_output is enabled
```

**⚠️ Exam tips:** A common task is **modify an existing rule's output format** (e.g., add `%container.image.repository`) and reload, then confirm the new alert format appears. Don't edit defaults in place — override in `falco_rules.local.yaml`. After any change, **reload** or the new rule won't fire. To redirect alerts to a file, enable `file_output` in `/etc/falco/falco.yaml`.

---

## API Server Audit Logging

**Why it matters:** Audit logs are the forensic record of every API request — who did what, when. Configuring an audit Policy + log backend is a classic high-difficulty apiserver task.

**Concepts**
- An audit **Policy** has rules with a `level`: `None`, `Metadata`, `Request`, `RequestResponse` (increasing detail).
- **First matching rule wins** → put specific rules *before* the catch-all, or the catch-all eats everything.
- The apiserver writes the log; you wire it in via flags + (because it's file-backed) **volumes/volumeMounts**.

**Commands & examples**

```yaml
# /etc/kubernetes/audit/policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse          # full detail for secret access (specific FIRST)
  resources: [{group: "", resources: ["secrets"]}]
- level: Metadata                 # log who/what for pod exec
  resources: [{group: "", resources: ["pods/exec"]}]
- level: None                     # drop noisy read-only events
  verbs: ["get", "watch", "list"]
- level: Metadata                 # catch-all LAST
```
```yaml
# Add to kube-apiserver.yaml (back up first!):
    - --audit-policy-file=/etc/kubernetes/audit/policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit.log
    - --audit-log-maxage=7
    - --audit-log-maxbackup=2
    - --audit-log-maxsize=50
    volumeMounts:
    - {name: audit-policy, mountPath: /etc/kubernetes/audit, readOnly: true}
    - {name: audit-logs,   mountPath: /var/log/kubernetes}
  volumes:
  - {name: audit-policy, hostPath: {path: /etc/kubernetes/audit, type: DirectoryOrCreate}}
  - {name: audit-logs,   hostPath: {path: /var/log/kubernetes, type: DirectoryOrCreate}}
```
```bash
# Read the log:
sudo tail -f /var/log/kubernetes/audit.log | jq 'select(.verb=="delete")'
```

**⚠️ Exam tips:** Rule **order matters** (first match wins) — a `level: None` for reads must come before the catch-all. Forgetting the `volumes`/`volumeMounts` (or pointing the path wrong) breaks the apiserver — verify it restarts with `/readyz` and that the log file is actually being written.

---

## Behavioral Analytics & Threat Detection

**Why it matters:** The exam may give you Falco/audit output and ask what's happening, or to write a rule that catches a described attack.

**Concepts**
- Map signals to attack phases: recon (`kubectl get` from a pod token), exploit (shell in container), lateral movement (API calls with a stolen SA token), exfil/persistence (unexpected outbound connection, write below `/bin`, `/etc/passwd` modification).
- High-value Falco conditions: `write below binary dir`, `unexpected outbound connection`, `modify /etc/passwd`, package-manager run inside container.

**⚠️ Exam tips:** If asked to detect "a reverse shell" or "crypto miner", target the *behavior* (outbound connection from a container, shell process, write to system dirs) rather than a specific binary name.

---

## Immutable Containers at Runtime

**Why it matters:** A read-only root filesystem stops an attacker who lands in a container from writing tools, payloads, or modifying binaries to persist.

**Commands & examples**

```yaml
    securityContext:
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      runAsNonRoot: true
    volumeMounts: [{name: tmp, mountPath: /tmp}]
  volumes: [{name: tmp, emptyDir: {}}]   # give back only the paths it must write
```

**⚠️ Exam tips:** If a container needs to write (logs, cache, `/tmp`), mount an `emptyDir` there — otherwise it crashes on a read-only root. Verify with `kubectl exec ... -- touch /test` failing while `/tmp` works.

---

## Quick command reference

```bash
# Falco
sudo kill -1 $(cat /var/run/falco.pid)         # reload rules (SIGHUP)
sudo journalctl -fu falco
#   rules: /etc/falco/falco_rules.local.yaml ; config: /etc/falco/falco.yaml

# Audit
#   policy: /etc/kubernetes/audit/policy.yaml ; flags in kube-apiserver.yaml
#   levels: None < Metadata < Request < RequestResponse ; FIRST MATCH WINS
sudo tail -f /var/log/kubernetes/audit.log | jq 'select(.user.username=="...")'

# Immutable
#   securityContext.readOnlyRootFilesystem: true  + emptyDir for writable paths
```

## Docs to bookmark

- [Falco rules](https://falco.org/docs/rules/) · [Falco fields](https://falco.org/docs/reference/rules/supported-fields/) *(falco.org allowed in-exam)*
- [Auditing](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/)
- [Audit Policy reference](https://kubernetes.io/docs/reference/config-api/apiserver-audit.v1/)
- [Configure SecurityContext (readOnlyRootFilesystem)](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [Security Checklist](https://kubernetes.io/docs/concepts/security/security-checklist/)
