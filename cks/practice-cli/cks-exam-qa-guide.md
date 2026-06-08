# CKS Exam — Question & Answer Solution Guide

> **18 exam-style CKS question archetypes** in official curriculum order (v1.34), with detailed solutions, commands, YAML manifests, key tips, and official documentation links. Distilled from the CKS curriculum and first-hand exam debriefs.
>
> **Exam Format**: ~15–17 performance-based tasks | 2 hours | 67% passing score | Kubernetes v1.34 | prerequisite: passed CKA
>
> **Allowed Documentation During Exam**: kubernetes.io/docs, kubernetes.io/blog, falco.org/docs, etcd.io/docs, kubernetes-sigs.github.io/bom/cli-reference, kubernetes.github.io/ingress-nginx, docs.cilium.io, istio.io/latest/docs
>
> This guide drives the `[Q]` (question) and `[H]` (solution) actions in the CKS practice CLI. Run `./cks` to practice interactively.
---

## DOMAIN 1 — Cluster Setup (15%)

---

### Q1. NetworkPolicy: Default-Deny + Selective Allow

**Question:**
Namespace `prod` runs a `backend` deployment (label `app=backend`) and a `frontend` deployment (label `app=frontend`). Apply a default-deny policy for all ingress and egress in `prod`, then add policies so that: (a) `backend` pods accept ingress only from `frontend` pods on TCP 8080, and (b) all pods may still resolve DNS. Do not break DNS.

**Concept & Explanation:**

NetworkPolicies are additive, namespaced allow-lists enforced by the CNI (Calico/Cilium). An empty `podSelector: {}` selects all pods; a policy listing a `policyType` with no rules denies that whole direction. Because a default-deny egress also blocks DNS (UDP/TCP 53 to kube-dns), you must explicitly re-allow it — the single most common NetworkPolicy mistake.

**Solution — Step by Step:**

```bash
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: default-deny-all, namespace: prod}
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: allow-frontend-to-backend, namespace: prod}
spec:
  podSelector: {matchLabels: {app: backend}}
  policyTypes: [Ingress]
  ingress:
  - from:
    - podSelector: {matchLabels: {app: frontend}}
    ports:
    - {port: 8080, protocol: TCP}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: allow-dns, namespace: prod}
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - {port: 53, protocol: UDP}
    - {port: 53, protocol: TCP}
EOF
```

**Key Points to Remember:**

- Default-deny egress **breaks DNS** unless you allow port 53 UDP **and** TCP — always add the DNS rule.
- `podSelector: {}` = all pods in the namespace; omit a `policyType` and that direction is unaffected.
- Verify with a probe pod: `kubectl exec` a curl into `backend:8080` from `frontend` (allowed) vs another pod (denied).

**Official Documentation:**
- https://kubernetes.io/docs/concepts/services-networking/network-policies/

---

### Q2. CIS Benchmark Remediation with kube-bench

**Question:**
Run the CIS Kubernetes Benchmark against the control-plane node using `kube-bench`. Identify the FAIL items related to the API server and kubelet, and remediate at least the findings for `--anonymous-auth` and kubelet `--read-only-port`. Re-run to confirm the findings pass.

**Concept & Explanation:**

`kube-bench` checks your cluster's configuration against the CIS Benchmark, emitting PASS/WARN/FAIL with remediation text. Most FAILs map to a flag in a static-pod manifest (`/etc/kubernetes/manifests/`) or the kubelet config (`/var/lib/kubelet/config.yaml`). You fix the config, restart the affected component, and re-run.

**Solution — Step by Step:**

```bash
# Run against the relevant target
kube-bench run --targets master | grep -A3 "\[FAIL\]"
# or as a Job:  kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml

# Example fix 1 — apiserver anonymous-auth (edit the static pod manifest):
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kas.bak
sudo sed -i 's/--anonymous-auth=true/--anonymous-auth=false/' \
  /etc/kubernetes/manifests/kube-apiserver.yaml   # or add the flag if missing

# Example fix 2 — kubelet read-only port:
sudo vi /var/lib/kubelet/config.yaml      # set: readOnlyPort: 0
sudo systemctl restart kubelet

# Re-verify
sudo crictl ps | grep apiserver
kube-bench run --targets master,node | grep -A2 "anonymous-auth\|read-only"
```

