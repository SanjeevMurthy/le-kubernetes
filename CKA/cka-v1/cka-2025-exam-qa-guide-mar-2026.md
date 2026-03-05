# CKA 2025 Exam — Complete Question & Answer Solution Guide

> **22 Real Exam Question Archetypes** extracted from 9+ confirmed 2025 exam-takers, with detailed solutions, commands, YAML manifests, key tips, and official documentation links.
>
> **Exam Format**: 16–17 performance-based tasks | 2 hours | 66% passing score | Kubernetes v1.31+
>
> **Allowed Documentation During Exam**: kubernetes.io/docs, kubernetes.io/blog, helm.sh/docs, gateway-api.sigs.k8s.io

---

## DOMAIN 1 — Cluster Architecture, Installation & Configuration (25%)

---

### Q1. Helm Template Generation and Chart Installation

**Question:**
You are given a Helm chart repository URL and a chart name. Add the Helm repository to your system, generate a Helm template for the chart (saving the output to a specified file), and then install the chart into a given namespace with a specific release name and chart version. Ensure that existing CRDs in the cluster are not overwritten during installation.

**Concept & Explanation:**

Helm is a package manager for Kubernetes that simplifies deploying applications via "charts." The 2025 CKA tests three Helm operations: adding repos, templating (rendering manifests locally without installing), and installing with flags that control CRD behavior.

`helm template` renders chart templates locally, producing the Kubernetes manifests that *would* be applied — useful for inspection or GitOps pipelines. `helm install` actually deploys the chart into the cluster. The `--skip-crds` flag or `--set crds.install=false` (chart-specific) prevents Helm from overwriting CRDs that already exist.

**Solution — Step by Step:**

```bash
# Step 1: Add the Helm repository
helm repo add argocd https://argoproj.github.io/argo-helm
helm repo update

# Step 2: Search for the chart to confirm its name and available versions
helm search repo argocd/argo-cd --versions

# Step 3: Generate the template and save to a file
helm template my-argocd argocd/argo-cd \
  --namespace argocd \
  --version 5.46.0 \
  > /path/to/output/argocd-template.yaml

# Step 4: Install the chart, skipping CRDs if they already exist
helm install my-argocd argocd/argo-cd \
  --namespace argocd \
  --create-namespace \
  --version 5.46.0 \
  --set crds.install=false

# Step 5: Verify the installation
helm list -n argocd
kubectl get pods -n argocd
```

**Key Points to Remember:**

- `helm template` does NOT install anything — it only renders YAML locally. The release name is still required as the first argument.
- `helm install` requires: `<release-name> <chart-reference>` — getting the order wrong is a common mistake under pressure.
- To skip CRDs: use `--skip-crds` (generic Helm flag) or `--set crds.install=false` (chart-specific, used by ArgoCD and others). Check the chart's `values.yaml` to know which one applies.
- `--create-namespace` automatically creates the target namespace if it doesn't exist.
- Be careful with chart names that look similar (e.g., `argo-cd` vs `argocd`). Use `helm search repo` to confirm.
- During the exam, Helm docs are accessible at `helm.sh/docs`.

**Official Documentation:**

- Helm Install: https://helm.sh/docs/helm/helm_install/
- Helm Template: https://helm.sh/docs/helm/helm_template/
- Helm Repo Add: https://helm.sh/docs/helm/helm_repo_add/
- Helm Chart Best Practices (CRDs): https://helm.sh/docs/chart_best_practices/custom_resource_definitions/

---

### Q2. CNI Installation and Configuration (Calico)

**Question:**
A Kubernetes cluster has been bootstrapped using kubeadm but no CNI plugin has been installed. Pods are stuck in `Pending` state and nodes show `NotReady`. Choose an appropriate CNI plugin that supports NetworkPolicies, install it, and configure it to use the correct Pod CIDR for the cluster. Verify that nodes become `Ready` and pods can communicate.

**Concept & Explanation:**

A Container Network Interface (CNI) plugin provides pod-to-pod networking in Kubernetes. Without a CNI, the cluster's network layer is non-functional — nodes remain `NotReady` and pods cannot be scheduled to completion. Calico is the recommended choice when NetworkPolicy support is required (Flannel does not support NetworkPolicies natively).

The critical configuration detail is ensuring the CNI's Pod CIDR matches what kubeadm was configured with. This value can be found in the kubeadm config or by inspecting node annotations.

**Solution — Step by Step:**

```bash
# Step 1: Identify the cluster's Pod CIDR
kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}'
# OR check kubeadm config:
kubectl -n kube-system get cm kubeadm-config -o yaml | grep podSubnet

# Step 2: Install Calico using the Tigera operator (recommended method)
# Install the operator
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml

# Step 3: Download and edit the custom resources manifest
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml
```

Edit `custom-resources.yaml` to match your cluster's Pod CIDR:

```yaml
# custom-resources.yaml
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: 192.168.0.0/16    # <-- Replace with your cluster's Pod CIDR
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
```

```bash
# Step 4: Apply the custom resources
kubectl apply -f custom-resources.yaml

# Step 5: Verify installation
# Wait for Calico pods to be Running
kubectl get pods -n calico-system -w

# Verify nodes are Ready
kubectl get nodes

# Verify pods can schedule and communicate
kubectl run test-pod --image=nginx --restart=Never
kubectl get pods -o wide
```

**Key Points to Remember:**

- **Flannel vs Calico**: If the question mentions NetworkPolicy support, always choose Calico. Flannel does not support NetworkPolicies.
- The Pod CIDR in the CNI configuration MUST match the Pod CIDR configured during `kubeadm init` (`--pod-network-cidr`). A mismatch is the #1 cause of networking failures post-CNI install.
- On **single-node clusters**, the control plane node has a taint (`node-role.kubernetes.io/control-plane:NoSchedule`). You may need to tolerate this taint or remove it for workloads to schedule: `kubectl taint nodes --all node-role.kubernetes.io/control-plane-`
- Two installation methods exist: (a) Tigera Operator (newer, recommended) and (b) direct manifest (`calico.yaml`). Know both, but the operator method is more commonly tested.

**Official Documentation:**

- Kubernetes Network Plugins: https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/
- Calico Quickstart: https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart
- Cluster Networking Concepts: https://kubernetes.io/docs/concepts/cluster-administration/networking/

---

### Q3. CRD Tasks — List, Query, and Manage Custom Resource Definitions

**Question:**
List all Custom Resource Definitions (CRDs) installed in the cluster that contain "cert-manager" in their name. Save the full YAML definition of each matching CRD to a single output file at a specified path. Use only `kubectl` commands (no external tools).

**Concept & Explanation:**

Custom Resource Definitions (CRDs) extend the Kubernetes API with custom resource types. The CKA 2025 exam tests your ability to interact with CRDs using kubectl and basic shell scripting. This question specifically requires combining kubectl output with bash utilities like `grep`, `awk`, and `xargs` to filter and extract CRD definitions.

**Solution — Step by Step:**

