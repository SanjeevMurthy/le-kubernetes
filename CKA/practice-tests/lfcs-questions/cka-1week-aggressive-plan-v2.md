# CKA Retake: Aggressive 1-Week Study Plan (Updated)

## Your 7 Missed Questions — Complete Picture

| # | Question | Domain | Weight |
|---|---|---|---|
| 1 | Install containerd from dpkg and configure it | Cluster Architecture (25%) | 🔴 |
| 2 | Troubleshoot failed cluster — kubelet down, crictl, kube-apiserver logs | Troubleshooting (30%) | 🔴 |
| 3 | Install CNI plugin (Calico/Flannel), verify pod IPs | Cluster Architecture (25%) | 🔴 |
| 4 | Helm install ArgoCD and verify | Workloads & Scheduling (15%) | 🟡 |
| 5 | Replace Ingress (with TLS secret) using Gateway + HTTPRoute | Services & Networking (20%) | 🔴 |
| 6 | List cert-manager CRDs, find subject from Certificates CRD, write to file | Cluster Architecture (25%) | 🟡 |
| 7 | RBAC for custom resources (students, classes) — create Role/RoleBinding for custom objects | Cluster Architecture (25%) | 🟡 |

These 7 questions could represent **~30-40% of your total score**. Nailing all of them on retake = comfortably past 66%.

### Confirmed by Other Exam Takers

Your questions 6 and 7 are well-documented by people who've taken the updated CKA:

- Multiple candidates report seeing the exact cert-manager CRD question: list CRDs with a keyword filter, then use `kubectl explain` to extract the `spec.subject` field documentation from the Certificate CRD and save to a file
- The CRD + RBAC combination tests whether you understand that custom resources follow the same RBAC model as native resources — you use the CRD's `plural` name as the `resource` in a Role
- One candidate who passed with 84% specifically mentioned "List all CRDs matching a keyword (cert-manager) and write them into a file" as one of their 16 questions
- "cert-manager CRDs" is consistently cited alongside HPA, Helm, ArgoCD, and Gateway API as a common topic in the post-Feb 2025 exam

---

## The Strategy

You scored 64% with solid knowledge of the broader syllabus. This week is about drilling these 7 question patterns until they're muscle memory. Each day targets specific question types with deep hands-on practice.

**Daily commitment:** 3-4 hours focused practice
**Weekend:** 5-6 hours including a full mock exam

---

## Day 1 (Monday): Containerd dpkg + CRD Exploration (Questions 1 & 6)

### Morning: Containerd Installation from dpkg (1.5 hours)

**Drill this sequence until you can do it without looking:**

```bash
# Step 1: Install containerd package via dpkg
sudo dpkg -i containerd.io_<version>_amd64.deb
# If dependencies are missing:
sudo apt-get install -f

# Step 2: Generate default config
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Step 3: Enable SystemdCgroup (THE critical step)
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
# The setting lives under:
# [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]

# Step 4: Reload and start
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# Step 5: Verify
sudo systemctl status containerd
crictl info
crictl version
```

**Also practice:**
- Pre-requisites: loading kernel modules (`overlay`, `br_netfilter`), sysctl settings
- Installing runc binary manually
- Configuring crictl: `/etc/crictl.yaml`
- Key docs: https://kubernetes.io/docs/setup/production-environment/container-runtimes/

### Afternoon: CRD Exploration — cert-manager Question (2 hours)

**What the exam expects (Question 6):**

The exam has cert-manager pre-installed. You need to:
1. List all cert-manager CRDs and save to a file
2. Use `kubectl explain` to extract the `spec.subject` field docs from the Certificate CRD and save to another file

**IMPORTANT:** The exam says "use kubectl's default output format" and "do not set an output format" — this means DON'T use `-o yaml` or `-o json`. Just use the plain default output.

**Step-by-step solution:**