**Key Points to Remember:**

- FAIL items come with a **Remediation** block — read it; it tells you the exact flag/file.
- apiserver/scheduler/controller-manager fixes go in `/etc/kubernetes/manifests/*` (auto-restart); kubelet fixes go in `/var/lib/kubelet/config.yaml` then `systemctl restart kubelet`.
- Back up any manifest before editing.

**Official Documentation:**
- https://github.com/aquasecurity/kube-bench
- https://kubernetes.io/docs/concepts/security/security-checklist/

---

### Q3. Ingress TLS Termination

**Question:**
Expose service `web` (port 80) in namespace `prod` through an Ingress `web-ingress` for host `secure.example.com`, terminating TLS using a self-signed certificate stored in a `kubernetes.io/tls` secret named `web-tls`.

**Concept & Explanation:**

TLS termination at the Ingress means the controller decrypts HTTPS using a certificate/key supplied as a `kubernetes.io/tls` secret, referenced under `spec.tls`. You generate the cert with openssl, load it into a TLS secret, and bind it to the host in the Ingress.

**Solution — Step by Step:**

```bash
# 1. Self-signed cert/key for the host
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=secure.example.com/O=secure"

# 2. TLS secret
kubectl create secret tls web-tls --cert=tls.crt --key=tls.key -n prod

# 3. Ingress with TLS
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata: {name: web-ingress, namespace: prod}
spec:
  tls:
  - hosts: [secure.example.com]
    secretName: web-tls
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend: {service: {name: web, port: {number: 80}}}
EOF
```

**Key Points to Remember:**

- Secret **type must be `kubernetes.io/tls`** with keys `tls.crt` and `tls.key` — `create secret tls` does this.
- `spec.tls[].secretName` binds the cert to the host(s) in `spec.tls[].hosts`.
- Verify: `kubectl get ingress -n prod` shows the host; `curl -k https://secure.example.com --resolve ...`.

**Official Documentation:**
- https://kubernetes.io/docs/concepts/services-networking/ingress/#tls

---

## DOMAIN 2 — Cluster Hardening (15%)

---

### Q4. RBAC Least-Privilege Role + Binding

**Question:**
ServiceAccount `ci` in namespace `build` currently has cluster-admin via a binding. Replace it so `ci` can only `get`, `list`, and `watch` `pods` and `pods/log` in namespace `build` — nothing else. Verify the effective permissions.

**Concept & Explanation:**

Least privilege means granting the narrowest verbs/resources in the smallest scope. Here you remove the over-broad ClusterRoleBinding and add a namespaced Role + RoleBinding. `auth can-i --as` proves the result, which is how the task is graded.

**Solution — Step by Step:**

```bash
# 1. Remove the over-permissioned binding
kubectl delete clusterrolebinding ci-admin    # (whatever granted cluster-admin)

# 2. Create a tight Role + RoleBinding
kubectl create role ci-pod-reader \
  --verb=get,list,watch --resource=pods,pods/log -n build
kubectl create rolebinding ci-pod-reader \
  --role=ci-pod-reader --serviceaccount=build:ci -n build

# 3. VERIFY (graded on this)
kubectl auth can-i list pods   --as=system:serviceaccount:build:ci -n build   # yes
kubectl auth can-i delete pods --as=system:serviceaccount:build:ci -n build   # no
kubectl auth can-i get secrets --as=system:serviceaccount:build:ci -n build   # no
```

**Key Points to Remember:**

- Removing the broad binding is half the task — adding a tight one is the other half.
- `--as=system:serviceaccount:<ns>:<sa>` is the canonical verification.
- Use `Role`/`RoleBinding` (namespaced), not ClusterRole, to keep it scoped to `build`.