```bash
# Method 1: One-liner using bash piping (exam-tested approach)
kubectl get crd | grep cert-manager | awk '{print $1}' | \
  xargs -I {} kubectl get crd {} -o yaml >> /path/to/output/cert-manager-crds.yaml

# Method 2: Step-by-step breakdown
# Step 1: List all CRDs and filter for cert-manager
kubectl get crd | grep cert-manager
# Output example:
# certificates.cert-manager.io          2024-01-15T10:30:00Z
# clusterissuers.cert-manager.io        2024-01-15T10:30:00Z
# issuers.cert-manager.io               2024-01-15T10:30:00Z

# Step 2: Extract just the CRD names
kubectl get crd | grep cert-manager | awk '{print $1}'

# Step 3: For each CRD name, get the full YAML and append to file
for crd in $(kubectl get crd | grep cert-manager | awk '{print $1}'); do
  kubectl get crd "$crd" -o yaml >> /path/to/output/cert-manager-crds.yaml
  echo "---" >> /path/to/output/cert-manager-crds.yaml
done

# Method 3: Using kubectl with field-selector (if applicable)
kubectl get crd -o name | grep cert-manager | \
  xargs kubectl get -o yaml > /path/to/output/cert-manager-crds.yaml
```

**Key Points to Remember:**

- **Bash scripting IS tested on the 2025 CKA.** Despite older advice saying otherwise, you need to be comfortable with `grep`, `awk`, `xargs`, and piping.
- Use `>>` (append) not `>` (overwrite) when iterating through multiple CRDs to a single file.
- `kubectl get crd -o name` returns names prefixed with `customresourcedefinition.apiextensions.k8s.io/` — use `awk -F'/' '{print $2}'` to strip the prefix if needed.
- Separating YAML documents with `---` between entries is good practice.
- CRDs are cluster-scoped resources (no namespace needed).

**Official Documentation:**

- Custom Resource Definitions: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
- Extend the Kubernetes API with CRDs: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/

---

### Q4. Install Container Runtime and Prepare Node for Kubernetes

**Question:**
A new node needs to be prepared to join a Kubernetes cluster. Install and configure a container runtime (containerd), set the required OS-level kernel parameters for Kubernetes networking (`net.bridge.bridge-nf-call-iptables`, `net.ipv4.ip_forward`), and ensure all settings persist across reboots.

**Concept & Explanation:**

Before a node can join a Kubernetes cluster, it needs: (a) a container runtime (containerd, CRI-O, etc.), (b) kernel modules for networking (`overlay`, `br_netfilter`), and (c) sysctl parameters that allow bridge traffic to pass through iptables. These settings must be persisted in configuration files so they survive reboots.

**Solution — Step by Step:**

```bash
# Step 1: Load required kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Step 2: Set required sysctl parameters (persist across reboots)
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl parameters without reboot
sudo sysctl --system

# Step 3: Verify the parameters are set
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

# Step 4: Install containerd
sudo apt-get update
sudo apt-get install -y containerd

# Step 5: Configure containerd to use systemd cgroup driver
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
# Edit the config to set SystemdCgroup = true
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Step 6: Restart and enable containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# Step 7: Verify containerd is running
sudo systemctl status containerd
```

**Key Points to Remember:**

- The `SystemdCgroup = true` setting in containerd config is critical — without it, kubelet and containerd will have cgroup driver mismatches, causing node instability.
- Files in `/etc/modules-load.d/` persist kernel module loading across reboots. Files in `/etc/sysctl.d/` persist sysctl settings across reboots.
- `ip_forward = 1` enables IP forwarding, which allows pods to communicate across nodes.
- `bridge-nf-call-iptables = 1` ensures bridge traffic is processed by iptables rules (required for Services and NetworkPolicies).
- You may also need to install `kubelet`, `kubeadm`, and `kubectl` after the runtime — but the question scope determines this.

**Official Documentation:**

- Container Runtimes: https://kubernetes.io/docs/setup/production-environment/container-runtimes/
- Installing kubeadm (prerequisites): https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

---

### Q5. kubeadm Cluster Installation with Custom Configuration

**Question:**
Initialize a new Kubernetes cluster using kubeadm on a control plane node. The cluster must use a specific Pod CIDR (e.g., `10.244.0.0/16`) and a specific Service CIDR (e.g., `10.96.0.0/12`). After initialization, ensure the cluster is functional and you can interact with it using kubectl.

**Concept & Explanation:**

kubeadm is the official tool for bootstrapping Kubernetes clusters. The `kubeadm init` command initializes the control plane. Custom configurations (Pod CIDR, Service CIDR, API server address, etc.) can be passed via command-line flags or a configuration file. Post-init, you must configure kubectl access by copying the admin kubeconfig.

**Solution — Step by Step:**

```bash
# Method 1: Using command-line flags
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --service-cidr=10.96.0.0/12 \
  --kubernetes-version=v1.31.0 \
  --apiserver-advertise-address=<NODE_IP>

# Method 2: Using a configuration file (more flexible)
cat <<EOF > kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.31.0
networking:
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.96.0.0/12
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: <NODE_IP>
  bindPort: 6443
EOF

sudo kubeadm init --config=kubeadm-config.yaml

# Post-initialization: Configure kubectl access
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verify the cluster is working
kubectl get nodes
kubectl get pods -n kube-system
kubectl cluster-info
```

**Key Points to Remember:**

- The `--pod-network-cidr` value must match whatever you configure in your CNI plugin later. This is the #1 source of errors.
- Always copy the kubeconfig file after `kubeadm init` — without this step, kubectl won't work.
- The control plane node will initially show `NotReady` until a CNI is installed (see Q2).
- If the node is a single-node cluster, remove the control plane taint: `kubectl taint nodes --all node-role.kubernetes.io/control-plane-`
- Save the `kubeadm join` command printed at the end of `kubeadm init` — it's needed for worker nodes.

**Official Documentation:**

- Creating a cluster with kubeadm: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
- kubeadm init: https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/
- kubeadm Configuration (v1beta3): https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/

---

### Q6. Kustomize Deployment Tasks

**Question:**
You are given a base set of Kubernetes manifests in a directory. Use Kustomize to create an overlay that modifies the deployment — for example, changing the replica count, adding a namespace, or updating an image tag — and apply the resulting configuration to the cluster.

**Concept & Explanation:**

Kustomize is a template-free configuration management tool built into kubectl. It works by defining a `kustomization.yaml` file that references base manifests and specifies transformations (patches, name prefixes, labels, namespace overrides, image tag changes, etc.). Unlike Helm, Kustomize doesn't use templating — it uses a declarative overlay system.

**Solution — Step by Step:**

Assume the following base directory structure:

```
base/
├── deployment.yaml
├── service.yaml
└── kustomization.yaml
```

```yaml
# base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
```

Create an overlay:

```bash
mkdir -p overlays/production
```

```yaml
# overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Reference the base
resources:
  - ../../base

# Set the namespace for all resources
namespace: production

# Change the replica count via a patch
patches:
  - target:
      kind: Deployment
      name: my-app
    patch: |
      - op: replace
        path: /spec/replicas
        value: 5

# Override the image tag
images:
  - name: my-app
    newTag: v2.0.0

# Add common labels
commonLabels:
  environment: production
```

```bash
# Preview the final manifests (dry run)
kubectl kustomize overlays/production/

# Apply to the cluster
kubectl apply -k overlays/production/

# Verify
kubectl get deployments -n production
kubectl get pods -n production
```

**Key Points to Remember:**

- `kubectl apply -k <directory>` applies Kustomize configurations. The `-k` flag is the key differentiator from `-f`.
- `kubectl kustomize <directory>` renders the final YAML without applying it (similar to `helm template`).
- Kustomize is built into kubectl — no separate installation needed.
- Common transformations: `namespace`, `namePrefix`, `nameSuffix`, `commonLabels`, `commonAnnotations`, `images`, `patches`.
- Patches can use either **strategic merge patch** (partial YAML) or **JSON patch** (array of operations).
- The `kustomization.yaml` filename is required — Kustomize won't recognize other names.