```bash
# Part 1: List all cert-manager CRDs and save to file
# Method 1: grep for cert-manager in CRD names
kubectl get crd | grep cert-manager > /path/to/cert-manager-crds.txt

# Method 2: If they want ONLY the CRD list (no header)
kubectl get crd | grep cert-manager

# The output will look something like:
# certificaterequests.cert-manager.io     2024-01-15T10:00:00Z
# certificates.cert-manager.io            2024-01-15T10:00:00Z
# challenges.acme.cert-manager.io         2024-01-15T10:00:00Z
# clusterissuers.cert-manager.io          2024-01-15T10:00:00Z
# issuers.cert-manager.io                 2024-01-15T10:00:00Z
# orders.acme.cert-manager.io             2024-01-15T10:00:00Z

# Part 2: Extract the spec.subject documentation from Certificate CRD
# First, find the correct CRD name:
kubectl get crd | grep certificates
# → certificates.cert-manager.io

# Use kubectl explain to get the subject field documentation
kubectl explain certificates.spec.subject > ~/subject.yaml

# The output will contain the field description, type, and sub-fields
# If "certificates" doesn't work directly, try the full resource name:
kubectl explain certificate.spec.subject > ~/subject.yaml
```

**Key `kubectl explain` patterns to master:**

```bash
# Basic explain
kubectl explain pod.spec.containers

# Recursive (show all nested fields)
kubectl explain pod.spec --recursive

# For CRDs — use the resource kind (lowercase) or plural name
kubectl explain certificates                       # Top level
kubectl explain certificates.spec                  # spec fields
kubectl explain certificates.spec.subject          # specific nested field
kubectl explain certificates.spec.subject --recursive  # all sub-fields

# If you're unsure of the resource name, find it via:
kubectl api-resources | grep cert-manager
# This shows: NAME, SHORTNAMES, APIVERSION, NAMESPACED, KIND
```

**Practice drill:**
1. Install cert-manager on a practice cluster: `kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml`
2. Wait for pods: `kubectl get pods -n cert-manager`
3. List CRDs: `kubectl get crd | grep cert-manager`
4. Explore: `kubectl explain certificates.spec.subject`
5. Try other fields: `kubectl explain certificates.spec.issuerRef`, `kubectl explain certificates.spec.secretName`
6. Save output to file and verify it's correct

---

## Day 2 (Tuesday): Troubleshooting + RBAC for Custom Resources (Questions 2 & 7)

### Morning: Cluster Troubleshooting (2 hours)

**Build this debugging flowchart (memorize it):**

```
Can't access cluster via kubectl?
│
├─→ Is kubelet running?
│   $ systemctl status kubelet
│   $ journalctl -u kubelet --no-pager -l | tail -50
│   │
│   ├─→ kubelet NOT running → check config paths, runtime endpoint, certs
│   │   Fix → systemctl daemon-reload → systemctl restart kubelet
│   │
│   └─→ kubelet IS running but cluster broken
│       $ crictl ps -a  (are control plane containers running?)
│       $ crictl logs <container-id>
│
├─→ Is kube-apiserver running?
│   $ crictl ps -a | grep apiserver
│   $ crictl logs <container-id>
│   Common: wrong etcd endpoint, wrong cert paths, port conflict
│   Fix → edit /etc/kubernetes/manifests/kube-apiserver.yaml
│
└─→ Is etcd running?
    $ crictl ps -a | grep etcd
    Common: wrong data-dir, wrong peer URLs
```

**Break-fix scenarios to practice today:**

| Break This | How to Fix |
|---|---|
| Wrong `--etcd-servers` in kube-apiserver manifest | `crictl logs`, fix manifest |
| Renamed kubelet config file | `journalctl -u kubelet`, restore file |
| Wrong container runtime socket in kubelet | Fix socket path, restart kubelet |
| Deleted apiserver cert | `kubeadm init phase certs apiserver` |
| Stopped containerd on worker | `systemctl start containerd` |

**Do at least 4 break-fix scenarios. Time yourself: <8 min each.**

### Afternoon: RBAC for Custom Resources (2 hours)

**What the exam expects (Question 7):**

CRDs are already installed (e.g., `students.school.example.com`, `classes.school.example.com`). You need to create RBAC rules (Role + RoleBinding or ClusterRole + ClusterRoleBinding) that allow a user or ServiceAccount to create/manage these custom resources.

**The key insight:** Custom resources follow the exact same RBAC model as native resources. The `resource` field in a Role uses the **plural name** from the CRD, and the `apiGroups` field uses the CRD's API group.

**Step-by-step approach:**

