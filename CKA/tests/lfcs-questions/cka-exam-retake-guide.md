# CKA Master Revision Guide — Exam Retake Edition

> **Purpose:** This guide covers every question from your first CKA attempt with verified solutions, imperative shortcuts, declarative YAML, verification steps, and official doc links. Grouped by CKA exam domain.

## Table of Contents

### Domain 1: Cluster Architecture, Installation & Configuration (25%)

1. [Q1 — Install containerd from .deb Package](#q1--install-containerd-from-deb-package)
2. [Q2 — Install CNI Plugin (Calico) with NetworkPolicy Support](#q2--install-cni-plugin-calico-with-networkpolicy-support)
3. [Q3 — List cert-manager CRDs and Extract Field Documentation](#q3--list-cert-manager-crds-and-extract-field-documentation)
4. [Q4 — RBAC for Custom Resources (CRDs)](#q4--rbac-for-custom-resources-crds)

### Domain 2: Workloads & Scheduling (15%)

5. [Q5 — Create a Horizontal Pod Autoscaler (HPA)](#q5--create-a-horizontal-pod-autoscaler-hpa)
6. [Q6 — Create a PriorityClass](#q6--create-a-priorityclass)
7. [Q7 — Fix Pending Pods by Adjusting Resource Requests](#q7--fix-pending-pods-by-adjusting-resource-requests)
8. [Q8 — Add a Sidecar Log Container to an Existing Deployment](#q8--add-a-sidecar-log-container-to-an-existing-deployment)
9. [Q9 — Helm Template and Install with Custom Values](#q9--helm-template-and-install-with-custom-values)

### Domain 3: Services & Networking (20%)

10. [Q10 — Expose a Deployment Using a NodePort Service](#q10--expose-a-deployment-using-a-nodeport-service)
11. [Q11 — Create an Ingress Resource](#q11--create-an-ingress-resource)
12. [Q12 — Replace Ingress with Gateway API (TLS) + HTTPRoute](#q12--replace-ingress-with-gateway-api-tls--httproute)
13. [Q13 — Select and Apply the Correct NetworkPolicy](#q13--select-and-apply-the-correct-networkpolicy)
14. [Q14 — Update NGINX ConfigMap to Enable TLSv1.2](#q14--update-nginx-configmap-to-enable-tlsv12)

### Domain 4: Storage (10%)

15. [Q15 — Create a StorageClass](#q15--create-a-storageclass)
16. [Q16 — Create a PVC to Bind an Existing PV, Then Attach to a Pod](#q16--create-a-pvc-to-bind-an-existing-pv-then-attach-to-a-pod)

### Domain 5: Troubleshooting (30%)

17. [Q17 — Fix Broken Cluster: kube-apiserver and kube-scheduler Down](#q17--fix-broken-cluster-kube-apiserver-and-kube-scheduler-down)
18. [Q18 — Troubleshoot a Completely Failed Cluster (kubelet down)](#q18--troubleshoot-a-completely-failed-cluster-kubelet-down)

---

## Exam Setup — Paste First

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

---

# DOMAIN 1: Cluster Architecture, Installation & Configuration (25%)

---

### Q1 — Install containerd from .deb Package

**Problem:** Install the `containerd` container runtime from a provided `.deb` package using `dpkg -i`. Configure it properly (enable `SystemdCgroup`) and start the service.

**Reference Doc:** https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd

**Solution Steps:**

1. Pre-requisite kernel modules and sysctl (if not already done):

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

2. Install the .deb package:

```bash
sudo dpkg -i containerd.io_<version>_amd64.deb
# If dependency errors occur:
sudo apt-get install -f
```

3. Generate default config and enable SystemdCgroup:

```bash
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# CRITICAL: Enable SystemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
```

> **WARNING:** The `SystemdCgroup = true` setting lives under `[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]`. If `sed` doesn't match, open the file manually and find that section.

4. Start and enable containerd:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
```

**Verification:**

```bash
sudo systemctl status containerd    # Should be active (running)
crictl info                          # Should return runtime info
crictl version                       # Should show containerd version
```

---

### Q2 — Install CNI Plugin (Calico) with NetworkPolicy Support

**Problem:** The cluster's CNI failed a security audit and was removed. Install a new CNI that supports enforcing NetworkPolicies. Two options given: Flannel v0.26.1 and Calico v3.28.2.

**Reference Doc:** https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy

**Key Decision:** Choose **Calico** — it natively supports NetworkPolicies. Flannel does **not**.

**Solution Steps:**

1. Determine the cluster's Pod CIDR (needed for Calico configuration):

```bash
kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}'
# OR check kubeadm config:
kubectl -n kube-system get cm kubeadm-config -o yaml | grep podSubnet
```

2. Install the Calico operator:

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml
```

3. Download and configure the custom resources (set PodCIDR):

```bash
# The custom-resources.yaml is in the same directory as the operator manifest
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/custom-resources.yaml
```

Edit `custom-resources.yaml` to match your cluster's Pod CIDR:

```yaml
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
      - blockSize: 26
        cidr: 192.168.0.0/16 # ← Change this to match your cluster's podCIDR
        encapsulation: VXLANCrossSubnet
        natOutgoing: Enabled
        nodeSelector: all()
```

```bash
kubectl apply -f custom-resources.yaml
```

> **WARNING:** If `kubectl apply -f tigera-operator.yaml` throws errors, wait 10-15 seconds and retry. The CRDs need time to register. If errors persist, try `kubectl create -f` instead of `apply`.

**Verification:**

```bash
kubectl get pods -n tigera-operator          # tigera-operator should be Running
kubectl get pods -n calico-system            # calico-node, calico-kube-controllers should be Running
kubectl get nodes                            # All nodes should be Ready
# Test pod gets an IP:
kubectl run test-cni --image=nginx --restart=Never
kubectl get pod test-cni -o wide             # Should have an IP in the Pod CIDR range
kubectl delete pod test-cni --force --grace-period=0
```

---

### Q3 — List cert-manager CRDs and Extract Field Documentation

**Problem:** cert-manager is deployed. (a) List all cert-manager CRDs and save to `~/resources.yaml` using kubectl's **default output format** (no `-o yaml` or `-o json`). (b) Extract the documentation for the `subject` field of the Certificate CRD's spec and save to `~/subject.yaml`.

**Reference Doc:** https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#viewing-crds

**Solution Steps:**

1. List all cert-manager CRDs and save (default format — no `-o` flag):

```bash
# Method 1: grep and redirect (preserves default table output)
kubectl get crds | grep cert-manager > ~/resources.yaml

# Method 2: If they want full CRD details per resource
kubectl get crds | grep cert-manager | awk '{print $1}' | xargs kubectl get crd > ~/resources.yaml
```

> **CRITICAL WARNING:** The question explicitly says "use kubectl's default output format" and "do not set an output format." Adding `-o yaml` or `-o json` will lose you points.

2. Extract the `spec.subject` field documentation:

```bash
kubectl explain certificates.spec.subject > ~/subject.yaml
# If "certificates" doesn't work, try "certificate" (singular):
kubectl explain certificate.spec.subject > ~/subject.yaml
```

3. If unsure of the resource name:

```bash
kubectl api-resources | grep cert-manager
# Look for KIND=Certificate, NAME=certificates
```

**Verification:**

```bash
cat ~/resources.yaml     # Should list cert-manager CRDs in table format
cat ~/subject.yaml       # Should show GROUP, VERSION, KIND, FIELD, DESCRIPTION for spec.subject
```

---

### Q4 — RBAC for Custom Resources (CRDs)

**Problem:** CRDs are already installed for custom objects (e.g., `students` and `classes`). Create a Role and RoleBinding that grants a user permission to create/manage these custom resources.

**Reference Doc:** https://kubernetes.io/docs/reference/access-authn-authz/rbac/

**Solution Steps:**

1. Discover the CRD details:

```bash
kubectl get crd | grep -E "students|classes"
# e.g., students.school.example.com, classes.school.example.com

kubectl api-resources | grep -E "students|classes"
# Find: plural name, apiGroup, whether namespaced
# e.g.: students   school.example.com/v1   true   Student
```

2. Create the Role imperatively:

```bash
kubectl create role school-admin \
  --verb=get,list,create,update,delete \
  --resource=students.school.example.com \
  --resource=classes.school.example.com \
  -n <namespace> $do > role.yaml

kubectl apply -f role.yaml
```

3. Or declaratively:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: school-admin
  namespace: default # use the namespace from the question
rules:
  - apiGroups: ["school.example.com"] # CRD's spec.group
    resources: ["students", "classes"] # CRD's spec.names.plural
    verbs: ["get", "list", "create", "update", "delete"]
```

4. Create the RoleBinding:

```bash
kubectl create rolebinding school-admin-binding \
  --role=school-admin \
  --user=jane \
  -n <namespace>
```

Or for a ServiceAccount:

```bash
kubectl create rolebinding school-admin-binding \
  --role=school-admin \
  --serviceaccount=<namespace>:<sa-name> \
  -n <namespace>
```

**Mapping Cheat Sheet:**

| CRD Field                                 | RBAC Field                           |
| ----------------------------------------- | ------------------------------------ |
| `spec.group` (e.g., `school.example.com`) | `rules[].apiGroups[]`                |
| `spec.names.plural` (e.g., `students`)    | `rules[].resources[]`                |
| `spec.scope: Namespaced`                  | Use Role + RoleBinding               |
| `spec.scope: Cluster`                     | Use ClusterRole + ClusterRoleBinding |

**Verification:**

```bash
kubectl auth can-i create students --as=jane -n <namespace>     # → yes
kubectl auth can-i delete classes --as=jane -n <namespace>      # → yes
kubectl auth can-i create pods --as=jane -n <namespace>         # → no
```

---

# DOMAIN 2: Workloads & Scheduling (15%)

---

### Q5 — Create a Horizontal Pod Autoscaler (HPA)

**Problem:** Create an HPA for an existing deployment with specified min/max replicas and CPU utilization target.

**Reference Doc:** https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/

**Imperative Command (fastest):**

```bash
kubectl autoscale deployment <deployment-name> \
  --min=2 \
  --max=10 \
  --cpu-percent=50 \
  -n <namespace>
```

**Declarative YAML:**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: <hpa-name>
  namespace: <namespace>
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: <deployment-name>
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

> **WARNING:** The deployment's containers **must** have `resources.requests.cpu` set for HPA to work.

**Verification:**

```bash
kubectl get hpa -n <namespace>
kubectl describe hpa <hpa-name> -n <namespace>
# TARGETS column should show current/target (e.g., 10%/50%)
# If it shows <unknown>/50%, the deployment lacks CPU requests
```

---

### Q6 — Create a PriorityClass

**Problem:** Create a PriorityClass with specific properties, modifying from an existing user-defined PriorityClass.

**Reference Doc:** https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#priorityclass

**Solution Steps:**

1. Inspect the existing PriorityClass:

```bash
kubectl get priorityclasses
kubectl get priorityclass <existing-name> -o yaml
```

2. Create a new PriorityClass (declarative):

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: <new-priority-class-name>
value: 1000000 # Adjust as specified
globalDefault: false # Only one can be true cluster-wide
preemptionPolicy: PreemptLowerPriority # or "Never"
description: "Custom priority class for critical workloads"
```

```bash
kubectl apply -f priorityclass.yaml
```

> **Key fields to modify:** `value` (integer), `globalDefault` (bool), `preemptionPolicy` (`PreemptLowerPriority` or `Never`).

**Verification:**

```bash
kubectl get priorityclasses
kubectl describe priorityclass <new-priority-class-name>
```

---

### Q7 — Fix Pending Pods by Adjusting Resource Requests

**Problem:** A deployment with 3 replicas has pods stuck in Pending because container resource requests exceed node capacity. Check node resources, then divide CPU/memory equally among containers, leaving overhead for system components.

**Reference Doc:** https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

**Solution Steps:**

1. Check why pods are pending:

```bash
kubectl get pods -n <namespace>
kubectl describe pod <pending-pod> -n <namespace>
# Look for: "Insufficient cpu" or "Insufficient memory" in Events
```

2. Check available node resources:

```bash
kubectl describe node <node-name> | grep -A 5 "Allocatable"
# Note the Allocatable CPU and Memory

kubectl describe node <node-name> | grep -A 20 "Allocated resources"
# See what's already consumed
```

3. Calculate per-container resources:

```
Available = Allocatable - Already_Used - System_Overhead_Buffer
Per_Replica = Available / number_of_replicas
Per_Container = Per_Replica / containers_per_pod
```

> **Tip:** Leave ~10-15% overhead for system components (kubelet, kube-proxy, etc.). For example, if a node has 2000m CPU allocatable and you need 3 replicas with 1 container each, set requests to ~550m-600m CPU per container.

4. Edit the deployment:

```bash
kubectl edit deployment <deployment-name> -n <namespace>
# Or export and edit:
kubectl get deployment <deployment-name> -n <namespace> -o yaml > dep.yaml
# Edit resources.requests in dep.yaml
kubectl apply -f dep.yaml
```

Update the container resources section:

```yaml
resources:
  requests:
    cpu: "500m" # Calculated value
    memory: "256Mi" # Calculated value
  limits:
    cpu: "500m"
    memory: "256Mi"
```

**Verification:**

```bash
kubectl get pods -n <namespace>
# All 3 replicas should be Running, none Pending
kubectl describe pod <pod-name> -n <namespace> | grep -A 3 "Requests"
```

---

### Q8 — Add a Sidecar Log Container to an Existing Deployment

**Problem:** Add a sidecar container to an existing deployment that reads logs from a shared volume (emptyDir).

**Reference Doc:** https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/

**Solution Steps:**

1. Export the existing deployment:

```bash
kubectl get deployment <deployment-name> -n <namespace> -o yaml > deployment.yaml
```

2. Edit `deployment.yaml` — add a shared `emptyDir` volume and the sidecar container:

```yaml
spec:
  template:
    spec:
      containers:
        - name: main-app # Existing container
          # ... existing config ...
          volumeMounts:
            - name: log-volume
              mountPath: /var/log/app # Where app writes logs
        - name: sidecar-logger # NEW sidecar container
          image: busybox:1.36
          command: ["sh", "-c", "tail -f /var/log/app/app.log"]
          volumeMounts:
            - name: log-volume
              mountPath: /var/log/app # Same path to read logs
      volumes:
        - name: log-volume
          emptyDir: {} # Shared between containers
```

3. Apply:

```bash
kubectl apply -f deployment.yaml
```

**Verification:**

```bash
kubectl get pods -n <namespace>
# Pods should show 2/2 READY (main + sidecar)
kubectl logs <pod-name> -c sidecar-logger -n <namespace>
# Should show log output from the main application
```

---

### Q9 — Helm Template and Install with Custom Values

**Problem:** Generate a Helm template and save it to a file. Then install a Helm chart with modified values in a specific namespace and version.

**Reference Doc:** https://kubernetes.io/docs/tasks/manage-kubernetes-objects/helm/ (also: `helm --help`)

**Solution Steps:**

1. Generate the template (renders manifests without installing):

```bash
helm template <release-name> <repo/chart> \
  --namespace <namespace> \
  --version <chart-version> \
  > ~/helm-template-output.yaml
```

2. Install the chart with custom values:

```bash
# Method 1: Inline value overrides
helm install <release-name> <repo/chart> \
  --namespace <namespace> \
  --create-namespace \
  --version <chart-version> \
  --set key1=value1 \
  --set key2=value2

# Method 2: From a values file
helm install <release-name> <repo/chart> \
  --namespace <namespace> \
  --create-namespace \
  --version <chart-version> \
  -f custom-values.yaml
```

**Example — ArgoCD Install:**

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Template
helm template argocd argo/argo-cd --namespace argocd --version 5.51.0 > ~/argocd-template.yaml

# Install
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --version 5.51.0 \
  --set server.service.type=NodePort
```

**Essential Helm Commands:**

```bash
helm repo add <name> <url>       # Add chart repo
helm repo update                 # Update repo index
helm search repo <keyword>       # Find charts
helm show values <chart>         # View default values
helm list -n <namespace>         # List installed releases
helm history <release> -n <ns>   # View release history
helm upgrade <release> <chart>   # Upgrade release
helm rollback <release> <rev>    # Rollback
helm uninstall <release> -n <ns> # Remove release
```

**Verification:**

```bash
helm list -n <namespace>                  # Release should appear with STATUS=deployed
kubectl get pods -n <namespace>           # Chart pods should be Running
kubectl get svc -n <namespace>            # Services should be created
```

---

# DOMAIN 3: Services & Networking (20%)

---

### Q10 — Expose a Deployment Using a NodePort Service

**Problem:** Expose an existing deployment via a NodePort service on a specified port.

**Reference Doc:** https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport

**Imperative Command (fastest):**

```bash
kubectl expose deployment <deployment-name> \
  --type=NodePort \
  --port=80 \
  --target-port=8080 \
  --name=<service-name> \
  -n <namespace>
```

> If a specific `nodePort` is required, use the declarative approach since `kubectl expose` cannot set it.

**Declarative YAML:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: <service-name>
  namespace: <namespace>
spec:
  type: NodePort
  selector:
    app: <label-matching-deployment-pods> # Must match pod labels
  ports:
    - port: 80 # Service port
      targetPort: 8080 # Container port
      nodePort: 30080 # Optional: specific node port (30000-32767)
      protocol: TCP
```

**Verification:**

```bash
kubectl get svc <service-name> -n <namespace>
# Should show TYPE=NodePort and PORT(S) column like 80:30080/TCP

curl http://<node-ip>:<nodePort>
# Should return a response from the application
```

---

### Q11 — Create an Ingress Resource

**Problem:** Create an Ingress resource matching a described scenario (host-based or path-based routing to backend services).

**Reference Doc:** https://kubernetes.io/docs/concepts/services-networking/ingress/

**Imperative Command:**

```bash
kubectl create ingress <ingress-name> \
  --rule="host.example.com/path=service-name:port" \
  -n <namespace> $do > ingress.yaml
```

**Declarative YAML:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <ingress-name>
  namespace: <namespace>
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: / # If needed
spec:
  ingressClassName: nginx # Check: kubectl get ingressclass
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix # Prefix or Exact
            backend:
              service:
                name: <service-name>
                port:
                  number: 80
```

**Verification:**

```bash
kubectl get ingress -n <namespace>
kubectl describe ingress <ingress-name> -n <namespace>
# Check ADDRESS is populated and rules are correct
curl -H "Host: app.example.com" http://<ingress-controller-ip>
```

---

### Q12 — Replace Ingress with Gateway API (TLS) + HTTPRoute

**Problem:** An Ingress with TLS exists. Create a Gateway with TLS termination and an HTTPRoute to replace it, then delete the Ingress.

**Reference Doc:** https://kubernetes.io/docs/concepts/services-networking/gateway/ and https://gateway-api.sigs.k8s.io/guides/tls/

**Solution Steps:**

1. Inspect the existing Ingress to extract details:

```bash
kubectl get ingress <ingress-name> -n <namespace> -o yaml
# Note: hostname, TLS secret name, backend service name/port, path
```

2. Check if GatewayClass exists:

```bash
kubectl get gatewayclass
# If one exists, use it. Note the name.
```

3. Create the Gateway (TLS config goes HERE, not in HTTPRoute):

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: secure-gateway
  namespace: <namespace>
spec:
  gatewayClassName: <existing-gateway-class> # From step 2
  listeners:
    - name: https
      port: 443
      protocol: HTTPS
      hostname: "secure.example.com" # From Ingress spec.rules[].host
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: tls-secret # From Ingress spec.tls[].secretName
      allowedRoutes:
        kinds:
          - kind: HTTPRoute
```

4. Create the HTTPRoute:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: secure-app-route
  namespace: <namespace>
spec:
  parentRefs:
    - name: secure-gateway # References the Gateway above
  hostnames:
    - "secure.example.com"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: <service-name> # From Ingress backend
          port: 80 # From Ingress backend port
```

5. Apply and then delete the old Ingress:

```bash
kubectl apply -f gateway.yaml
kubectl apply -f httproute.yaml
kubectl delete ingress <ingress-name> -n <namespace>
```

> **CRITICAL RULE:** TLS secret goes in the **Gateway** `listeners[].tls.certificateRefs`, **NOT** in the HTTPRoute.

**Verification:**

```bash
kubectl get gateway -n <namespace>
kubectl describe gateway secure-gateway -n <namespace>
kubectl get httproute -n <namespace>
kubectl get ingress -n <namespace>     # Should be gone
```

---

### Q13 — Select and Apply the Correct NetworkPolicy

**Problem:** Review multiple NetworkPolicy YAML samples in `~/netpol/`. Apply the one that allows traffic from frontend namespace to backend namespace without being overly permissive. Do not modify the samples.

**Reference Doc:** https://kubernetes.io/docs/concepts/services-networking/network-policies/

**Solution Steps:**

1. Inspect the deployments to find labels:

```bash
kubectl get deployment -n frontend --show-labels
kubectl get pods -n frontend --show-labels
kubectl get deployment -n backend --show-labels
kubectl get pods -n backend --show-labels
# Note the labels, e.g., app=frontend, app=backend
```

2. Check namespace labels:

```bash
kubectl get ns frontend --show-labels
kubectl get ns backend --show-labels
# If no useful labels on namespace, you can add:
# kubectl label ns frontend name=frontend (but check first)
```

3. Review each policy file:

```bash
ls ~/netpol/
cat ~/netpol/*.yaml
```

4. The **correct** policy should look like:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: backend # Applied in backend namespace
spec:
  podSelector:
    matchLabels:
      app: backend # Targets backend pods
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: frontend # OR kubernetes.io/metadata.name: frontend
          podSelector:
            matchLabels:
              app: frontend # Optional: further restricts to frontend pods
```

**Reject policies that:**

- Have an empty `podSelector: {}` (too permissive — targets all pods)
- Have an empty `from: []` or missing `from` (allows all traffic)
- Use `namespaceSelector: {}` (matches ALL namespaces)
- Apply to the wrong namespace

5. Apply only the correct one:

```bash
kubectl apply -f ~/netpol/<correct-file>.yaml
```

**Verification:**

```bash
kubectl get networkpolicy -n backend
kubectl describe networkpolicy <policy-name> -n backend
```

---

### Q14 — Update NGINX ConfigMap to Enable TLSv1.2

**Problem:** An NGINX deployment uses a ConfigMap. Currently only TLSv1.3 is enabled. Update the ConfigMap to also allow TLSv1.2, then restart the deployment. Verify with `curl --tls-max 1.2`.

**Reference Doc:** https://kubernetes.io/docs/concepts/configuration/configmap/

**Solution Steps:**

1. Export and edit the ConfigMap:

```bash
kubectl get configmap nginx-config -n nginx-static -o yaml > nginx-config.yaml
```

2. Find the TLS line and update:

```bash
# Change:
#   ssl_protocols TLSv1.3;
# To:
#   ssl_protocols TLSv1.2 TLSv1.3;
```

Or edit in-place:

```bash
kubectl edit configmap nginx-config -n nginx-static
# Find ssl_protocols and add TLSv1.2
```

3. Apply changes and restart the deployment (NGINX won't auto-reload):

```bash
kubectl apply -f nginx-config.yaml    # If using file method
kubectl rollout restart deployment nginx-static -n nginx-static
```

4. Wait for rollout:

```bash
kubectl rollout status deployment nginx-static -n nginx-static
```

**Verification:**

```bash
curl --tls-max 1.2 https://web.k8s.local
# A successful response means TLSv1.2 is now accepted
```

---

# DOMAIN 4: Storage (10%)

---

### Q15 — Create a StorageClass

**Problem:** Create a StorageClass with specified provisioner and parameters.

**Reference Doc:** https://kubernetes.io/docs/concepts/storage/storage-classes/

**Declarative YAML:**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: <storageclass-name>
provisioner: kubernetes.io/no-provisioner # Or specific provisioner
reclaimPolicy: Retain # Retain or Delete
volumeBindingMode: WaitForFirstConsumer # Or Immediate
allowVolumeExpansion: true # If needed
parameters: # Provisioner-specific
  type: gp2 # Example for AWS EBS
```

```bash
kubectl apply -f storageclass.yaml
```

**Verification:**

```bash
kubectl get storageclass
kubectl describe storageclass <storageclass-name>
```

---

### Q16 — Create a PVC to Bind an Existing PV, Then Attach to a Pod

**Problem:** A retained PV exists. Create a PVC that binds to this specific PV (matching access mode, storage, and using `volumeName`). Then update a deployment/pod to use the PVC.

**Reference Doc:** https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims

**Solution Steps:**

1. Inspect the existing PV:

```bash
kubectl get pv
kubectl describe pv <pv-name>
# Note: capacity, accessModes, storageClassName, status
```

> **WARNING:** If the PV status is `Released` (not `Available`), you must clear the `claimRef` first:
>
> ```bash
> kubectl patch pv <pv-name> -p '{"spec":{"claimRef": null}}'
> ```

2. Create the PVC to match the PV:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb
  namespace: mariadb
spec:
  accessModes:
    - ReadWriteOnce # Must match the PV
  resources:
    requests:
      storage: 250Mi # Must match or be <= PV capacity
  volumeName: <pv-name> # Binds to this specific PV
  storageClassName: "" # Empty string if PV has no storageClass
```

> **CRITICAL:** If the PV has a `storageClassName`, the PVC must match it exactly. If the PV has no `storageClassName`, set it to `""` (empty string) in the PVC.

```bash
kubectl apply -f mariadb-pvc.yaml
```

3. Edit the deployment to use the PVC:

```yaml
spec:
  template:
    spec:
      containers:
        - name: mariadb
          # ... existing config ...
          volumeMounts:
            - name: mariadb-storage
              mountPath: /var/lib/mysql
      volumes:
        - name: mariadb-storage
          persistentVolumeClaim:
            claimName: mariadb # Matches PVC name
```

```bash
kubectl apply -f ~/mariadb-deployment.yaml
```

**Verification:**

```bash
kubectl get pvc -n mariadb             # STATUS should be Bound
kubectl get pv                         # PV should be Bound to mariadb/mariadb
kubectl get pods -n mariadb            # Pod should be Running
kubectl describe pod <pod-name> -n mariadb | grep -A 5 "Volumes"
```

---

# DOMAIN 5: Troubleshooting (30%)

---

### Q17 — Fix Broken Cluster: kube-apiserver and kube-scheduler Down

**Problem:** A kubeadm cluster was migrated to a new machine. `kube-apiserver` and `kube-scheduler` are not working. `etcd`, `kube-controller-manager`, and `kubelet` are running. The cluster uses an external etcd server.

**Reference Doc:** https://kubernetes.io/docs/tasks/debug/debug-cluster/

**Debugging Flowchart:**

```
kubectl get nodes fails?
├── Check kubelet: systemctl status kubelet
├── Check control plane containers: crictl ps -a | grep kube
│   ├── kube-apiserver NOT running → check manifest
│   └── kube-scheduler NOT running → check manifest
└── Check logs: crictl logs <container-id>
```

**Solution Steps:**

1. Check what's running:

```bash
sudo systemctl status kubelet           # Should be active
sudo crictl ps -a                       # See which control plane containers are up/down
sudo crictl ps -a | grep apiserver      # Check apiserver status
sudo crictl ps -a | grep scheduler      # Check scheduler status
```

2. Check kube-apiserver logs:

```bash
sudo crictl logs $(sudo crictl ps -a | grep apiserver | awk '{print $1}')
# OR check manifest errors:
sudo journalctl -u kubelet | grep apiserver | tail -30
```

3. Fix kube-apiserver — common issues after migration:

```bash
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

**Common fixes:**

- **Wrong `--etcd-servers` URL:** Update to the correct external etcd endpoint (IP/hostname may have changed during migration).
- **Wrong cert paths:** Verify `--etcd-cafile`, `--etcd-certfile`, `--etcd-keyfile` point to existing files.
- **Wrong `--advertise-address`:** Should match the node's current IP.

```bash
# Verify cert files exist:
ls -la /etc/kubernetes/pki/etcd/
ls -la /etc/kubernetes/pki/apiserver*
```

4. Fix kube-scheduler:

```bash
sudo vi /etc/kubernetes/manifests/kube-scheduler.yaml
```

**Common fixes:**

- **Wrong `--kubeconfig` path:** Should be `/etc/kubernetes/scheduler.conf`
- **Wrong port or bind address for the API server connection**
- **Missing or incorrect authentication config**

```bash
# Verify scheduler config exists:
ls -la /etc/kubernetes/scheduler.conf
```

5. After editing manifests, kubelet auto-restarts static pods. Wait ~30 seconds:

```bash
# Watch for containers to come up:
sudo crictl ps | grep -E "apiserver|scheduler"
```

6. If static pods don't restart, force kubelet restart:

```bash
sudo systemctl restart kubelet
```

**Verification:**

```bash
kubectl get nodes                       # Should respond and show nodes
kubectl get pods -n kube-system         # All control plane pods should be Running
kubectl get componentstatuses           # (deprecated but may still work)
kubectl cluster-info                    # Should show control plane endpoints
```

---

### Q18 — Troubleshoot a Completely Failed Cluster (kubelet down)

**Problem:** The cluster is completely down. `kubelet` is not running. Cannot use `kubectl` or `crictl` initially.

**Reference Doc:** https://kubernetes.io/docs/tasks/debug/debug-cluster/

**Solution Steps:**

1. Start with systemd (the only tool available when kubelet is down):

```bash
sudo systemctl status kubelet
sudo journalctl -u kubelet --no-pager -l | tail -50
```

2. Common kubelet issues and fixes:

| Symptom in journalctl                             | Fix                                                 |
| ------------------------------------------------- | --------------------------------------------------- |
| `failed to load kubelet config file`              | Restore or fix `/var/lib/kubelet/config.yaml`       |
| `container runtime is not running`                | Start containerd: `sudo systemctl start containerd` |
| `unable to load client CA file`                   | Fix cert path in kubelet config                     |
| `node not found`                                  | Check `--hostname-override` or DNS                  |
| `kubelet.service: Failed with result 'exit-code'` | Check config file paths                             |

3. Check the kubelet config and service file:

```bash
# Kubelet service file:
sudo cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
# OR
sudo systemctl cat kubelet

# Kubelet config:
sudo cat /var/lib/kubelet/config.yaml

# Check if containerd is running:
sudo systemctl status containerd
```

4. Fix the issue, then restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo systemctl status kubelet        # Verify it's active
```

5. Once kubelet is up, check control plane:

```bash
sudo crictl ps -a                    # Are control plane pods running?
sudo crictl logs <container-id>      # Check logs of failing containers
```

6. If the apiserver is still down, check manifests:

```bash
ls /etc/kubernetes/manifests/
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml
# Fix any config errors, kubelet will auto-restart static pods
```

**Verification:**

```bash
sudo systemctl status kubelet        # active (running)
sudo crictl ps                       # All control plane containers running
kubectl get nodes                    # Node(s) showing Ready
kubectl get pods -n kube-system      # All system pods Running
```

---

# APPENDIX: Quick Reference Cards

---

### Card A — Essential kubectl Shortcuts

```bash
# Generate YAML templates quickly
kubectl run nginx --image=nginx $do > pod.yaml
kubectl create deployment nginx --image=nginx $do > dep.yaml
kubectl create service clusterip my-svc --tcp=80:80 $do > svc.yaml
kubectl create configmap my-cm --from-literal=key=value $do > cm.yaml
kubectl create secret generic my-secret --from-literal=pass=123 $do > secret.yaml
kubectl create ingress my-ing --rule="host/path=svc:port" $do > ing.yaml
kubectl create role my-role --verb=get --resource=pods $do > role.yaml
kubectl create rolebinding my-rb --role=my-role --user=jane $do > rb.yaml
```

### Card B — Exam Documentation Bookmarks

| Topic                   | URL                                                                                    |
| ----------------------- | -------------------------------------------------------------------------------------- |
| Container Runtimes      | https://kubernetes.io/docs/setup/production-environment/container-runtimes/            |
| Cluster Troubleshooting | https://kubernetes.io/docs/tasks/debug/debug-cluster/                                  |
| kubectl Cheat Sheet     | https://kubernetes.io/docs/reference/kubectl/cheatsheet/                               |
| RBAC                    | https://kubernetes.io/docs/reference/access-authn-authz/rbac/                          |
| Custom Resources        | https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/  |
| Network Policies        | https://kubernetes.io/docs/concepts/services-networking/network-policies/              |
| Persistent Volumes      | https://kubernetes.io/docs/concepts/storage/persistent-volumes/                        |
| Storage Classes         | https://kubernetes.io/docs/concepts/storage/storage-classes/                           |
| HPA Walkthrough         | https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/ |
| Pod Priority            | https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/       |
| Ingress                 | https://kubernetes.io/docs/concepts/services-networking/ingress/                       |
| Gateway API             | https://kubernetes.io/docs/concepts/services-networking/gateway/                       |
| Gateway API TLS Guide   | https://gateway-api.sigs.k8s.io/guides/tls/                                            |
| ConfigMaps              | https://kubernetes.io/docs/concepts/configuration/configmap/                           |
| Sidecar Containers      | https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/                 |
| Helm                    | https://helm.sh/docs/                                                                  |

### Card C — Troubleshooting Decision Tree

```
Problem: Can't reach cluster
│
├─ 1. Is kubelet running?
│     systemctl status kubelet
│     journalctl -u kubelet --no-pager | tail -50
│     FIX: config paths, runtime socket, certs → systemctl restart kubelet
│
├─ 2. Is containerd running?
│     systemctl status containerd
│     FIX: systemctl start containerd
│
├─ 3. Are static pods running?
│     crictl ps -a
│     crictl logs <container-id>
│     FIX: edit /etc/kubernetes/manifests/<component>.yaml
│
└─ 4. Specific component down?
      ├─ apiserver: check --etcd-servers, cert paths, --advertise-address
      ├─ scheduler: check --kubeconfig path
      ├─ controller-manager: check --kubeconfig path
      └─ etcd: check data-dir, peer URLs, cert paths
```

### Card D — Exam Day Workflow

```
1. Set up aliases (30 sec)
2. kubectl config use-context <context>  ← EVERY QUESTION
3. Triage: scan all questions, do easy ones first
4. Flag and skip after 10 min on any question
5. Verify EVERY answer before moving on
6. CRD/RBAC/HPA = fast imperative commands = do these first
7. Troubleshooting = follow the flowchart, don't guess
```

---

_18 unique questions. Every solution verified against official Kubernetes documentation patterns. You were 2% away — this guide covers every gap. Trust your preparation and go claim that CKA._