**Official Documentation:**

- Kustomize Overview: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
- Kustomize Feature List: https://kubectl.docs.kubernetes.io/references/kustomize/

---

## DOMAIN 2 — Workloads & Scheduling (15%)

---

### Q7. Create a Horizontal Pod Autoscaler (HPA)

**Question:**
An existing deployment named `web-app` is running in the `default` namespace. Create a Horizontal Pod Autoscaler that scales this deployment between 1 and 4 replicas based on average CPU utilization, targeting 50% CPU usage.

**Concept & Explanation:**

The Horizontal Pod Autoscaler (HPA) automatically adjusts the number of pod replicas in a deployment based on observed metrics (CPU, memory, or custom metrics). The HPA controller periodically checks metrics and scales up/down to maintain the target utilization. For HPA to function, the Metrics Server must be installed in the cluster, and pods must have CPU/memory resource requests defined.

**Solution — Step by Step:**

```bash
# Method 1: Imperative command (fastest during exam)
kubectl autoscale deployment web-app \
  --min=1 \
  --max=4 \
  --cpu-percent=50

# Method 2: Declarative YAML
```

```yaml
# hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 1
  maxReplicas: 4
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
  behavior:                          # Optional: stabilization settings
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 50
          periodSeconds: 60
```

```bash
kubectl apply -f hpa.yaml

# Verify the HPA
kubectl get hpa
kubectl describe hpa web-app-hpa

# Check if the deployment has resource requests (required for HPA)
kubectl get deployment web-app -o yaml | grep -A5 resources
```

**Important**: If the deployment doesn't have CPU resource requests, add them:

```bash
kubectl set resources deployment web-app --requests=cpu=100m
```

**Key Points to Remember:**

- **HPA requires resource requests** on containers. Without them, HPA cannot calculate utilization and will show `<unknown>` for current metrics.
- **Metrics Server must be running.** Verify with `kubectl top pods`. If it shows errors, metrics-server is not installed.
- The imperative `kubectl autoscale` is the fastest method during the exam — use it first, then verify with `kubectl get hpa`.
- `autoscaling/v2` supports both CPU and memory metrics. `autoscaling/v1` only supports CPU.
- The `behavior` section (stabilization window) controls how quickly HPA scales down — prevents flapping.

**Official Documentation:**

- HPA Walkthrough: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
- HPA API Reference: https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v2/

---

### Q8. Add a Sidecar Log Container to an Existing Deployment

**Question:**
An existing deployment named `app-deployment` in namespace `logging` runs a main container that writes logs to `/var/log/app.log`. Add a sidecar container using the `busybox` image that continuously reads from the same log file and streams it to stdout. Both containers must share a volume.

**Concept & Explanation:**

The sidecar pattern places a helper container alongside the main application container in the same pod. They share the pod's network and can share volumes. For logging, the sidecar reads log files written by the main container via a shared `emptyDir` volume and streams them to stdout, making logs accessible via `kubectl logs`.

This is reportedly one of the hardest questions under exam time pressure because it requires editing an existing deployment's YAML with precise container and volume specifications.

**Solution — Step by Step:**

```bash
# Step 1: Export the current deployment to edit it
kubectl get deployment app-deployment -n logging -o yaml > app-deploy.yaml
```

Edit the deployment YAML to add the sidecar container and shared volume:

```yaml
# app-deploy.yaml (edited)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
  namespace: logging
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        # Main application container
        - name: app-container
          image: myapp:latest
          volumeMounts:
            - name: log-volume
              mountPath: /var/log
        # Sidecar log streaming container
        - name: log-sidecar
          image: busybox:1.36
          command: ["sh", "-c", "tail -f /var/log/app.log"]
          volumeMounts:
            - name: log-volume
              mountPath: /var/log
      volumes:
        - name: log-volume
          emptyDir: {}
```

```bash
# Step 2: Apply the updated deployment
kubectl apply -f app-deploy.yaml

# Step 3: Verify both containers are running
kubectl get pods -n logging
kubectl describe pod <pod-name> -n logging

# Step 4: Verify the sidecar is streaming logs
kubectl logs <pod-name> -n logging -c log-sidecar
```

**Alternative: Edit in-place with kubectl edit:**

```bash
kubectl edit deployment app-deployment -n logging
# Add the sidecar container and volume directly in the editor
```

**Key Points to Remember:**

- Both containers must mount the SAME volume name to the SAME path for log sharing to work.
- `emptyDir: {}` is the correct volume type — it exists as long as the pod runs and is shared between all containers in the pod.
- The sidecar command `tail -f /var/log/app.log` follows the file continuously. The `-f` flag is essential.
- When editing deployments, a new rollout is triggered. Watch for rollout status: `kubectl rollout status deployment app-deployment -n logging`.
- During the exam, `kubectl edit` is faster than export/edit/apply. But be careful with YAML indentation.
- If using `kubectl edit`, the `volumes` section goes under `spec.template.spec` (same level as `containers`), NOT at the deployment spec level.

**Official Documentation:**

- Sidecar Containers: https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/
- Logging Architecture: https://kubernetes.io/docs/concepts/cluster-administration/logging/
- Volumes (emptyDir): https://kubernetes.io/docs/concepts/storage/volumes/#emptydir

---

### Q9. PriorityClass Creation and Assignment to Workloads

**Question:**
Create a PriorityClass named `high-priority` with a priority value of `1000000` and set `globalDefault` to `false`. Then update an existing deployment named `critical-app` in namespace `production` to use this PriorityClass, ensuring it gets scheduling preference over other workloads.

**Concept & Explanation:**

PriorityClasses define relative importance of pods. When cluster resources are scarce, the scheduler uses priority to decide which pods to schedule first and which lower-priority pods to preempt (evict) to make room. Higher numeric values indicate higher priority. The `system-cluster-critical` and `system-node-critical` PriorityClasses are reserved for system components.

**Solution — Step by Step:**

```yaml
# priority-class.yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false
preemptionPolicy: PreemptLowerPriority
description: "High priority class for critical application workloads"
```

```bash
# Step 1: Create the PriorityClass
kubectl apply -f priority-class.yaml

# Step 2: Verify it was created
kubectl get priorityclass

# Step 3: Update the deployment to use the PriorityClass
kubectl patch deployment critical-app -n production \
  --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/priorityClassName", "value": "high-priority"}]'

# OR use kubectl edit:
kubectl edit deployment critical-app -n production
# Add under spec.template.spec:
#   priorityClassName: high-priority
```

The deployment YAML should look like:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-app
  namespace: production
spec:
  template:
    spec:
      priorityClassName: high-priority    # <-- Add this line
      containers:
        - name: app
          image: myapp:latest