```bash
# Step 1: Discover the CRDs and their details
kubectl get crd
# Example output:
# students.school.example.com    2024-01-15T10:00:00Z
# classes.school.example.com     2024-01-15T10:00:00Z

# Step 2: Find the API group and resource names
kubectl api-resources | grep -E "students|classes"
# Example output:
# NAME       SHORTNAMES   APIVERSION              NAMESPACED   KIND
# students                school.example.com/v1   true         Student
# classes                 school.example.com/v1   true         Class

# The key info you need:
# - resource name (plural): students, classes
# - apiGroup: school.example.com
# - namespaced: true (so use Role, not ClusterRole)

# Step 3: Create a Role that grants permissions for custom resources
kubectl create role school-admin \
  --verb=get,list,create,update,delete \
  --resource=students.school.example.com \
  --resource=classes.school.example.com \
  --dry-run=client -o yaml > role.yaml
```

**If the imperative command doesn't work cleanly with CRD resources, use YAML:**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: school-admin
  namespace: default          # or whatever namespace is specified
rules:
- apiGroups: ["school.example.com"]    # API group from the CRD
  resources: ["students", "classes"]    # plural names from the CRD
  verbs: ["get", "list", "create", "update", "delete"]
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: school-admin-binding
  namespace: default
subjects:
- kind: User                            # or ServiceAccount
  name: jane                            # username from the question
  apiGroup: rbac.authorization.k8s.io
# For ServiceAccount:
# - kind: ServiceAccount
#   name: sa-name
#   namespace: default
roleRef:
  kind: Role
  name: school-admin
  apiGroup: rbac.authorization.k8s.io
```

**Verification:**
```bash
# Verify the RBAC is working
kubectl auth can-i create students --as=jane
# → yes

kubectl auth can-i delete classes --as=jane
# → yes

kubectl auth can-i create pods --as=jane
# → no (only custom resources were granted)
```

**The RBAC + CRD mapping cheat sheet:**

| CRD Field | Where It Goes in RBAC |
|---|---|
| `spec.group` (e.g., `school.example.com`) | Role `rules[].apiGroups[]` |
| `spec.names.plural` (e.g., `students`) | Role `rules[].resources[]` |
| `spec.names.kind` (e.g., `Student`) | NOT used in Role (kind is for kubectl, not RBAC) |
| `spec.scope: Namespaced` | Use Role + RoleBinding |
| `spec.scope: Cluster` | Use ClusterRole + ClusterRoleBinding |

**Practice drill:**
1. Create a CRD for a custom resource (e.g., `crontabs.stable.example.com`) — use the Kubernetes docs example
2. Create custom resource instances
3. Create a Role that only allows `get` and `list` on that custom resource
4. Create a RoleBinding for a ServiceAccount
5. Verify with `kubectl auth can-i`
6. Try creating the resource as the ServiceAccount: `kubectl get crontabs --as=system:serviceaccount:default:mysa`

---

## Day 3 (Wednesday): CNI Plugin + Gateway API with TLS (Questions 3 & 5)

### Morning: CNI Installation (1.5 hours)

**Calico:**
```bash
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
# Verify CALICO_IPV4POOL_CIDR matches --pod-network-cidr
kubectl apply -f calico.yaml

# Verify
kubectl get pods -n kube-system -l k8s-app=calico-node
kubectl get nodes            # Should be Ready
kubectl run test --image=nginx && kubectl get pod test -o wide  # Gets IP
```

**Flannel:**
```bash
# Requires --pod-network-cidr=10.244.0.0/16 during kubeadm init
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl get pods -n kube-flannel
```

**Key paths:** CNI binaries: `/opt/cni/bin/`, CNI config: `/etc/cni/net.d/`

### Afternoon: Gateway API + TLS replacing Ingress (2.5 hours)

**The conversion pattern — Ingress with TLS → Gateway API:**

Given this Ingress:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-app
spec:
  tls:
  - hosts:
    - secure.example.com
    secretName: tls-secret
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

Replace with:

**1. GatewayClass** (check if it already exists: `kubectl get gatewayclass`):
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: example-gateway-class
spec:
  controllerName: example.com/gateway-controller
```

