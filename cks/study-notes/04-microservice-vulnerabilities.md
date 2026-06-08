# CKS Study Notes — Minimize Microservice Vulnerabilities (20%)

> Part of the CKS study-notes set; order follows the official CKS curriculum (v1.34, Kubernetes 1.34).
> Goal: understand each topic well enough to do the task fast under exam time pressure — not exhaustively.

**What the examiner tests here:** Enforcing Pod Security Standards, writing admission policies (Gatekeeper/Kyverno), encrypting Secrets at rest, running workloads in a sandbox (RuntimeClass), and making containers immutable. This is a 20% domain — high yield.

---

## Pod Security Admission (PSA) / Pod Security Standards (PSS)

**Why it matters:** PSA is the **built-in replacement for the removed PodSecurityPolicy**. It enforces baseline/restricted security at the namespace level — a near-guaranteed exam task. (Do **not** study PSP; it's gone.)

**Concepts**
- Three **standards**: `privileged` (no restrictions), `baseline` (blocks known privilege escalations), `restricted` (hardened best-practice).
- Three **modes** via namespace labels: `enforce` (reject), `audit` (log), `warn` (warn the user).
- `restricted` requires: `runAsNonRoot: true`, `allowPrivilegeEscalation: false`, `capabilities.drop: ["ALL"]`, `seccompProfile.type: RuntimeDefault`, no host namespaces/privileged.

**Commands & examples**

```bash
# Enforce restricted on a namespace (+ warn/audit for visibility):
kubectl label ns prod \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/audit=restricted
```
```yaml
# A pod that SATISFIES restricted:
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile: {type: RuntimeDefault}
  containers:
  - name: app
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      capabilities: {drop: ["ALL"]}
```

**⚠️ Exam tips:** Labels are the whole task — no extra objects. You can pin a version: `pod-security.kubernetes.io/enforce-version=v1.34`. Test enforcement by trying to create a privileged pod — it must be **forbidden**.

---

## Admission Policies: Gatekeeper & Kyverno

**Why it matters:** When PSA isn't expressive enough (e.g., "only images from registry X", "every pod needs limits"), policy engines enforce custom rules at admission. Kyverno (YAML) is more exam-friendly than Gatekeeper (Rego).

**Concepts**
- **OPA Gatekeeper**: a `ConstraintTemplate` (defines Rego logic + schema) + a `Constraint` (applies it with params).
- **Kyverno**: a single `ClusterPolicy` with rules of type `validate`, `mutate`, `generate`, or `verifyImages`. `validationFailureAction: Enforce` blocks; `Audit` only reports.
- Keep Rego minimal — deep policy authoring is rarely tested; applying a provided policy is.

**Commands & examples**

```yaml
# Kyverno: require non-root (validate / enforce)
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata: {name: require-run-as-non-root}
spec:
  validationFailureAction: Enforce
  rules:
  - name: check-non-root
    match: {any: [{resources: {kinds: [Pod]}}]}
    validate:
      message: "runAsNonRoot must be true"
      pattern:
        spec:
          =(securityContext):
            =(runAsNonRoot): true
```
```yaml
# Gatekeeper: ConstraintTemplate + Constraint (block privileged) — sketch
kind: ConstraintTemplate          # spec.crd.spec.names.kind: K8sBlockPrivileged
# ... rego in spec.targets[0].rego ...
---
kind: K8sBlockPrivileged          # the Constraint
metadata: {name: no-privileged}
spec: {match: {kinds: [{apiGroups: [""], kinds: ["Pod"]}]}}
```

**⚠️ Exam tips:** With Kyverno, `Enforce` blocks vs `Audit` only reports — read which the task wants. Test by applying a violating manifest and confirming rejection. Restrict registries with a Kyverno `validate` pattern like `image: "registry.internal/*"`.

---

## Secrets Management & Encryption at Rest

**Why it matters:** By default Secrets are only base64-encoded in etcd — readable by anyone with etcd/disk access. Encryption-at-rest is a classic, high-difficulty task.

**Concepts**
- An `EncryptionConfiguration` (provider e.g. `aescbc`/`aesgcm`/`secretbox`) is referenced by the apiserver flag `--encryption-provider-config`.
- It only encrypts **new writes** — you must re-encrypt existing Secrets.
- Verify by reading the raw etcd bytes (encrypted records start with `k8s:enc:aescbc:`).

**Commands & examples**

```yaml
# /etc/kubernetes/enc/enc.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources: ["secrets"]
  providers:
  - aescbc: {keys: [{name: key1, secret: <base64-32-byte-key>}]}
  - identity: {}        # fallback so existing plaintext still reads
```
```bash
# Generate a key:  head -c 32 /dev/urandom | base64
# Add to apiserver manifest:  --encryption-provider-config=/etc/kubernetes/enc/enc.yaml
#   + volume/volumeMount for /etc/kubernetes/enc  (see Cluster Hardening notes)

# RE-ENCRYPT all existing secrets after the apiserver restarts:
kubectl get secrets -A -o json | kubectl replace -f -

# VERIFY a secret is now encrypted in etcd:
sudo ETCDCTL_API=3 etcdctl get /registry/secrets/default/mysecret \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key | hexdump -C | head
```

**⚠️ Exam tips:** The re-encrypt step (`get … | replace -f -`) is the part people forget — without it old secrets stay plaintext. Put `identity` last as the read fallback. Don't forget the apiserver volume mount for the config file.

---

## Runtime Sandboxes (RuntimeClass / gVisor)

**Why it matters:** A sandbox (gVisor `runsc`, Kata) isolates a workload's syscalls from the host kernel — defense for untrusted code. Tasks ask you to run a pod under a RuntimeClass.

**Commands & examples**

```yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata: {name: gvisor}
handler: runsc          # must match the containerd runtime handler on the node
---
apiVersion: v1
kind: Pod
metadata: {name: sandboxed}
spec:
  runtimeClassName: gvisor
  containers: [{name: app, image: nginx}]
```

**⚠️ Exam tips:** `handler` must match what's configured in `/etc/containerd/config.toml` on the node (commonly `runsc`). Verify the pod runs and `dmesg`/`uname -a` inside differs from the host (gVisor kernel).

---

## Pod-to-Pod mTLS (concept) & Immutable Containers

**Why it matters:** mTLS encrypts and authenticates service-to-service traffic; immutability stops attackers writing payloads into a running container.

**Concepts & examples**

```yaml
# Immutable container:
    securityContext:
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
    volumeMounts: [{name: tmp, mountPath: /tmp}]   # emptyDir for needed writes
```
- **mTLS** (doc-navigable): Cilium offers transparent mTLS; Istio uses `PeerAuthentication` with `mtls.mode: STRICT`. Know where the docs are rather than memorizing every field.

**⚠️ Exam tips:** With `readOnlyRootFilesystem: true`, give the app an `emptyDir` for any path it must write (e.g. `/tmp`, cache) or it will crash.

---

## Quick command reference

```bash
kubectl label ns NS pod-security.kubernetes.io/enforce=restricted
kubectl label ns NS pod-security.kubernetes.io/warn=restricted
head -c 32 /dev/urandom | base64                       # encryption key
kubectl get secrets -A -o json | kubectl replace -f -  # re-encrypt
sudo ETCDCTL_API=3 etcdctl get /registry/secrets/NS/NAME --cacert=... | hexdump -C | head
# RuntimeClass: handler must match containerd; pod uses spec.runtimeClassName
```

## Docs to bookmark

- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)
- [Encrypting Confidential Data at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)
- [Secrets Good Practices](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)
- [Runtime Class](https://kubernetes.io/docs/concepts/containers/runtime-class/)
- [Kyverno policies](https://kyverno.io/policies/) · [Gatekeeper](https://open-policy-agent.github.io/gatekeeper/)
- [Configure SecurityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