```

```bash
# Step 4: Verify the pod has the correct priority
kubectl get pods -n production -o yaml | grep -A2 priority
```

**Key Points to Remember:**

- PriorityClass is a **cluster-scoped** resource (no namespace).
- `globalDefault: true` means ALL pods without an explicit priorityClassName get this priority. Only one PriorityClass should be the global default.
- `preemptionPolicy: PreemptLowerPriority` (default) allows this priority to evict lower-priority pods. `preemptionPolicy: Never` means the pod waits without evicting others.
- `priorityClassName` goes under `spec.template.spec` in a Deployment, NOT under `spec`.
- Values above 1 billion are reserved for system use.

**Official Documentation:**

- Pod Priority and Preemption: https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/
- PriorityClass API: https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/priority-class-v1/

---

### Q10. Resource Requests/Limits Calculation for Pending Pods

**Question:**
A deployment named `resource-app` with 3 replicas has pods stuck in `Pending` state. Investigate the issue, calculate the available CPU and memory on the node, and adjust the deployment's resource requests so that all 3 replicas can be scheduled successfully. Ensure each pod gets an equal share of available resources with an appropriate buffer for system overhead.

**Concept & Explanation:**

When pods are `Pending` with the event reason `Insufficient cpu` or `Insufficient memory`, the node doesn't have enough allocatable resources to meet the pod's resource requests. The solution requires inspecting node capacity, calculating available resources, and setting requests that allow all replicas to fit.

**Solution — Step by Step:**

```bash
# Step 1: Check why pods are pending
kubectl describe pod <pending-pod-name> | grep -A5 Events
# Look for: "0/1 nodes are available: 1 Insufficient cpu, 1 Insufficient memory"

# Step 2: Check node allocatable resources
kubectl describe node <node-name> | grep -A6 "Allocated resources"
# Note:
#   - Allocatable CPU (total available for pods)
#   - Allocatable Memory
#   - Currently requested CPU/Memory by existing pods

# Step 3: Calculate available resources
# Available = Allocatable - Already Requested
# Example:
#   Allocatable:  CPU = 2000m,  Memory = 4Gi
#   Requested:    CPU = 500m,   Memory = 1Gi
#   Available:    CPU = 1500m,  Memory = 3Gi

# Step 4: Divide by number of replicas with a buffer (~10-15% overhead)
# Per pod: CPU = (1500m * 0.85) / 3 = ~425m
# Per pod: Memory = (3Gi * 0.85) / 3 = ~870Mi

# Step 5: Update the deployment
kubectl set resources deployment resource-app \
  --requests=cpu=400m,memory=800Mi \
  --limits=cpu=800m,memory=1600Mi

# OR edit the YAML:
kubectl edit deployment resource-app
```

```yaml
# In the deployment spec:
spec:
  template:
    spec:
      containers:
        - name: app
          image: myapp:latest
          resources:
            requests:
              cpu: "400m"
              memory: "800Mi"
            limits:
              cpu: "800m"
              memory: "1600Mi"
```

```bash
# Step 6: Verify all pods are running
kubectl get pods
kubectl describe node <node-name> | grep -A6 "Allocated resources"
```

**Key Points to Remember:**

- **Requests** determine scheduling — the scheduler looks at requests, not limits, to decide if a pod fits on a node.
- **Limits** set the maximum a container can use. Exceeding CPU limits causes throttling; exceeding memory limits causes OOMKill.
- Always leave a buffer (10–15%) for system daemons (kubelet, kube-proxy, container runtime).
- `kubectl describe node` shows both `Capacity` and `Allocatable`. Use **Allocatable** for calculations (Capacity minus system reserved).
- `kubectl top nodes` shows actual real-time usage (requires metrics-server), but scheduling decisions use requests, not actual usage.
- CPU units: `1000m = 1 CPU core`. Memory units: `Mi` (mebibytes), `Gi` (gibibytes).

**Official Documentation:**

- Resource Management: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
- Assign Resources to Containers: https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/

---

### Q11. NGINX ConfigMap TLS Configuration Modification

**Question:**
An existing NGINX deployment uses a ConfigMap for its configuration. Currently, NGINX only accepts TLSv1.3 connections. Modify the ConfigMap to also accept TLSv1.2 while keeping TLSv1.3 enabled. Ensure the NGINX pods pick up the configuration change.

**Concept & Explanation:**

NGINX in Kubernetes often uses ConfigMaps to store its configuration. The TLS protocol version is controlled by the `ssl_protocols` directive. When a ConfigMap is updated, pods using it via volume mounts will eventually see the update (kubelet syncs ConfigMap changes periodically), but pods using ConfigMaps as environment variables require a restart.

**Solution — Step by Step:**

```bash
# Step 1: Identify the ConfigMap used by NGINX
kubectl get deployment nginx-deployment -o yaml | grep configMap
# Or describe the deployment to find the ConfigMap name

# Step 2: View current ConfigMap content
kubectl get configmap nginx-config -o yaml

# Step 3: Edit the ConfigMap
kubectl edit configmap nginx-config
```

Change the TLS configuration:

```nginx
# Before:
ssl_protocols TLSv1.3;

# After:
ssl_protocols TLSv1.2 TLSv1.3;
```

Full ConfigMap example:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    server {
        listen 443 ssl;
        ssl_protocols TLSv1.2 TLSv1.3;    # <-- Modified line
        ssl_certificate /etc/nginx/ssl/tls.crt;
        ssl_certificate_key /etc/nginx/ssl/tls.key;
        # ... rest of config
    }
```

```bash
# Step 4: If the ConfigMap is mounted as a volume, pods will auto-update
# (may take up to 1 minute for kubelet sync)

# If you need immediate effect, restart the deployment:
kubectl rollout restart deployment nginx-deployment

# Step 5: Verify the change
kubectl exec -it <nginx-pod> -- nginx -T | grep ssl_protocols
```

**Key Points to Remember:**

- ConfigMaps mounted as **volumes** are auto-updated by kubelet (with some delay). ConfigMaps used as **environment variables** require a pod restart.
- `kubectl rollout restart deployment <name>` is the cleanest way to force pods to reload config.
- NGINX syntax: `ssl_protocols` takes space-separated protocol names — `TLSv1.2 TLSv1.3` (no commas).
- Check with `nginx -T` inside the pod to verify the full merged configuration.
- The question may also involve NGINX Ingress Controller ConfigMaps, which use key-value pairs like `ssl-protocols: "TLSv1.2 TLSv1.3"`.

**Official Documentation:**

- ConfigMaps: https://kubernetes.io/docs/concepts/configuration/configmap/
- Configure a Pod to Use a ConfigMap: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/

---

### Q12. Run a Single-Container Pod

**Question:**
Create a pod named `nginx-pod` using the `nginx:1.25` image in the `default` namespace. The pod should expose port 80.

**Concept & Explanation:**

This is the simplest question type on the CKA and should be solved in under 30 seconds using imperative commands. It tests basic kubectl proficiency.

**Solution:**

```bash
# One-liner (fastest approach)
kubectl run nginx-pod --image=nginx:1.25 --port=80

# Verify
kubectl get pod nginx-pod
kubectl describe pod nginx-pod
```

If you need to generate YAML first (for more complex modifications):

```bash
# Generate YAML without creating the pod
kubectl run nginx-pod --image=nginx:1.25 --port=80 --dry-run=client -o yaml > pod.yaml

# Review and apply
kubectl apply -f pod.yaml
```

```yaml
# pod.yaml (generated)
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    run: nginx-pod
spec:
  containers:
    - name: nginx-pod
      image: nginx:1.25
      ports:
        - containerPort: 80
```

**Key Points to Remember:**

- `kubectl run` creates a **Pod** (not a Deployment). This changed in recent Kubernetes versions.
- `--dry-run=client -o yaml` generates YAML without applying — extremely useful during the exam for any resource.
- `--port` sets `containerPort` in the spec but does NOT expose the pod externally (you need a Service for that).
- This should take <30 seconds. If you spend more, you're overthinking it.