**2. Gateway** (TLS config goes HERE):
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: secure-gateway
spec:
  gatewayClassName: example-gateway-class
  listeners:
  - name: https
    port: 443
    protocol: HTTPS
    hostname: "secure.example.com"
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: tls-secret               # ← same secret from Ingress
    allowedRoutes:
      kinds:
      - kind: HTTPRoute
```

**3. HTTPRoute** (routing rules):
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: secure-app-route
spec:
  parentRefs:
  - name: secure-gateway
  hostnames:
  - "secure.example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: my-service
      port: 80
```

**Key rule:** TLS secret goes in **Gateway** listeners, NOT in HTTPRoute.

**Exam-allowed docs:** https://gateway-api.sigs.k8s.io and https://gateway-api.sigs.k8s.io/guides/tls/

**Practice:** Write the conversion from memory 3 times. Verify with `kubectl get gateway` and `kubectl describe gateway`.

---

## Day 4 (Thursday): Helm + ArgoCD & Combined Timed Drills (Question 4 + All)

### Morning: Helm Workflows (1.5 hours)

```bash
# ArgoCD install
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd -n argocd --create-namespace

# With custom values
helm install argocd argo/argo-cd -n argocd --create-namespace \
  --set server.service.type=NodePort

# Verify
helm list -n argocd
kubectl get pods -n argocd
kubectl get svc -n argocd

# Other essential Helm commands
helm search repo argo
helm show values argo/argo-cd
helm upgrade argocd argo/argo-cd -n argocd
helm rollback argocd 1 -n argocd
helm history argocd -n argocd
helm uninstall argocd -n argocd
```

### Afternoon: Combined Timed Drill — All 7 Questions (2.5 hours)

Run through all 7 questions back-to-back, timed:

| Question | Target Time |
|---|---|
| 1. Install containerd via dpkg | 8 min |
| 2. Troubleshoot broken cluster (kubelet + apiserver) | 10 min |
| 3. Install CNI plugin + verify pod IPs | 5 min |
| 4. Helm install ArgoCD + verify | 5 min |
| 5. Replace Ingress with Gateway + HTTPRoute (TLS) | 10 min |
| 6. List cert-manager CRDs + explain subject to file | 4 min |
| 7. RBAC for custom resources (students, classes) | 6 min |
| **Total** | **48 min** |

The real exam gives ~7 min per question on average. If you can do all 7 in under 50 minutes, you're in excellent shape — that leaves 70+ minutes for the other 9-10 questions you already know.

---

## Day 5 (Friday): Killer.sh Mock Exam

### Full Simulation (2 hours + 1 hour review)

- Complete Killer.sh practice exam under real conditions
- No breaks, no external resources beyond allowed docs
- Set up aliases first

### Post-Exam Review
- Categorize mistakes: knowledge gap, speed issue, or silly mistake?
- Note any CRD/RBAC questions in the simulation — compare with your drilling
- If you scored 75%+ on Killer.sh, you're ready (it's harder than the real exam)

---

## Day 6 (Saturday): Targeted Remediation + Speed Drills

### Morning: Fix Killer.sh Gaps (2-3 hours)
- Revisit any topics you struggled with
- Re-practice any of the 7 questions that felt shaky

### Afternoon: Speed Optimization (2-3 hours)

**Exam setup script (paste this at the START):**
```bash
alias k=kubectl
alias kgp='kubectl get pods -A'
alias kgn='kubectl get nodes'
alias kgs='kubectl get svc'
alias kd='kubectl describe'
alias kaf='kubectl apply -f'
export do='--dry-run=client -o yaml'
export now='--force --grace-period=0'
source <(kubectl completion bash)
complete -o default -F __start_kubectl k
```

**Key `kubectl explain` patterns for CRD questions:**
```bash
# When you don't know the resource name
kubectl api-resources | grep <keyword>
kubectl api-resources --api-group=cert-manager.io

# Explore CRD structure
kubectl explain <resource>.spec
kubectl explain <resource>.spec.<field>
kubectl explain <resource>.spec --recursive

# Save to file
kubectl explain certificates.spec.subject > ~/subject.yaml
```

