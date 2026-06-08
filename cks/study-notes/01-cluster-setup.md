# CKS Study Notes — Cluster Setup (15%)

> Part of the CKS study-notes set; order follows the official CKS curriculum (v1.34, Kubernetes 1.34).
> Goal: understand each topic well enough to do the task fast under exam time pressure — not exhaustively.

**What the examiner tests here:** Creating and applying NetworkPolicies (including the DNS egress trap), running kube-bench and remediating findings, configuring Ingress TLS, blocking cloud metadata endpoints, and verifying binary checksums.

---

## NetworkPolicy: Default-Deny + Selective Allow

**Why it matters:** By default all pod-to-pod traffic is allowed. A default-deny policy is the CKS baseline; selective-allow policies are how you then open only what's needed. Expect 1–2 tasks requiring you to write or fix a policy under time pressure.

**Concepts**
- Policies are additive and namespace-scoped; there is no "global" deny built in
- `policyTypes: [Ingress, Egress]` — if omitted, only the direction(s) with rules are enforced
- Selectors: `podSelector` (empty `{}` = all pods in namespace), `namespaceSelector`, `ipBlock`
- A policy with empty `spec.ingress` / `spec.egress` blocks ALL traffic for that direction
- Ports in a rule are **OR** within the rule; rules themselves are **OR** across the list

**Commands & examples**

```bash
# 1. Default-deny ALL ingress AND egress in a namespace
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# 2. Allow ingress to app pods from frontend pods on port 8080
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-app
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 8080
      protocol: TCP
EOF

# 3. Allow egress to another namespace (e.g. monitoring namespace)
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-monitoring
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
    ports:
    - port: 9090
      protocol: TCP
EOF
```

---

## NetworkPolicy: The DNS Egress Trap (Port 53)

**Why it matters:** This is the single most common CKS gotcha. If you apply a default-deny-egress policy and forget to allow port 53 UDP+TCP, every DNS lookup inside the namespace silently fails. Pods that look healthy will hang or error on any hostname resolution.

**Concepts**
- DNS uses port 53, both **UDP** (normal queries) and **TCP** (large responses / zone transfers)
- `kube-dns` / `CoreDNS` runs in `kube-system`; you need a `namespaceSelector` targeting that namespace
- You must specify **two separate port entries** — one UDP, one TCP — because `protocol` defaults to TCP only

**Commands & examples**

```bash
# Allow DNS egress — always add this alongside any egress default-deny
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
EOF

# Verify DNS still works after applying deny-all
kubectl run test --image=busybox --restart=Never --rm -it -n prod -- nslookup kubernetes.default
```

**⚠️ Exam tips:**
- Forgetting port 53 will break the task silently — your app pod will fail even if the NetworkPolicy rules look correct
- Always write the DNS-allow policy FIRST, then the deny-all, to avoid locking yourself out mid-task
- `kubernetes.io/metadata.name` is automatically set on all namespaces in modern Kubernetes — use it instead of custom labels

---

## NetworkPolicy: Blocking Cloud Metadata Endpoint (169.254.169.254)

**Why it matters:** On cloud nodes (AWS, GCP, Azure) the instance metadata API is reachable at 169.254.169.254. A compromised pod can harvest IAM credentials from it. Blocking this via `ipBlock` is a standard CKS hardening task.

**Concepts**
- `ipBlock` matches on CIDR; `except` carves out exclusions
- To block a single IP, use `/32` as the CIDR, then use `except` if you need to allow a sub-range
- Strategy: allow the broad CIDR **except** 169.254.169.254/32 — OR deny egress to that IP explicitly

**Commands & examples**

```bash
# Block egress to the metadata endpoint while allowing all other egress
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: block-metadata-endpoint
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.169.254/32
EOF

# If you already have a default-deny-egress, add a specific deny via ipBlock + no-to rule
# (easier approach: use the except pattern above in the allow-all rule)
```

**⚠️ Exam tips:**
- You cannot have a "deny" rule in NetworkPolicy — only allow rules. To block a specific IP, use `ipBlock` with `except` inside an allow-all-else rule
- Combine metadata blocking with the DNS-allow policy if you're writing egress rules from scratch