**Official Documentation:**

- kubectl run: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_run/

---

### Q13. Enforce Pod Security Standards on a Namespace

**Question:**
Apply the `restricted` Pod Security Standard to the namespace `secure-ns`. The standard should be enforced (not just warned or audited), meaning pods that violate the restricted profile must be rejected.

**Concept & Explanation:**

Pod Security Standards (PSS) define three profiles: `privileged` (unrestricted), `baseline` (minimally restrictive), and `restricted` (heavily restricted). They are enforced via labels on namespaces. The `restricted` profile blocks privileged containers, host networking, host PID/IPC, and requires security contexts with non-root users and read-only root filesystems.

**Solution — Step by Step:**

```bash
# Step 1: Label the namespace to enforce the restricted standard
kubectl label namespace secure-ns \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=latest

# Optional: Also add warn and audit for visibility
kubectl label namespace secure-ns \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/audit=restricted

# Step 2: Verify the labels
kubectl get namespace secure-ns --show-labels

# Step 3: Test — try creating a privileged pod (should be rejected)
kubectl run test-priv --image=nginx --namespace=secure-ns \
  --overrides='{"spec":{"containers":[{"name":"test","image":"nginx","securityContext":{"privileged":true}}]}}'
# Expected: Error - pod is forbidden by the restricted policy
```

A compliant pod in the `restricted` namespace must have:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: compliant-pod
  namespace: secure-ns
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: app
      image: nginx:1.25
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop: ["ALL"]
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
```

**Key Points to Remember:**

- Three enforcement modes: `enforce` (reject violations), `warn` (allow but show warning), `audit` (allow but log).
- Three profiles: `privileged`, `baseline`, `restricted` — from least to most restrictive.
- Labels are applied to **namespaces**, not to pods directly.
- The label key format is `pod-security.kubernetes.io/<mode>=<level>`.
- `enforce-version` can be set to `latest` or a specific Kubernetes version (e.g., `v1.31`).
- This replaced the deprecated PodSecurityPolicy (PSP) admission controller.

**Official Documentation:**

- Pod Security Standards: https://kubernetes.io/docs/concepts/security/pod-security-standards/
- Enforce Pod Security Standards with Namespace Labels: https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-namespace-labels/

---

## DOMAIN 3 — Services & Networking (20%)

---

### Q14. Gateway API Migration — Create Gateway with TLS and HTTPRoute

**Question:**
An existing Ingress resource routes traffic from `app.example.com` to a service named `web-service` on port 80, with TLS termination using a Secret named `app-tls-secret`. Migrate this routing to the Gateway API by creating a Gateway resource with TLS configuration and an HTTPRoute that replicates the existing routing behavior. After verifying the Gateway API setup works, delete the old Ingress.

**Concept & Explanation:**

The Gateway API is the successor to Ingress, providing more expressive, role-oriented, and extensible routing. A Gateway defines the network gateway (like a load balancer) with listeners that specify protocols, ports, and TLS config. HTTPRoutes attach to Gateways and define routing rules (hostnames, paths, backend services). The 2025 CKA heavily tests this migration pattern.

**Solution — Step by Step:**

First, review the existing Ingress:

```bash
kubectl get ingress app-ingress -o yaml
```

Create the Gateway:

```yaml
# gateway.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: app-gateway
  namespace: default
spec:
  gatewayClassName: example-gateway-class   # Check which class is available
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      hostname: app.example.com
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: app-tls-secret
            namespace: default
      allowedRoutes:
        namespaces:
          from: Same
```

Create the HTTPRoute:

```yaml
# httproute.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: app-route
  namespace: default
spec:
  parentRefs:
    - name: app-gateway
      namespace: default
  hostnames:
    - app.example.com
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: web-service
          port: 80
```

```bash
# Step 1: Check available GatewayClasses
kubectl get gatewayclass

# Step 2: Apply Gateway and HTTPRoute
kubectl apply -f gateway.yaml
kubectl apply -f httproute.yaml

# Step 3: Verify
kubectl get gateway app-gateway
kubectl describe gateway app-gateway
kubectl get httproute app-route
kubectl describe httproute app-route

# Step 4: Delete the old Ingress
kubectl delete ingress app-ingress
```

**IMPORTANT VARIANT — TLS Certificate in ConfigMap (not Secret):**

One exam variant stores the TLS certificate in a ConfigMap instead of a Secret. This is non-standard and requires using a `configMapRef`:

```yaml
tls:
  mode: Terminate
  certificateRefs:
    - kind: ConfigMap       # <-- Not the usual Secret
      name: app-tls-config
```

**Key Points to Remember:**

- **Gateway API docs are allowed during the exam**: `gateway-api.sigs.k8s.io` — bookmark the API reference.
- The `gatewayClassName` must reference an existing GatewayClass in the cluster. Check with `kubectl get gatewayclass` first.
- `parentRefs` in HTTPRoute links it to the Gateway. Get the name right.
- TLS `mode: Terminate` means the Gateway handles TLS termination. `mode: Passthrough` passes encrypted traffic to the backend.
- `certificateRefs` defaults to `kind: Secret`. If the exam uses ConfigMap, you must explicitly set `kind: ConfigMap`.
- Gateway API resources may not exist in the cluster by default — you may need to install the CRDs first: `kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml`

**Official Documentation:**

- Gateway API Concepts: https://gateway-api.sigs.k8s.io/concepts/api-overview/
- Gateway Resource: https://gateway-api.sigs.k8s.io/api-types/gateway/
- HTTPRoute: https://gateway-api.sigs.k8s.io/api-types/httproute/
- Kubernetes Ingress: https://kubernetes.io/docs/concepts/services-networking/ingress/

---

### Q15. Create an Ingress Resource

**Question:**
Create an Ingress resource named `app-ingress` that routes HTTP traffic for the hostname `myapp.example.com` with path `/api` (prefix match) to a backend service named `api-service` on port 8080.

**Concept & Explanation:**

An Ingress is a Kubernetes resource that manages external HTTP/HTTPS access to services within a cluster. It requires an Ingress Controller (e.g., NGINX) to be running in the cluster. Ingress defines rules that map hostnames and paths to backend services.

**Solution — Step by Step:**

```bash
# Method 1: Imperative (fast during exam)
kubectl create ingress app-ingress \
  --rule="myapp.example.com/api*=api-service:8080"
```

```yaml
# Method 2: Declarative YAML
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx    # Check which IngressClass is available
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 8080
```

```bash
kubectl apply -f ingress.yaml

# Verify
kubectl get ingress app-ingress
kubectl describe ingress app-ingress
```

**Key Points to Remember:**

- `pathType` is required and must be one of: `Prefix`, `Exact`, or `ImplementationSpecific`.
- `ingressClassName` specifies which Ingress Controller handles this Ingress. Check available classes: `kubectl get ingressclass`.
- The imperative `kubectl create ingress` is fastest during the exam. The `*` after the path indicates Prefix type.
- The backend service must exist and have a matching port.
- Annotations are controller-specific (e.g., `nginx.ingress.kubernetes.io/rewrite-target` is NGINX-specific).

**Official Documentation:**

- Ingress: https://kubernetes.io/docs/concepts/services-networking/ingress/
- Ingress Controllers: https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/

---

### Q16. Expose Deployment via NodePort Service

**Question:**
Expose an existing deployment named `frontend` on port 80 using a NodePort service. The service should be accessible on NodePort 30080 from outside the cluster.

**Concept & Explanation:**

A Service of type NodePort exposes the application on a static port on each node's IP. External traffic can reach the service via `<NodeIP>:<NodePort>`. NodePort range is 30000–32767 by default.

**Solution — Step by Step:**

```bash
# Method 1: Imperative (fastest)
kubectl expose deployment frontend \
  --type=NodePort \
  --port=80 \
  --target-port=80 \
  --name=frontend-service