**Official Documentation:**
- https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- https://kubernetes.io/docs/concepts/security/rbac-good-practices/

---

### Q5. ServiceAccount Token Hardening

**Question:**
The pod `legacy` in namespace `app` should not have a ServiceAccount token mounted (it never calls the API). Create a dedicated ServiceAccount `app-sa` with automount disabled, and ensure the pod uses it with no token mounted.

**Concept & Explanation:**

A mounted SA token is a stealable credential. Setting `automountServiceAccountToken: false` (on the SA or pod) removes `/var/run/secrets/kubernetes.io/serviceaccount/` from the container, shrinking the blast radius of a compromise.

**Solution — Step by Step:**

```bash
kubectl create serviceaccount app-sa -n app
kubectl patch serviceaccount app-sa -n app \
  -p '{"automountServiceAccountToken": false}'
```
```yaml
# Pod uses the SA and (belt-and-suspenders) disables automount at pod level:
apiVersion: v1
kind: Pod
metadata: {name: legacy, namespace: app}
spec:
  serviceAccountName: app-sa
  automountServiceAccountToken: false
  containers:
  - {name: c, image: nginx}
```
```bash
# Verify: the token dir should be absent
kubectl exec -n app legacy -- ls /var/run/secrets/kubernetes.io/serviceaccount 2>&1 # No such file
```

**Key Points to Remember:**

- Pod-level `automountServiceAccountToken` overrides the SA-level setting.
- Give workloads their **own** SA, never rely on `default`.
- Verify by exec-ing into the pod and confirming the token path is gone.

**Official Documentation:**
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/

---

### Q6. Restrict the API Server (apiserver flags)

**Question:**
Harden the API server on the control-plane node: disable anonymous authentication, ensure the authorization mode is `Node,RBAC`, and enable the `NodeRestriction` admission plugin. Confirm the API server comes back healthy.

**Concept & Explanation:**

The kube-apiserver runs as a static pod; its flags live in `/etc/kubernetes/manifests/kube-apiserver.yaml`. Editing the file makes the kubelet recreate the pod. A bad edit takes down the control plane, so back up first and know how to diagnose a failed restart.

**Solution — Step by Step:**

```bash
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kas.bak

# Ensure these appear under spec.containers[0].command:
#   - --anonymous-auth=false
#   - --authorization-mode=Node,RBAC
#   - --enable-admission-plugins=NodeRestriction   (append to existing list)
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml

# Wait for restart, then verify health:
sudo crictl ps | grep kube-apiserver
kubectl get --raw='/readyz'
kubectl -n kube-system get pod -l component=kube-apiserver

# If it does NOT recover:
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}')
sudo journalctl -u kubelet -f
```

**Key Points to Remember:**

- **Back up first.** A typo in the manifest stops the API server entirely.
- Append `NodeRestriction` to any existing `--enable-admission-plugins` list (comma-separated) — don't drop the others.
- The pod restart takes 30–90s and the API may be briefly unreachable; confirm with `/readyz`.

**Official Documentation:**
- https://kubernetes.io/docs/concepts/security/controlling-access/
- https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/
---

## DOMAIN 3 — System Hardening (10%)

---

### Q7. AppArmor Profile on a Pod

**Question:**
An AppArmor profile named `k8s-deny-write` (denies writes to the filesystem) is provided. Load it on the worker node, then run a pod `secure-pod` whose container is confined by that profile. Confirm the profile is enforced.

**Concept & Explanation:**

AppArmor is a Linux MAC system that confines a process to an allow-list of capabilities/paths. The profile must be loaded into the kernel on the node **before** a pod references it. Kubernetes 1.30+ sets it via `securityContext.appArmorProfile`; older clusters use a `container.apparmor.security.beta.kubernetes.io/<container>` annotation.

**Solution — Step by Step:**