---

## CIS Benchmark & kube-bench

**Why it matters:** The CIS Kubernetes Benchmark defines secure configuration baselines for every cluster component. The CKS exam may ask you to run kube-bench, identify a FAIL, and remediate the corresponding flag in the right config file.

**Concepts**
- kube-bench tests: master (apiserver, scheduler, controller-manager, etcd), node (kubelet, proxy)
- FAIL items include the check ID (e.g. `1.2.9`), the expected setting, and remediation instructions
- Remediations are almost always a flag change in a manifest or a config file restart

**Commands & examples**

```bash
# Run kube-bench against master and node components
kube-bench run --targets master,node

# Run only the apiserver checks
kube-bench run --targets master --check 1.2

# Sample FAIL output:
# [FAIL] 1.2.9 Ensure that the --anonymous-auth argument is set to false
# Remediation: Edit the API server pod specification file
#   /etc/kubernetes/manifests/kube-apiserver.yaml
#   and set the below parameter:  --anonymous-auth=false

# Remediate: edit the flag in the static manifest
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Add: - --anonymous-auth=false  under spec.containers[0].command

# Watch the apiserver restart after editing
watch crictl ps | grep api
# Wait for STATUS=Running before proceeding

# Re-run to confirm PASS
kube-bench run --targets master --check 1.2.9

# kubelet config findings often require editing /var/lib/kubelet/config.yaml
# Example: set readOnlyPort: 0 (disables unauthenticated read-only port)
sudo vi /var/lib/kubelet/config.yaml
# Then restart kubelet:
sudo systemctl restart kubelet
```

**⚠️ Exam tips:**
- Check the kube-bench remediation text carefully — it tells you exactly which file and flag to change
- apiserver changes → edit the static pod manifest; kubelet changes → edit `/var/lib/kubelet/config.yaml` or `/etc/kubernetes/kubelet.conf` + restart kubelet
- etcd changes → edit `/etc/kubernetes/manifests/etcd.yaml`
- After editing a static pod manifest, wait for the pod to restart before re-running kube-bench — it takes 10–30 seconds

---

## Ingress TLS Termination

**Why it matters:** The exam may ask you to expose a service via Ingress with HTTPS. You need to create a TLS secret and reference it correctly — a missing or misnamed secret silently falls back to HTTP.

**Concepts**
- Secret type must be `kubernetes.io/tls` with keys `tls.crt` and `tls.key`
- The secret must be in the **same namespace** as the Ingress
- `spec.tls[].hosts` must match the hostname in `spec.rules[].host`
- The Ingress controller handles termination; backend sees plain HTTP

**Commands & examples**

```bash
# Generate a self-signed cert (one-liner for exam use)
openssl req -x509 -newkey rsa:4096 -keyout tls.key -out tls.crt -days 365 -nodes \
  -subj "/CN=myapp.example.com"

# Create the TLS secret
kubectl create secret tls myapp-tls \
  --cert=tls.crt \
  --key=tls.key \
  -n prod

# Verify the secret
kubectl get secret myapp-tls -n prod -o jsonpath='{.type}'
# Should print: kubernetes.io/tls

# Ingress referencing the TLS secret
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: prod
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-svc
            port:
              number: 80
EOF
```

**⚠️ Exam tips:**
- The `secretName` in `spec.tls` must exactly match the Secret name — typos silently break TLS
- Secret and Ingress must be in the same namespace
- `spec.tls[].hosts` is a list; it must include the hostname used in `spec.rules[].host`

---

## Verifying Platform Binaries (sha256 / sha512)

**Why it matters:** Supply chain integrity. If you download a binary (kubectl, kubeadm, a CNI plugin) you should verify it hasn't been tampered with. The CKS exam can ask you to check a running binary against a known checksum.

**Concepts**
- Kubernetes GitHub releases publish `.sha256` and `.sha512` checksum files alongside each binary
- `sha256sum` / `sha512sum` — standard Linux tools, output: `<hash>  <filename>`
- Compare the downloaded hash against the published hash; any mismatch = fail

**Commands & examples**