# Then patch to set specific NodePort:
kubectl patch service frontend-service \
  --type='json' \
  -p='[{"op":"replace","path":"/spec/ports/0/nodePort","value":30080}]'
```

```yaml
# Method 2: Declarative YAML
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: NodePort
  selector:
    app: frontend    # Must match the deployment's pod labels
  ports:
    - protocol: TCP
      port: 80            # Service port (cluster-internal)
      targetPort: 80      # Container port
      nodePort: 30080     # External port on each node
```

```bash
kubectl apply -f service.yaml

# Verify
kubectl get svc frontend-service
curl http://<NODE_IP>:30080
```

**Key Points to Remember:**

- **Three port values**: `port` (service's cluster IP port), `targetPort` (container port), `nodePort` (external port on nodes).
- Check the deployment's pod labels first: `kubectl get deployment frontend -o yaml | grep -A3 labels`. The service `selector` must match.
- If `nodePort` is not specified, Kubernetes auto-assigns one in the 30000–32767 range.
- `kubectl expose` is the fastest method, but it auto-assigns the nodePort. Use `kubectl patch` or YAML to set a specific nodePort.
- Other service types: `ClusterIP` (internal only, default), `LoadBalancer` (cloud provider LB), `ExternalName` (DNS alias).

**Official Documentation:**

- Service Types: https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport
- kubectl expose: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_expose/

---

### Q17. Network Policy Configuration

**Question:**
Create a NetworkPolicy named `allow-frontend` in namespace `production` that allows pods with the label `role=frontend` to receive incoming TCP traffic on port 80 ONLY from pods with label `role=backend` in the same namespace and from all pods in the `monitoring` namespace. Deny all other ingress traffic to the frontend pods.

**Concept & Explanation:**

NetworkPolicies are Kubernetes resources that control traffic flow between pods. They work at the IP/port level and require a CNI that supports them (Calico, Cilium — NOT Flannel). By default, all traffic is allowed. Once a NetworkPolicy selects a pod, only explicitly allowed traffic is permitted; everything else is denied.

**Solution:**

```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
  namespace: production
spec:
  podSelector:
    matchLabels:
      role: frontend
  policyTypes:
    - Ingress
  ingress:
    - from:
        # Rule 1: Allow from backend pods in same namespace
        - podSelector:
            matchLabels:
              role: backend
        # Rule 2: Allow from ALL pods in monitoring namespace
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: monitoring
      ports:
        - protocol: TCP
          port: 80
```

**IMPORTANT: `from` array semantics:**

```yaml
# TWO separate items in `from` array = OR logic
ingress:
  - from:
      - podSelector: {matchLabels: {role: backend}}     # OR
      - namespaceSelector: {matchLabels: {name: monitoring}}

# ONE item with BOTH selectors = AND logic
ingress:
  - from:
      - podSelector: {matchLabels: {role: backend}}
        namespaceSelector: {matchLabels: {name: monitoring}}
# This means: pods labeled role=backend AND in namespace monitoring
```

```bash
# Step 1: Ensure the monitoring namespace has the correct label
kubectl label namespace monitoring kubernetes.io/metadata.name=monitoring --overwrite

# Step 2: Apply the NetworkPolicy
kubectl apply -f network-policy.yaml

# Step 3: Verify
kubectl get networkpolicy -n production
kubectl describe networkpolicy allow-frontend -n production

# Step 4: Test connectivity (optional)
# From a backend pod: curl frontend-pod:80  → should work
# From any other pod: curl frontend-pod:80  → should be blocked
```

**Key Points to Remember:**

- **OR vs AND logic**: Separate items in the `from` array are OR conditions. Combined selectors in a single item are AND conditions. This is the #1 gotcha.
- `podSelector: {}` selects ALL pods in the policy's namespace. `namespaceSelector: {}` selects ALL namespaces.
- `policyTypes: ["Ingress"]` means this policy only controls incoming traffic. Egress is unaffected.
- The `kubernetes.io/metadata.name` label is automatically applied to namespaces in modern K8s versions.
- NetworkPolicies are **additive** — if multiple policies select the same pod, the union of all allowed traffic applies.
- NetworkPolicies require a supporting CNI (Calico, Cilium). Flannel ignores them silently.

**Official Documentation:**

- Network Policies: https://kubernetes.io/docs/concepts/services-networking/network-policies/
- Declare Network Policy: https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/

---

## DOMAIN 4 — Storage (10%)

---

### Q18. Create StorageClass and Set as Default

**Question:**
Create a StorageClass named `fast-storage` using the `kubernetes.io/no-provisioner` provisioner with `volumeBindingMode: WaitForFirstConsumer`. Set this StorageClass as the cluster default. If another StorageClass is currently the default, remove its default annotation first.

**Concept & Explanation:**

StorageClasses define "classes" of storage with different performance characteristics. The `WaitForFirstConsumer` binding mode delays PV binding until a pod that uses the PVC is scheduled — this ensures the PV is created in the same availability zone as the pod. Setting a StorageClass as the default means PVCs without an explicit `storageClassName` will use it.

**Solution — Step by Step:**

```bash
# Step 1: Check if any existing StorageClass is the default
kubectl get storageclass
# The default one will have "(default)" annotation

# Step 2: Remove default from existing StorageClass (if any)
kubectl patch storageclass old-default \
  -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'
```

```yaml
# fast-storage-class.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain
```

```bash
# Step 3: Apply the new StorageClass
kubectl apply -f fast-storage-class.yaml

# Step 4: Verify it's the default
kubectl get storageclass
# fast-storage should show "(default)"
```

**Key Points to Remember:**

- Only ONE StorageClass should be the default at a time. If multiple are marked, behavior is undefined.
- The annotation key is `storageclass.kubernetes.io/is-default-class: "true"` — must be a string `"true"`, not a boolean.
- `WaitForFirstConsumer` delays binding until a pod is scheduled. `Immediate` binds the PV as soon as the PVC is created.
- `reclaimPolicy: Retain` keeps the PV data after PVC deletion. `Delete` removes the PV. `Recycle` is deprecated.
- `kubernetes.io/no-provisioner` means no dynamic provisioning — PVs must be pre-created manually. This is common in CKA exams.
- StorageClass is a cluster-scoped resource.

**Official Documentation:**

- Storage Classes: https://kubernetes.io/docs/concepts/storage/storage-classes/
- Change the Default StorageClass: https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/

---

### Q19. Create PVC and Bind to Existing PV

**Question:**
An existing PersistentVolume named `data-pv` has 5Gi capacity, `ReadWriteOnce` access mode, and StorageClass `fast-storage`. Create a PersistentVolumeClaim named `data-pvc` that binds to this specific PV. Then create a pod named `data-pod` using the `nginx` image that mounts this PVC at `/usr/share/nginx/html`.

**Concept & Explanation:**

PVCs bind to PVs when their requirements (storage size, access mode, storageClass) match. For a PVC to bind to a specific PV, the PVC's requested storage must be less than or equal to the PV's capacity, and the access mode and storageClassName must match exactly.

**Solution — Step by Step:**

```bash
# Step 1: Inspect the existing PV
kubectl get pv data-pv -o yaml
```

```yaml
# pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
    - ReadWriteOnce           # Must match the PV
  resources:
    requests:
      storage: 5Gi            # Must be <= PV capacity
  storageClassName: fast-storage  # Must match the PV's storageClass
  # Optional: bind to specific PV by name
  volumeName: data-pv