**Key imperative RBAC commands:**
```bash
# Create role for native resources
k create role pod-reader --verb=get,list --resource=pods $do > role.yaml

# Create role for CRD resources (specify full resource.apigroup)
k create role custom-admin \
  --verb=get,list,create,update,delete \
  --resource=students.school.example.com $do > role.yaml

# Create rolebinding
k create rolebinding custom-binding \
  --role=custom-admin \
  --user=jane $do > rb.yaml

# Verify
k auth can-i create students --as=jane
k auth can-i list classes --as=jane -n <namespace>
```

### Evening: Final 7-question drill one more time
All 7 questions, timed. Target: under 45 minutes total.

---

## Day 7 (Sunday): Final Review + Rest

### Morning: Light Review (1-2 hours max)
- Review your cheat sheet cards one final time
- Confirm docs bookmarks are organized:
  - https://kubernetes.io/docs/setup/production-environment/container-runtimes/
  - https://kubernetes.io/docs/tasks/debug/debug-cluster/
  - https://kubernetes.io/docs/reference/kubectl/cheatsheet/
  - https://kubernetes.io/docs/reference/access-authn-authz/rbac/
  - https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
  - https://gateway-api.sigs.k8s.io/guides/tls/

### Afternoon: REST
- No studying after lunch
- Get good sleep

---

## Quick Reference Cards

### Card 1: Containerd dpkg Install
```
dpkg -i containerd.io_*.deb
→ mkdir -p /etc/containerd
→ containerd config default > /etc/containerd/config.toml
→ sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
→ systemctl daemon-reload && systemctl enable --now containerd
→ crictl info
```

### Card 2: Troubleshooting Broken Cluster
```
systemctl status kubelet → journalctl -u kubelet
→ crictl ps -a → crictl logs <id>
→ check /etc/kubernetes/manifests/
→ fix config → systemctl restart kubelet
```

### Card 3: CNI Install
```
Calico: kubectl apply -f calico.yaml (match CALICO_IPV4POOL_CIDR to pod CIDR)
Flannel: kubectl apply -f kube-flannel.yml (requires 10.244.0.0/16)
Verify: kubectl get nodes (Ready) + run test pod (gets IP)
```

### Card 4: Helm + ArgoCD
```
helm repo add argo https://argoproj.github.io/argo-helm && helm repo update
→ helm install argocd argo/argo-cd -n argocd --create-namespace
→ helm list -n argocd && kubectl get pods -n argocd
```

### Card 5: Ingress → Gateway API with TLS
```
GatewayClass (check: kubectl get gatewayclass)
→ Gateway: listeners[].tls.mode=Terminate, certificateRefs[].name=<tls-secret>
→ HTTPRoute: parentRefs → gateway, hostnames, rules → matches + backendRefs
Key: TLS secret goes in Gateway, NOT HTTPRoute
```

### Card 6: cert-manager CRD Exploration
```
kubectl get crd | grep cert-manager > /path/to/file.txt
→ kubectl explain certificates.spec.subject > ~/subject.yaml
WARNING: Use DEFAULT output format. Do NOT add -o yaml or -o json.
Tip: kubectl api-resources | grep cert-manager (find resource names)
```

### Card 7: RBAC for Custom Resources
```
kubectl api-resources | grep <custom-resource>  (find apiGroup + plural name)
→ Role: apiGroups=["<crd-api-group>"], resources=["<plural-name>"], verbs=[...]
→ RoleBinding: bind to User or ServiceAccount
→ Verify: kubectl auth can-i create <resource> --as=<user>
Key: Use CRD's spec.group as apiGroups, spec.names.plural as resources
```

---

## Exam Day Strategy

1. **First 30 seconds:** Set up aliases + autocompletion
2. **Context switching:** `kubectl config use-context <context>` at the START of EVERY question
3. **Triage:** Quick scan all questions, do confident ones first, flag the rest
4. **CRD questions are free points:** `kubectl get crd | grep`, `kubectl explain` — these are fast if you know the pattern
5. **Don't get stuck on troubleshooting:** Follow the flowchart systematically, max 10 min
6. **Verify everything:** `kubectl get pods`, `kubectl auth can-i`, `helm list`

---

*You were 2% away. These 7 questions are your clear path. Every single one follows a predictable pattern that you can drill. Trust the preparation, trust your existing knowledge, and go claim that CKA.*