```bash
# On the node: load and confirm the profile
sudo apparmor_parser -q /etc/apparmor.d/k8s-deny-write
sudo aa-status | grep k8s-deny-write
```
```yaml
# Pod confined by the profile (Kubernetes 1.30+ field form)
apiVersion: v1
kind: Pod
metadata: {name: secure-pod}
spec:
  containers:
  - name: c
    image: busybox
    command: ["sh","-c","sleep 3600"]
    securityContext:
      appArmorProfile:
        type: Localhost
        localhostProfile: k8s-deny-write
```
```bash
# Verify enforcement: a write should be denied
kubectl exec secure-pod -- sh -c 'echo x > /root/test' 2>&1   # Permission denied
```

**Key Points to Remember:**

- The profile must be **loaded on the node first** (`apparmor_parser`); a pod referencing an unloaded profile won't start.
- 1.30+ uses `securityContext.appArmorProfile` (`type: Localhost`, `localhostProfile: <name>`); legacy uses the beta annotation.
- `aa-status` shows loaded profiles and enforce/complain mode.

**Official Documentation:**
- https://kubernetes.io/docs/tutorials/security/apparmor/
- https://kubernetes.io/docs/concepts/security/linux-kernel-security-constraints/

---

### Q8. Seccomp RuntimeDefault + Custom Profile

**Question:**
Run pod `audited` using the `RuntimeDefault` seccomp profile. Then run pod `custom` using a custom seccomp profile located at `profiles/audit.json` under the kubelet seccomp directory. Verify both pods run.

**Concept & Explanation:**

Seccomp filters the syscalls a container may make. `RuntimeDefault` applies the container runtime's curated profile (recommended baseline). Custom profiles are JSON files placed under `/var/lib/kubelet/seccomp/` and referenced by relative path via `type: Localhost`.

**Solution — Step by Step:**

```yaml
# RuntimeDefault (pod-level securityContext)
apiVersion: v1
kind: Pod
metadata: {name: audited}
spec:
  securityContext:
    seccompProfile: {type: RuntimeDefault}
  containers: [{name: c, image: nginx}]
---
# Custom profile at /var/lib/kubelet/seccomp/profiles/audit.json
apiVersion: v1
kind: Pod
metadata: {name: custom}
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/audit.json
  containers: [{name: c, image: nginx}]
```
```bash
# The custom profile file (on the node), e.g. an audit-logging profile:
sudo mkdir -p /var/lib/kubelet/seccomp/profiles
# (place audit.json with {"defaultAction":"SCMP_ACT_LOG"} or similar)

# Verify the applied profile:
kubectl get pod custom -o jsonpath='{.spec.securityContext.seccompProfile}'
sudo crictl inspect <container-id> | grep -i seccomp
```

**Key Points to Remember:**

- `localhostProfile` is **relative to `/var/lib/kubelet/seccomp/`** — don't use an absolute path.
- The JSON file must exist on the node where the pod is scheduled, or the pod fails to start.
- `RuntimeDefault` is the easy, recommended baseline and satisfies the `restricted` PSS.

**Official Documentation:**
- https://kubernetes.io/docs/tutorials/security/seccomp/

---

## DOMAIN 4 — Minimize Microservice Vulnerabilities (20%)

---

### Q9. Enforce Pod Security Admission (restricted)

**Question:**
Label namespace `payments` so the `restricted` Pod Security Standard is enforced (and also warns). Confirm a privileged pod is rejected and a compliant pod is admitted.

**Concept & Explanation:**

Pod Security Admission enforces the Pod Security Standards via namespace labels — no extra objects. `restricted` blocks privilege escalation, host namespaces, running as root, and requires a seccomp profile.

**Solution — Step by Step:**

```bash
kubectl label ns payments \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/warn=restricted

# Should be REJECTED:
kubectl run bad --image=nginx -n payments \
  --overrides='{"spec":{"containers":[{"name":"bad","image":"nginx","securityContext":{"privileged":true}}]}}'

# Should be ADMITTED:
kubectl apply -n payments -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata: {name: good}
spec:
  securityContext: {runAsNonRoot: true, seccompProfile: {type: RuntimeDefault}}
  containers:
  - name: c
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      capabilities: {drop: ["ALL"]}
EOF
```