```

```yaml
# pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: data-pod
spec:
  containers:
    - name: nginx
      image: nginx
      volumeMounts:
        - name: data-volume
          mountPath: /usr/share/nginx/html
  volumes:
    - name: data-volume
      persistentVolumeClaim:
        claimName: data-pvc
```

```bash
# Step 2: Apply PVC and Pod
kubectl apply -f pvc.yaml
kubectl apply -f pod.yaml

# Step 3: Verify binding
kubectl get pv data-pv
# STATUS should be "Bound"

kubectl get pvc data-pvc
# STATUS should be "Bound" and VOLUME should show "data-pv"

kubectl get pod data-pod
# STATUS should be "Running"

# Step 4: Verify the mount inside the pod
kubectl exec data-pod -- df -h /usr/share/nginx/html
```

**Key Points to Remember:**

- The `volumeName` field in PVC forces binding to a specific PV by name. Without it, Kubernetes auto-selects based on matching criteria.
- **Access Modes**: `ReadWriteOnce` (RWO) — single node read-write, `ReadOnlyMany` (ROX) — multi-node read-only, `ReadWriteMany` (RWX) — multi-node read-write.
- PVC storage request must be **<= PV capacity**. If you request more than the PV has, it won't bind.
- StorageClassName must match exactly. If the PV has `storageClassName: ""` (empty string), the PVC must also have `storageClassName: ""`.
- For restoring deleted applications: if the PV has `persistentVolumeReclaimPolicy: Retain`, data persists after PVC deletion. Create a new PVC with `volumeName: <pv-name>` to rebind.

**Official Documentation:**

- Persistent Volumes: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- Configure a Pod to Use a PersistentVolume: https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/

---

## DOMAIN 5 — Troubleshooting (30%)

---

### Q20. Control Plane Troubleshooting — kube-apiserver / kube-scheduler

**Question:**
A Kubernetes cluster's control plane is malfunctioning. The `kubectl` command returns connection errors or timeouts. Diagnose and fix the issue. Upon investigation, you find that `kube-apiserver` and `kube-scheduler` are not running, while `etcd`, `kube-controller-manager`, and `kubelet` are operational.

**Concept & Explanation:**

Control plane components in kubeadm clusters run as static pods — their manifests are in `/etc/kubernetes/manifests/`. Kubelet watches this directory and manages these pods directly (no API server involvement). Common issues include incorrect file paths, wrong etcd endpoints, certificate mismatches, and syntax errors in YAML manifests.

**Solution — Step by Step:**

```bash
# Step 1: SSH to the control plane node (if not already there)
ssh controlplane

# Step 2: Check the status of control plane components
sudo crictl ps -a | grep -E "kube-api|kube-sched|etcd|controller"
# OR
sudo systemctl status kubelet

# Step 3: Check kubelet logs for errors related to static pods
sudo journalctl -u kubelet --no-pager -l | tail -50
# Look for errors like:
# "Failed to create pod sandbox" or "manifest parse error"

# Step 4: Examine the static pod manifests
ls -la /etc/kubernetes/manifests/
# You should see: etcd.yaml, kube-apiserver.yaml,
# kube-controller-manager.yaml, kube-scheduler.yaml

# Step 5: Check kube-apiserver.yaml for errors
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep -i etcd
# Common issue: Wrong etcd server URL
# Wrong:  --etcd-servers=https://127.0.0.1:2380
# Correct: --etcd-servers=https://127.0.0.1:2379
# Port 2379 = client port, 2380 = peer port

# Step 6: Fix the etcd-servers URL
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Change 2380 → 2379 (or fix whatever the actual error is)

# Step 7: Check kube-scheduler.yaml for errors
sudo cat /etc/kubernetes/manifests/kube-scheduler.yaml
# Common issues: wrong kubeconfig path, incorrect port

# Step 8: Fix and wait for kubelet to restart the static pods
# Kubelet detects manifest changes automatically (within ~20 seconds)

# Step 9: Verify recovery
kubectl get nodes
kubectl get pods -n kube-system
kubectl get componentstatuses   # deprecated but may still work
```

**Common Control Plane Errors and Fixes:**

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| kube-apiserver won't start | Wrong etcd URL (2380 vs 2379) | Fix `--etcd-servers` in manifest |
| kube-apiserver crashloop | Wrong certificate path | Check `--tls-cert-file` and `--tls-private-key-file` |
| kube-scheduler not running | Wrong kubeconfig path | Fix `--kubeconfig` path |
| All components down | kubelet not running | `sudo systemctl restart kubelet` |
| Node shows NotReady | kubelet stopped or misconfigured | Check `journalctl -u kubelet` |

**Key Points to Remember:**

- Static pod manifests live in `/etc/kubernetes/manifests/` — kubelet watches this directory.
- Use `sudo crictl ps -a` (not `docker ps`) to check containers on the node. Docker is deprecated.
- etcd ports: **2379** = client connections (what apiserver uses), **2380** = peer communication.
- After editing a manifest, DON'T try to `kubectl apply` it — kubelet picks up changes automatically.
- Always use `sudo` — exam environments often require root access for system files.
- Check `sudo journalctl -u kubelet -f` for real-time logs while debugging.

**Official Documentation:**

- Troubleshooting Clusters: https://kubernetes.io/docs/tasks/debug/debug-cluster/
- Static Pods: https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/
- kubeadm Troubleshooting: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/

---

### Q21. CNI / Networking Troubleshooting Post-Installation

**Question:**
After installing a CNI plugin, pods are still stuck in `ContainerCreating` or `CrashLoopBackOff` state, and inter-pod communication is failing. Diagnose and fix the networking issue.

**Concept & Explanation:**

Post-CNI networking issues usually stem from a Pod CIDR mismatch between the CNI configuration and what kubeadm was initialized with. Other causes include missing or misconfigured CNI configuration files, CNI binary not found, or node taints preventing CNI pods from scheduling.

**Solution — Step by Step:**

```bash
# Step 1: Check pod status and events
kubectl get pods -A
kubectl describe pod <problematic-pod> | grep -A10 Events
# Look for: "network not ready" or "CNI plugin not initialized"

# Step 2: Check CNI pods (in calico-system or kube-system)
kubectl get pods -n calico-system
kubectl get pods -n kube-system | grep -i calico
kubectl get pods -n kube-system | grep -i flannel
# If CNI pods are CrashLoopBackOff, check their logs:
kubectl logs -n calico-system <calico-pod> --previous

# Step 3: Verify Pod CIDR consistency
# Check what kubeadm was configured with:
kubectl -n kube-system get cm kubeadm-config -o yaml | grep podSubnet

# Check what the node expects:
kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}'

# Check what the CNI is configured with:
kubectl get installation default -o yaml | grep -A5 ipPools
# OR for Calico:
kubectl get ippools -o yaml