```bash
# Download kubectl and its checksum (example for v1.34.0)
curl -LO "https://dl.k8s.io/release/v1.34.0/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/v1.34.0/bin/linux/amd64/kubectl.sha256"

# Verify: the output should be "kubectl: OK"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# Alternative one-liner if the .sha256 file contains just the hash
SHA=$(cat kubectl.sha256)
sha256sum kubectl | awk '{print $1}' | diff - <(echo "$SHA")
# No output = match; any diff = tampered

# Check a running binary already on the system
sha256sum $(which kubectl)
# Compare manually against the published hash for that version

# Find the version of an installed binary first
kubectl version --client --short
```

**⚠️ Exam tips:**
- The exam will tell you the expected hash or provide the `.sha256` file — don't guess
- `sha256sum --check` expects the format `<hash>  <filename>` (two spaces) — the official `.sha256` files use this format
- If verifying a binary already installed, use `which kubectl` (or `which kubeadm`) to get the full path

---

## Minimizing GUI / Dashboard Exposure

**Why it matters:** The Kubernetes Dashboard has historically been a major attack vector (e.g., Tesla cryptomining incident). The CKS tests whether you know how to restrict it using RBAC — not how to use the dashboard itself.

**Concepts**
- Dashboard should never be accessible without authentication
- Anonymous access (`--enable-skip-login`, anonymous auth) must be disabled
- Dashboard ServiceAccount should have minimal RBAC — view-only at most, namespace-scoped
- Never bind `cluster-admin` to the dashboard ServiceAccount
- NodePort / LoadBalancer exposure should be replaced with port-forward or Ingress + auth

**Commands & examples**

```bash
# Check what the dashboard SA can do — look for over-permissioned bindings
kubectl get clusterrolebinding,rolebinding -A | grep dashboard

# Find any cluster-admin binding to a dashboard SA
kubectl get clusterrolebinding -o wide | grep -i dashboard

# Remove a dangerous binding (example)
kubectl delete clusterrolebinding kubernetes-dashboard

# Replace with a namespace-scoped view-only role
kubectl create rolebinding dashboard-view \
  --clusterrole=view \
  --serviceaccount=kubernetes-dashboard:kubernetes-dashboard \
  -n kubernetes-dashboard

# Verify the SA cannot do harmful things
kubectl auth can-i list secrets \
  --as=system:serviceaccount:kubernetes-dashboard:kubernetes-dashboard \
  -n default
# Should print: no

# Check if anonymous auth is enabled on the dashboard deployment
kubectl get deploy kubernetes-dashboard -n kubernetes-dashboard -o yaml | grep -i skip
# Look for --enable-skip-login; remove it if present
```

**⚠️ Exam tips:**
- The ask is usually: remove a cluster-admin binding from the dashboard SA, or patch the deployment to remove `--enable-skip-login`
- Deleting a ClusterRoleBinding is permanent and immediate — double-check the name before deleting

---

## Quick Command Reference

```bash
# NetworkPolicy: verify what policies exist in a namespace
kubectl get netpol -n prod

# NetworkPolicy: describe to see pod/namespace selectors
kubectl describe netpol default-deny-all -n prod

# kube-bench: run all checks, save output
kube-bench run --targets master,node 2>&1 | tee /tmp/kube-bench.txt
grep FAIL /tmp/kube-bench.txt

# kube-bench: run a specific check by ID
kube-bench run --check 1.2.9

# TLS secret: quick create
kubectl create secret tls <name> --cert=tls.crt --key=tls.key -n <ns>

# Verify binary hash
echo "$(cat file.sha256)  binary" | sha256sum --check

# Dashboard: audit SA bindings
kubectl get clusterrolebinding -o wide | grep -i dashboard
kubectl auth can-i list secrets --as=system:serviceaccount:<ns>:<sa>
```

## Docs to Bookmark
- [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [NetworkPolicy API reference](https://kubernetes.io/docs/reference/kubernetes-api/policy-resources/network-policy-v1/)
- [kube-bench](https://github.com/aquasecurity/kube-bench)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [Ingress TLS](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls)
- [Verify kubectl binary](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#verify-kubectl-binary)
- [Kubernetes Dashboard access control](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/#accessing-the-dashboard-ui)