**Key Points to Remember:**

- The entire task is namespace **labels** — `enforce`/`warn`/`audit` with a level.
- `restricted` requires `runAsNonRoot`, `allowPrivilegeEscalation: false`, `capabilities.drop:[ALL]`, `seccompProfile`.
- Prove it: the privileged pod must be **forbidden**; the compliant one must run.

**Official Documentation:**
- https://kubernetes.io/docs/concepts/security/pod-security-admission/
- https://kubernetes.io/docs/concepts/security/pod-security-standards/

---

### Q10. Encrypt Secrets at Rest (EncryptionConfiguration)

**Question:**
Enable encryption at rest for Secrets using an `aescbc` provider. Configure the API server to use `/etc/kubernetes/enc/enc.yaml`, then ensure all existing Secrets are encrypted. Verify a Secret is stored encrypted in etcd.

**Concept & Explanation:**

The apiserver encrypts resources before writing to etcd when given an `EncryptionConfiguration` via `--encryption-provider-config`. It only encrypts new writes, so existing Secrets must be rewritten. Encrypted etcd values are prefixed `k8s:enc:aescbc:`.

**Solution — Step by Step:**

```bash
# 1. 32-byte key
head -c 32 /dev/urandom | base64
```
```yaml
# 2. /etc/kubernetes/enc/enc.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources: ["secrets"]
  providers:
  - aescbc: {keys: [{name: key1, secret: <BASE64_KEY>}]}
  - identity: {}
```
```bash
# 3. apiserver: add flag + mount the dir, then it restarts
#   - --encryption-provider-config=/etc/kubernetes/enc/enc.yaml
#   volumeMount + hostPath volume for /etc/kubernetes/enc
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kas.bak
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml

# 4. Re-encrypt existing secrets
kubectl get secrets -A -o json | kubectl replace -f -

# 5. Verify in etcd
sudo ETCDCTL_API=3 etcdctl get /registry/secrets/default/<name> \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key | hexdump -C | head   # k8s:enc:aescbc:
```

**Key Points to Remember:**

- **Re-encrypt** existing Secrets (`get … | replace -f -`) — new config only affects new writes.
- Keep `identity` as the last provider so reads of not-yet-encrypted data still work.
- Add the apiserver `volumes`/`volumeMounts` for `/etc/kubernetes/enc` or it can't read the config.

**Official Documentation:**
- https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/

---

### Q11. Admission Policy with Kyverno/Gatekeeper

**Question:**
Using Kyverno (already installed), create a `ClusterPolicy` that blocks any Pod whose container image does not come from `registry.internal/`. The policy must enforce (reject), not just audit.

**Concept & Explanation:**

Kyverno evaluates `ClusterPolicy` rules at admission. A `validate` rule with `validationFailureAction: Enforce` rejects violating resources. A pattern match on `image` restricts the allowed registry — a common supply-chain/admission control.

**Solution — Step by Step:**

```bash
kubectl apply -f - <<'EOF'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata: {name: restrict-registries}
spec:
  validationFailureAction: Enforce
  background: false
  rules:
  - name: only-internal-registry
    match: {any: [{resources: {kinds: [Pod]}}]}
    validate:
      message: "images must come from registry.internal/"
      pattern:
        spec:
          containers:
          - image: "registry.internal/*"
EOF

# Test: should be REJECTED
kubectl run bad --image=nginx
# Should be ADMITTED
kubectl run ok --image=registry.internal/nginx:1.27
```

**Key Points to Remember:**

- `validationFailureAction: Enforce` blocks; `Audit` only reports — read which the task wants.
- Patterns support wildcards (`registry.internal/*`); apply to `initContainers`/`ephemeralContainers` too if asked.
- Verify by applying a violating pod and confirming rejection.