# Step 4: Fix the CIDR mismatch
# If CNI CIDR doesn't match node CIDR, update the CNI config:
kubectl edit installation default
# Change the cidr field under ipPools to match the node's podCIDR

# Step 5: For single-node clusters, check for taints
kubectl describe node | grep Taint
# If control-plane taint exists and CNI needs to run there:
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Step 6: Verify CNI config files on the node
ssh <node>
ls /etc/cni/net.d/
# Should contain a .conflist or .conf file
cat /etc/cni/net.d/10-calico.conflist

# Step 7: Verify CNI binaries
ls /opt/cni/bin/
# Should contain calico, calico-ipam, etc.

# Step 8: After fixes, wait for CNI pods to restart and verify
kubectl get pods -A -w
kubectl get nodes
# Nodes should show Ready
```

**Key Points to Remember:**

- **Pod CIDR mismatch** is the #1 cause of post-CNI networking failures. Always verify the CIDR matches across kubeadm config, node spec, and CNI configuration.
- CNI configuration files are stored at `/etc/cni/net.d/` on each node.
- CNI binaries are at `/opt/cni/bin/`.
- On single-node clusters, the control plane taint can prevent CNI daemonset pods from scheduling, causing a chicken-and-egg problem.
- `kubectl logs <cni-pod> --previous` shows logs from the last crashed container.
- After fixing CNI config, existing pods may need to be restarted to pick up the new network configuration: `kubectl delete pod --all` (only in test environments).

**Official Documentation:**

- Cluster Networking: https://kubernetes.io/docs/concepts/cluster-administration/networking/
- Troubleshooting CNI: https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/#is-the-cni-plugin-configured-correctly

---

### Q22. General Cluster Troubleshooting — Broken Cluster Repair

**Question:**
A worker node in the cluster shows `NotReady` status. Pods scheduled to this node are not running. SSH into the node, diagnose the issue, and restore the node to `Ready` status.

**Concept & Explanation:**

A node showing `NotReady` typically means the kubelet is not reporting health to the API server. Common causes include: kubelet service stopped or crashed, incorrect kubelet configuration, expired certificates, disk pressure, memory pressure, or container runtime issues.

**Solution — Step by Step:**

```bash
# Step 1: Check node status from the control plane
kubectl get nodes
kubectl describe node <worker-node> | grep -A20 Conditions
# Look for: KubeletNotReady, NetworkUnavailable, DiskPressure, MemoryPressure

# Step 2: SSH into the problematic node
ssh <worker-node>

# Step 3: Check kubelet status
sudo systemctl status kubelet
# If inactive/dead:
sudo systemctl start kubelet
sudo systemctl enable kubelet

# Step 4: If kubelet is running but node is still NotReady, check logs
sudo journalctl -u kubelet --no-pager -l | tail -100
# Common log errors:
# - "failed to load kubelet config file" → fix /var/lib/kubelet/config.yaml
# - "Unable to connect to the server" → check networking
# - "certificate has expired" → renew certificates
# - "container runtime is not running" → fix containerd

# Step 5: Check container runtime
sudo systemctl status containerd
# If not running:
sudo systemctl restart containerd

# Step 6: Check kubelet configuration
sudo cat /var/lib/kubelet/config.yaml
# Verify:
# - clusterDNS is correct
# - staticPodPath is correct
# - authentication/authorization settings

# Step 7: Check for disk pressure
df -h
# If disk is >85% full, kubelet marks the node as having DiskPressure

# Step 8: Check for certificate issues
sudo openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -noout -dates
# If expired, renew:
sudo kubeadm certs renew all

# Step 9: After fixing, restart kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Step 10: Verify from control plane
kubectl get nodes
# Worker node should show Ready within ~40 seconds
```

**Systematic Troubleshooting Checklist:**

```
1. kubectl describe node → read Conditions
2. SSH to node
3. systemctl status kubelet → running?
4. journalctl -u kubelet → error messages?
5. systemctl status containerd → running?
6. ls /etc/kubernetes/manifests/ → valid YAML?
7. cat /var/lib/kubelet/config.yaml → correct config?
8. df -h → disk space?
9. free -m → memory?
10. openssl x509 -in <cert> -noout -dates → cert expired?
```

**Key Points to Remember:**

- **Always check kubelet first** — it's the most common cause of `NotReady` nodes.
- `sudo systemctl daemon-reload` is needed after changing systemd unit files.
- kubelet config is at `/var/lib/kubelet/config.yaml`. The kubelet systemd service file is at `/etc/systemd/system/kubelet.service.d/10-kubeadm.conf`.
- Don't forget to `sudo systemctl enable kubelet` after starting it — otherwise it won't auto-start after reboot.
- Container runtime issues cascade: if containerd stops, kubelet can't manage containers, and the node goes NotReady.
- The exam gives you `sudo` access. Always use it for system-level operations.
- Troubleshooting questions are time-consuming (15+ minutes each). Save them for last if possible.
- Multiple troubleshooting questions appear per exam sitting (2–3 questions). Budget 30+ minutes for this domain.

**Official Documentation:**

- Troubleshooting Clusters: https://kubernetes.io/docs/tasks/debug/debug-cluster/
- Debug Running Pods: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/
- Node Health: https://kubernetes.io/docs/concepts/architecture/nodes/#node-status

---

## Exam Day Strategy — Quick Reference

**Time Budget (120 minutes total):**

| Priority | Questions | Est. Time | Action |
|----------|-----------|-----------|--------|
| First pass | Q12 (single pod), Q15 (Ingress), Q16 (NodePort) | 5 min total | Quick wins — do these immediately |
| Second pass | Q7 (HPA), Q9 (PriorityClass), Q11 (ConfigMap), Q13 (PSS), Q19 (PVC) | 20 min | Straightforward if practiced |
| Third pass | Q1 (Helm), Q6 (Kustomize), Q8 (Sidecar), Q10 (Resources), Q17 (NetworkPolicy), Q18 (StorageClass) | 35 min | Medium difficulty — steady execution |
| Fourth pass | Q2 (CNI), Q3 (CRDs), Q14 (Gateway API) | 25 min | New curriculum topics — need doc reference |
| Last | Q4 (Runtime), Q5 (kubeadm), Q20-Q22 (Troubleshooting) | 35 min | Time-consuming — save for last |

**Essential Aliases (set at start of exam):**

```bash
alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kd='kubectl describe'
export do='--dry-run=client -o yaml'
# Usage: k run nginx --image=nginx $do > pod.yaml
```

**Top kubectl Shortcuts:**

```bash
# Generate YAML for any resource
kubectl run <name> --image=<img> --dry-run=client -o yaml > pod.yaml
kubectl create deployment <name> --image=<img> --dry-run=client -o yaml > dep.yaml
kubectl create service nodeport <name> --tcp=80:80 --dry-run=client -o yaml > svc.yaml
kubectl create ingress <name> --rule="host/path=svc:port" --dry-run=client -o yaml > ing.yaml

# Quick context switching
kubectl config use-context <context-name>

# Fast resource inspection
kubectl get all -n <namespace>
kubectl top pods --sort-by=cpu
kubectl top nodes
```

---

*This guide covers all 22 question archetypes identified from 9+ confirmed 2025 CKA exam-takers. Focus your preparation on the highest-frequency questions: Gateway API migration (6 sources), Helm operations (7 sources), HPA creation (6 sources), and CNI installation (5 sources). These four topics alone cover approximately 40% of the exam.*