**Official Documentation:**
- https://kyverno.io/docs/ · https://kyverno.io/policies/
- https://open-policy-agent.github.io/gatekeeper/

---

### Q12. Runtime Sandbox with RuntimeClass (gVisor)

**Question:**
The node has the gVisor (`runsc`) runtime configured in containerd. Create a `RuntimeClass` named `gvisor` and run a pod `sandboxed` under it. Confirm the pod runs inside the sandbox.

**Concept & Explanation:**

A RuntimeClass selects an alternate container runtime (handler) per pod. gVisor's `runsc` intercepts syscalls in userspace, isolating the container from the host kernel — strong isolation for untrusted workloads.

**Solution — Step by Step:**

```bash
kubectl apply -f - <<'EOF'
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata: {name: gvisor}
handler: runsc
---
apiVersion: v1
kind: Pod
metadata: {name: sandboxed}
spec:
  runtimeClassName: gvisor
  containers:
  - {name: c, image: nginx}
EOF

# Verify the sandbox kernel differs from the host:
kubectl exec sandboxed -- dmesg 2>/dev/null | head    # gVisor signature
kubectl exec sandboxed -- uname -a
```

**Key Points to Remember:**

- `handler` must match the runtime name registered in `/etc/containerd/config.toml` (typically `runsc`).
- The pod sets `spec.runtimeClassName: gvisor`.
- If the handler isn't installed, the pod stays `Pending`/`ContainerCreating` — confirm node setup.

**Official Documentation:**
- https://kubernetes.io/docs/concepts/containers/runtime-class/
---

## DOMAIN 5 — Supply Chain Security (20%)

---

### Q13. Scan Images with Trivy and Remediate

**Question:**
Deployment `web` in namespace `prod` runs `nginx:1.18.0`. Use Trivy to confirm it has HIGH/CRITICAL vulnerabilities, then update the deployment to a patched image (`nginx:1.27.0`) that has no CRITICALs. Confirm the rollout.

**Concept & Explanation:**

Trivy scans container images for known CVEs in OS packages and libraries. The exam pattern is: scan → identify the vulnerable image actually running → replace it with a clean tag → verify. Trivy docs are NOT allowed in-exam, so the flags must be memorized.

**Solution — Step by Step:**

```bash
# 1. Confirm the current image is vulnerable
trivy image --severity HIGH,CRITICAL nginx:1.18.0

# 2. Confirm the replacement is clean of criticals
trivy image --severity CRITICAL nginx:1.27.0

# 3. Find/replace the running image
kubectl get deploy web -n prod -o jsonpath='{.spec.template.spec.containers[*].image}'
kubectl set image deploy/web web=nginx:1.27.0 -n prod
kubectl rollout status deploy/web -n prod
```

**Key Points to Remember:**

- `--severity HIGH,CRITICAL` focuses the scan; `--ignore-unfixed` shows only patchable CVEs.
- The deliverable is a **clean image running** — verify the new pod is Ready on the new tag.
- Audit all cluster images: `kubectl get pods -A -o=custom-columns=NS:.metadata.namespace,IMG:.spec.containers[*].image`.

**Official Documentation:**
- https://aquasecurity.github.io/trivy/ (not allowed in-exam — memorize flags)

---

### Q14. Restrict Images via ImagePolicyWebhook/Registry

**Question:**
Only images from the registry `registry.internal` may run cluster-wide. Implement this with admission control. (Either configure the `ImagePolicyWebhook` admission plugin against the provided endpoint, or enforce it with a Kyverno policy if a webhook backend is unavailable.)

**Concept & Explanation:**

`ImagePolicyWebhook` makes the apiserver consult an external service to allow/deny each image; it needs an `AdmissionConfiguration` file, a webhook kubeconfig, and the plugin enabled — plus volume mounts. Where no backend exists, a Kyverno `validate` policy enforces the same registry allow-list more simply.

**Solution — Step by Step:**

```yaml
# Option A — ImagePolicyWebhook
# /etc/kubernetes/admission/admission-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/admission/webhook.kubeconfig
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: false        # fail closed
```
```bash
# apiserver flags (back up first; add volumes/volumeMounts for /etc/kubernetes/admission):
#   --enable-admission-plugins=...,ImagePolicyWebhook
#   --admission-control-config-file=/etc/kubernetes/admission/admission-config.yaml
```
```yaml
# Option B — Kyverno allowed-registry (simpler, common)
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata: {name: allowed-registry}
spec:
  validationFailureAction: Enforce
  rules:
  - name: only-internal
    match: {any: [{resources: {kinds: [Pod]}}]}
    validate:
      message: "only registry.internal images allowed"
      pattern: {spec: {containers: [{image: "registry.internal/*"}]}}
```

**Key Points to Remember:**

- ImagePolicyWebhook = config file + webhook kubeconfig + apiserver flags + **volume mounts**; `defaultAllow: false` fails closed.
- Back up the apiserver manifest; a wrong path here breaks the control plane.
- Kyverno is the faster path when the task just says "restrict the registry."

**Official Documentation:**
- https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#imagepolicywebhook
- https://kyverno.io/policies/

---

### Q15. Static Analysis & Manifest Hardening (kubesec)

**Question:**
A pod manifest `app.yaml` scores poorly on security. Run `kubesec` against it, then harden the manifest so it passes the major checks (no privilege escalation, read-only root FS, drop all capabilities, run as non-root). Re-scan to confirm improvement.

**Concept & Explanation:**

`kubesec` statically scores a workload manifest and lists specific advice (positive points for good settings, criticals for bad ones). You apply the recommended `securityContext` hardening and re-scan to confirm the score rose.

**Solution — Step by Step:**

```bash
kubesec scan app.yaml         # read the "advise" + "critical" lists
```
```yaml
# Hardened pod
apiVersion: v1
kind: Pod
metadata: {name: app}
spec:
  securityContext: {runAsNonRoot: true, runAsUser: 1000}
  containers:
  - name: c
    image: nginx
    securityContext:
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      capabilities: {drop: ["ALL"]}
    resources:
      limits: {cpu: "200m", memory: "128Mi"}
    volumeMounts: [{name: tmp, mountPath: /tmp}]
  volumes: [{name: tmp, emptyDir: {}}]
```
```bash
kubesec scan app.yaml         # score should be higher / criticals cleared
```

**Key Points to Remember:**

- High-value fixes: drop `privileged`, set `readOnlyRootFilesystem`, `runAsNonRoot`, `capabilities.drop:[ALL]`, `allowPrivilegeEscalation:false`, add resource limits.
- `readOnlyRootFilesystem: true` needs an `emptyDir` for any path the app writes (e.g. `/tmp`).
- The task is graded on the **fixed manifest** — re-scan to prove it.

**Official Documentation:**
- https://kubesec.io/ · https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

---

## DOMAIN 6 — Monitoring, Logging and Runtime Security (20%)

---

### Q16. Detect Threats with Falco Rules

**Question:**
Falco is running on the node. Add a custom rule that fires at `WARNING` when a shell (`bash`/`sh`) is started inside any container, with an output line that includes the container name and process. Reload Falco without a full restart and confirm the rule triggers.

**Concept & Explanation:**

Falco evaluates kernel syscall events against rules. Custom rules go in `/etc/falco/falco_rules.local.yaml` (so defaults stay intact). A rule has `condition` (Falco fields), `output`, and `priority`. Falco must reload to pick up changes — `SIGHUP` reloads without dropping the process.

**Solution — Step by Step:**

```yaml
# /etc/falco/falco_rules.local.yaml
- rule: Shell In Container
  desc: Detect a shell spawned inside a container
  condition: container.id != host and proc.name in (bash, sh)
  output: "Shell in container (container=%container.name proc=%proc.name user=%user.name)"
  priority: WARNING
```
```bash
# Reload without full restart
sudo kill -1 $(cat /var/run/falco.pid)        # SIGHUP
# Trigger + observe
kubectl exec -it <somepod> -- sh
sudo journalctl -fu falco | grep "Shell in container"
```

**Key Points to Remember:**

- Put custom rules in `falco_rules.local.yaml`, not the default file.
- **Reload after editing** (`kill -1 $(cat /var/run/falco.pid)` or `systemctl reload falco`) or the rule won't fire.
- Output fields use `%field`; common ones: `%container.name`, `%proc.name`, `%fd.name`, `%user.name`.

**Official Documentation:**
- https://falco.org/docs/rules/ (falco.org allowed in-exam)

---

### Q17. API Server Audit Logging Policy

**Question:**
Configure API server auditing: log Secret access at `RequestResponse`, drop read-only (`get`/`list`/`watch`) noise, and log everything else at `Metadata`. Write logs to `/var/log/kubernetes/audit.log`. Confirm the log is being written.

**Concept & Explanation:**

An audit Policy lists rules evaluated **first-match-wins**, each with a `level`. You wire the policy and log path into the apiserver via flags plus hostPath volume mounts (the policy is file-backed and the log dir must be writable).

**Solution — Step by Step:**

```yaml
# /etc/kubernetes/audit/policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  resources: [{group: "", resources: ["secrets"]}]
- level: None
  verbs: ["get", "watch", "list"]
- level: Metadata
```
```yaml
# kube-apiserver.yaml (back up first) — flags + mounts:
    - --audit-policy-file=/etc/kubernetes/audit/policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit.log
    - --audit-log-maxage=7
    volumeMounts:
    - {name: audit-policy, mountPath: /etc/kubernetes/audit, readOnly: true}
    - {name: audit-logs,   mountPath: /var/log/kubernetes}
  volumes:
  - {name: audit-policy, hostPath: {path: /etc/kubernetes/audit, type: DirectoryOrCreate}}
  - {name: audit-logs,   hostPath: {path: /var/log/kubernetes, type: DirectoryOrCreate}}
```
```bash
sudo crictl ps | grep apiserver
sudo tail -f /var/log/kubernetes/audit.log | jq 'select(.objectRef.resource=="secrets")'
```

**Key Points to Remember:**

- **First match wins** — the Secret `RequestResponse` rule and the `None` read rule must come **before** the catch-all `Metadata`.
- Forgetting the `volumes`/`volumeMounts` (or a wrong path) breaks the apiserver — back up and verify `/readyz`.
- Confirm the log file is actually growing.

**Official Documentation:**
- https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/

---

### Q18. Immutable Containers (readOnlyRootFilesystem)

**Question:**
Harden deployment `api` in namespace `prod` so its container runs with a read-only root filesystem and cannot escalate privileges, while still being able to write to `/tmp`.

**Concept & Explanation:**

A read-only root filesystem prevents an attacker from writing payloads or modifying binaries inside a running container. Any legitimately writable path is provided via an `emptyDir` mount so the app still works.

**Solution — Step by Step:**

```bash
kubectl patch deploy api -n prod --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/securityContext","value":{
     "readOnlyRootFilesystem": true,
     "allowPrivilegeEscalation": false,
     "runAsNonRoot": true}},
  {"op":"add","path":"/spec/template/spec/volumes","value":[{"name":"tmp","emptyDir":{}}]},
  {"op":"add","path":"/spec/template/spec/containers/0/volumeMounts","value":[{"name":"tmp","mountPath":"/tmp"}]}
]'
kubectl rollout status deploy/api -n prod
```

**Key Points to Remember:**

- `readOnlyRootFilesystem: true` + `emptyDir` for writable paths — without the emptyDir the app crashes if it writes.
- Pair with `allowPrivilegeEscalation: false` and `runAsNonRoot: true` for the full hardening.
- Verify: `kubectl exec ... -- touch /test` fails; `touch /tmp/test` succeeds.

**Official Documentation:**
- https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
