# CKA Retake — Final Questions & Solutions

> **Purpose:** This document contains the **actual CKA exam questions** (reconstructed from memory and verified against online sources) with complete, verified solutions. Each question uses the exact exam wording with step-by-step solutions, imperative shortcuts, declarative YAML, verification steps, and official documentation links. Grouped by CKA exam domain.

## Table of Contents

### Domain 1: Cluster Architecture, Installation & Configuration (25%)

1. [Q1 — Install cri-dockerd and Configure Sysctl Network Parameters](#q1--install-cri-dockerd-and-configure-sysctl-network-parameters)
2. [Q2 — Install CNI Plugin (Calico) with NetworkPolicy Support](#q2--install-cni-plugin-calico-with-networkpolicy-support)
3. [Q3 — List cert-manager CRDs and Extract Field Documentation](#q3--list-cert-manager-crds-and-extract-field-documentation)
4. [Q4 — RBAC for Custom Resources (CRDs)](#q4--rbac-for-custom-resources-crds)
5. [Q5 — Create a PriorityClass and Patch Deployment](#q5--create-a-priorityclass-and-patch-deployment)
6. [Q6 — Helm Template ArgoCD with Custom Configuration](#q6--helm-template-argocd-with-custom-configuration)

### Domain 2: Workloads & Scheduling (15%)

7. [Q7 — Create a Horizontal Pod Autoscaler (HPA) with Downscale Stabilization](#q7--create-a-horizontal-pod-autoscaler-hpa-with-downscale-stabilization)
8. [Q8 — Fix Pending Pods by Adjusting Resource Requests](#q8--fix-pending-pods-by-adjusting-resource-requests)
9. [Q9 — Add a Sidecar Container to an Existing Deployment](#q9--add-a-sidecar-container-to-an-existing-deployment)
10. [Q10 — Taints and Tolerations](#q10--taints-and-tolerations)

### Domain 3: Services & Networking (20%)

11. [Q11 — Expose Deployment with NodePort Service](#q11--expose-deployment-with-nodeport-service)
12. [Q12 — Create an Ingress Resource](#q12--create-an-ingress-resource)
13. [Q13 — Migrate Ingress to Gateway API with TLS + HTTPRoute](#q13--migrate-ingress-to-gateway-api-with-tls--httproute)
14. [Q14 — Select and Apply the Correct NetworkPolicy](#q14--select-and-apply-the-correct-networkpolicy)
15. [Q15 — Update NGINX ConfigMap to Add TLSv1.2 Support and Make Immutable](#q15--update-nginx-configmap-to-add-tlsv12-support-and-make-immutable)

### Domain 4: Storage (10%)

16. [Q16 — Create a StorageClass and Set as Default](#q16--create-a-storageclass-and-set-as-default)
17. [Q17 — Create PVC to Bind an Existing PV and Restore MariaDB Deployment](#q17--create-pvc-to-bind-an-existing-pv-and-restore-mariadb-deployment)

### Domain 5: Troubleshooting (30%)

18. [Q18 — Fix kube-apiserver After Cluster Migration (etcd Port Fix)](#q18--fix-kube-apiserver-after-cluster-migration-etcd-port-fix)

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

### Q1 — Install cri-dockerd and Configure Sysctl Network Parameters

**Problem:** Set up cri-dockerd. Install the debian package `~/cri-dockerd.deb` using `dpkg`. Enable and start the `cri-docker` service. Configure these parameters:

1. Set `net.bridge.bridge-nf-call-iptables` to `1`
2. Set `net.ipv6.conf.all.forwarding` to `1`
3. Set `net.ipv4.ip_forward` to `1`
4. Set `net.netfilter.nf_conntrack_max` to `131072`

**Reference Doc:** https://kubernetes.io/docs/setup/production-environment/container-runtimes/

**Solution Steps:**

1. Install the `.deb` package:

```bash
sudo dpkg -i ~/cri-dockerd.deb
# If dependency errors occur:
sudo apt-get install -f
```

2. Enable and start the cri-docker service:

```bash
sudo systemctl enable --now cri-docker.service
sudo systemctl status cri-docker.service
```

3. Configure sysctl parameters persistently:

```bash
sudo tee /etc/sysctl.d/kube.conf >/dev/null <<'EOF'
net.bridge.bridge-nf-call-iptables=1
net.ipv6.conf.all.forwarding=1
net.ipv4.ip_forward=1
net.netfilter.nf_conntrack_max=131072
EOF

sudo sysctl --system
```

> **WARNING:** The `net.bridge.*` parameters require the `br_netfilter` kernel module to be loaded. If sysctl --system shows errors for bridge parameters, load the module first:
>
> ```bash
> sudo modprobe br_netfilter
> ```

> **Key:** Writing to `/etc/sysctl.d/` makes the settings **persistent across reboots**. `sysctl --system` applies them **immediately** without a reboot. Both are needed for full marks.

**Verification:**

```bash
sudo systemctl status cri-docker.service    # Should be active (running)
sysctl net.bridge.bridge-nf-call-iptables   # → 1
sysctl net.ipv6.conf.all.forwarding         # → 1
sysctl net.ipv4.ip_forward                  # → 1
sysctl net.netfilter.nf_conntrack_max       # → 131072
```

---

### Q2 — Install CNI Plugin (Calico) with NetworkPolicy Support

**Problem:** Install and configure a CNI of your choice that meets the specified requirements. Choose one of the following:

- **Flannel (v0.26.1)** using the manifest `kube-flannel.yml` (`https://github.com/flannel-io/flannel/releases/download/v0.26.1/kube-flannel.yml`)
- **Calico (v3.28.2)** using the manifest `tigera-operator.yaml` (`https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml`)

The CNI you choose must:

1. Let pods communicate with each other
2. Support network policy enforcement
3. Install from manifest

**Reference Doc:** https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy

**Key Decision:** Choose **Calico** — it natively supports NetworkPolicies. Flannel does **not** support network policy enforcement.

**Solution Steps:**

1. Determine the cluster's Pod CIDR (needed for Calico configuration):

```bash
kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}'
# OR check kubeadm config:
kubectl -n kube-system get cm kubeadm-config -o yaml | grep podSubnet
```

2. Install the Calico operator:

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml
```

3. Download and configure the custom resources (set PodCIDR):

```bash
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
kubectl get all -n tigera-operator              # tigera-operator should be Running
kubectl get pods -n calico-system               # calico-node, calico-kube-controllers should be Running
kubectl get nodes                               # All nodes should be Ready
# Test pod gets an IP:
kubectl run test-cni --image=nginx --restart=Never
kubectl get pod test-cni -o wide                # Should have an IP in the Pod CIDR range
kubectl delete pod test-cni $now
```

---

### Q3 — List cert-manager CRDs and Extract Field Documentation

**Problem:**

1. Create a list of all cert-manager CRDs and save it to `/root/resources.yaml`. You may use any output format that kubectl supports.
2. Using kubectl, extract the documentation for the `subject` specification field of the Certificate Custom Resource and save it to `/root/subject.yaml`.

**Reference Doc:** https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#viewing-crds

**Solution Steps:**

1. List all cert-manager CRDs and save:

```bash
kubectl get crd | grep cert-manager | tee /root/resources.yaml
```

> **TIP:** The question says "you may use any output format" — the default table output (`grep` redirect) is the simplest and works fine here.

2. Extract the `spec.subject` field documentation:

```bash
kubectl explain certificate.spec.subject | tee /root/subject.yaml
```

3. If unsure of the resource name:

```bash
kubectl api-resources | grep cert-manager
# Look for KIND=Certificate, NAME=certificates
```

**Verification:**

```bash
cat /root/resources.yaml     # Should list cert-manager CRDs
cat /root/subject.yaml       # Should show GROUP, VERSION, KIND, FIELD, DESCRIPTION for spec.subject
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

### Q5 — Create a PriorityClass and Patch Deployment

**Problem:** You're working in a Kubernetes cluster with an existing deployment named `busybox-logger` running in the `priority` namespace. The cluster already has at least one user-defined PriorityClass.

**Tasks:**

1. Create a new PriorityClass named `high-priority` for user workloads. The value of this class should be exactly one less than the highest existing user-defined PriorityClass.
2. Patch the existing deployment `busybox-logger` in the `priority` namespace to use the newly created `high-priority` class.

**Reference Doc:** https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#priorityclass

**Solution Steps:**

1. Find the highest existing user-defined PriorityClass value:

```bash
kubectl get priorityclasses
# Ignore system-* classes (system-cluster-critical=2000000000, system-node-critical=2000001000)
# Note the highest user-defined value, e.g., 1000
```

2. Create the new PriorityClass (value = highest - 1):

```bash
# If the highest user-defined value is 1000:
kubectl create priorityclass high-priority --value=999 --description="high priority"
```

Or declaratively:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 999 # One less than the highest user-defined PC
globalDefault: false
preemptionPolicy: PreemptLowerPriority
description: "high priority"
```

3. Patch the deployment to use it:

```bash
kubectl patch deployment busybox-logger -n priority \
  -p '{"spec":{"template":{"spec":{"priorityClassName":"high-priority"}}}}'
```

Or declaratively — export, edit, and apply:

```yaml
# Add this under spec.template.spec:
spec:
  template:
    spec:
      priorityClassName: high-priority
```

```bash
kubectl edit deployment busybox-logger -n priority
# Add priorityClassName: high-priority under spec.template.spec
```

**Verification:**

```bash
kubectl get pc                        # high-priority should appear with value 999
kubectl describe deployment busybox-logger -n priority | grep -i "Priority Class"
# Should show: high-priority
kubectl get pods -n priority          # Pods should be Running
```

---

### Q6 — Helm Template ArgoCD with Custom Configuration

**Problem:** Install Argo CD in a Kubernetes cluster using Helm while ensuring the CRDs are not installed (as they are pre-installed).

**Tasks:**

1. Add the official Argo CD Helm repository with the name `argocd` (`https://argoproj.github.io/argo-helm`)
2. Create a namespace called `argocd`
3. Generate a Helm template from the Argo CD chart version `7.7.3` for the `argocd` namespace
4. Ensure that CRDs are not installed by configuring the chart accordingly
5. Save the generated YAML manifest to `/root/argo-helm.yaml`

**Reference Doc:** https://kubernetes.io/docs/tasks/manage-kubernetes-objects/helm/

**Solution Steps:**

1. Create the namespace:

```bash
kubectl create namespace argocd
```

2. Add the Helm repository:

```bash
helm repo add argocd https://argoproj.github.io/argo-helm
helm repo update
```

3. Generate the template with CRDs disabled and save:

```bash
helm template argocd argocd/argo-cd \
  --version 7.7.3 \
  --namespace argocd \
  --set crds.install=false \
  > /root/argo-helm.yaml
```

> **CRITICAL:** `helm template` renders manifests locally **without installing**. This is different from `helm install`. The `--set crds.install=false` flag tells the chart to skip CRD installation since they are pre-installed.

> **TIP:** If you're unsure what values a chart accepts, run `helm show values argocd/argo-cd` to see all configurable options.

**Essential Helm Commands for the Exam:**

```bash
helm repo add <name> <url>       # Add chart repo
helm repo update                 # Update repo index
helm search repo <keyword>       # Find charts
helm show values <chart>         # View default values
helm template <name> <chart>     # Render templates locally (no install)
helm install <name> <chart>      # Install chart
helm list -n <namespace>         # List installed releases
helm uninstall <release> -n <ns> # Remove release
```

**Verification:**

```bash
cat /root/argo-helm.yaml         # Should contain rendered K8s manifests
# Verify no CRD resources in the output:
grep "kind: CustomResourceDefinition" /root/argo-helm.yaml
# Should return no results
```

---

# DOMAIN 2: Workloads & Scheduling (15%)

---

### Q7 — Create a Horizontal Pod Autoscaler (HPA) with Downscale Stabilization

**Problem:** Create a new HorizontalPodAutoscaler (HPA) named `apache-server` in the `autoscale` namespace.

**Tasks:**

1. The HPA must target the existing deployment called `apache-deployment` in the `autoscale` namespace
2. Set the HPA to target 50% CPU usage per Pod
3. Configure the HPA to have a minimum of 1 pod and a maximum of 4 pods
4. Set the downscale stabilization window to 30 seconds

**Reference Doc:** https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/

**Sample Target Deployment** (already exists in the cluster):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache-deployment
  namespace: autoscale
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      containers:
        - name: apache
          image: httpd:2.4
          resources:
            requests:
              cpu: "100m" # ← HPA requires this to calculate CPU utilization
              memory: "128Mi"
            limits:
              cpu: "200m"
              memory: "256Mi"
          ports:
            - containerPort: 80
```

> **CRITICAL:** The deployment **must** have `resources.requests.cpu` set on its containers, otherwise HPA cannot calculate CPU utilization and the TARGETS column will show `<unknown>/50%`.

**Solution Steps:**

Since the question requires a `downscale stabilization window`, we need `autoscaling/v2` with the `behavior` field — the imperative `kubectl autoscale` command **cannot** set this.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: apache-server
  namespace: autoscale
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: apache-deployment
  minReplicas: 1
  maxReplicas: 4
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 30
```

```bash
kubectl apply -f hpa.yaml
```

> **WARNING:** The deployment's containers **must** have `resources.requests.cpu` set for HPA to work. If the TARGETS column shows `<unknown>/50%`, the deployment lacks CPU requests.

> **Key:** The `behavior.scaleDown.stabilizationWindowSeconds` field is only available in `autoscaling/v2`. The default stabilization window is 300 seconds (5 minutes); the question asks to set it to 30 seconds.

**Verification:**

```bash
kubectl get hpa -n autoscale
kubectl describe hpa apache-server -n autoscale
# TARGETS column should show current/target (e.g., 10%/50%)
# Check behavior section shows stabilizationWindowSeconds: 30
```

---

### Q8 — Fix Pending Pods by Adjusting Resource Requests

**Problem:** You are managing a WordPress application running in a Kubernetes cluster. Your task is to adjust the Pod resource requests and limits to ensure stable operation.

**Tasks:**

1. Scale down the WordPress deployment to 0 replicas
2. Edit the deployment and divide the node resources evenly across all 3 pods
3. Assign fair and equal CPU and memory to each Pod
4. Add sufficient overhead to avoid node instability
5. Ensure both the init containers and the main containers use exactly the same resource requests and limits
6. After making the changes, scale the deployment back to 3 replicas

**Reference Doc:** https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/

**Sample Deployment** (already exists in the cluster — pods are Pending due to oversized resource requests):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
spec:
  replicas: 3
  selector:
    matchLabels:
      app: wordpress
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      initContainers:
        - name: init-db-check
          image: busybox:stable
          command: ["sh", "-c", "echo 'Checking DB connectivity'"]
          resources:
            requests:
              cpu: "1000m" # ← Too high — causes Pending
              memory: "2Gi"
            limits:
              cpu: "1000m"
              memory: "2Gi"
      containers:
        - name: wordpress
          image: wordpress:6.4
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "1000m" # ← Too high — causes Pending
              memory: "2Gi"
            limits:
              cpu: "1000m"
              memory: "2Gi"
```

> **Root Cause:** With 3 replicas × 1000m CPU each = 3000m total, but the node may only have ~2000m allocatable CPU. This causes pods to stay in Pending with `Insufficient cpu` in events.

**Solution Steps:**

1. Scale down to 0 replicas:

```bash
kubectl scale deployment wordpress --replicas=0
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
Available = Allocatable - Already_Used - System_Overhead_Buffer (~10-15%)
Per_Pod = Available / 3 (number of replicas)
Per_Container = Per_Pod resources (same for init and main containers)
```

4. Edit the deployment — set **identical** resources on all init and main containers:

```bash
kubectl edit deployment wordpress
```

Update every container (init and main) with the same resources:

```yaml
resources:
  requests:
    cpu: "300m" # Calculated value based on node capacity
    memory: "600Mi" # Calculated value based on node capacity
  limits:
    cpu: "400m"
    memory: "700Mi"
```

> **CRITICAL:** The question explicitly says "Ensure both the init containers and the main containers use exactly the same resource requests and limits." Every container — init and main — must have identical values.

5. Scale back to 3 replicas:

```bash
kubectl scale deployment wordpress --replicas=3
kubectl rollout status deployment wordpress
```

**Verification:**

```bash
kubectl get pods -l app=wordpress
# All 3 replicas should be Running, none Pending
kubectl describe pod <pod-name> | grep -A 3 "Requests"
# Verify all containers show the same resource values
```

---

### Q9 — Add a Sidecar Container to an Existing Deployment

**Problem:** Update the existing WordPress deployment by adding a sidecar container named `sidecar` using the `busybox:stable` image to the existing pod. The new sidecar container has to run the following command: `"/bin/sh -c tail -f /var/log/wordpress.log"`. Use a volume mounted at `/var/log` to make the log file `wordpress.log` available to the co-located container.

**Reference Doc:** https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/

**Solution Steps:**

1. Export the existing deployment:

```bash
kubectl get deployment wordpress -o yaml > wordpress-deploy.yaml
```

2. Edit the deployment — add a shared `emptyDir` volume and the sidecar container:

```yaml
spec:
  template:
    spec:
      volumes:
        - name: log
          emptyDir: {}
      containers:
        - name: wordpress # Existing container
          # ... existing config ...
          volumeMounts:
            - name: log
              mountPath: /var/log
        - name: sidecar # NEW sidecar container
          image: busybox:stable
          command: ["/bin/sh", "-c", "tail -f /var/log/wordpress.log"]
          volumeMounts:
            - name: log
              mountPath: /var/log # Same path to share logs
```

3. Apply:

```bash
kubectl apply -f wordpress-deploy.yaml
kubectl rollout status deployment wordpress
```

**Verification:**

```bash
kubectl get pods -l app=wordpress
# Pods should show 2/2 READY (main + sidecar)
kubectl logs <pod-name> -c sidecar
# Should show log output (or wait for logs to appear)
```

---

### Q10 — Taints and Tolerations

**Problem:**

**Tasks:**

1. Add a taint to `node01` so that no normal pods can be scheduled on this node. Key=`PERMISSION`, Value=`granted`, Effect=`NoSchedule`.
2. Schedule a Pod on `node01` adding the correct toleration to the spec so it can be deployed.

**Reference Doc:** https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/

**Solution Steps:**

1. Add the taint to node01:

```bash
kubectl taint nodes node01 PERMISSION=granted:NoSchedule
```

2. Create a pod with the matching toleration:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
    - name: nginx
      image: nginx
  tolerations:
    - key: PERMISSION
      operator: Equal
      value: granted
      effect: NoSchedule
```

```bash
kubectl apply -f pod.yaml
```

> **Key toleration fields:**
>
> - `key` must match the taint key exactly (`PERMISSION`)
> - `operator: Equal` requires both key and value to match
> - `value` must match the taint value exactly (`granted`)
> - `effect` must match the taint effect exactly (`NoSchedule`)

> **TIP:** To remove a taint later: `kubectl taint nodes node01 PERMISSION=granted:NoSchedule-` (note the trailing `-`)

**Verification:**

```bash
kubectl get pods -o wide
# nginx pod should be Running on node01

# Negative test — a pod without toleration should stay Pending:
kubectl run nginx-fail --image=nginx
kubectl describe pod nginx-fail | grep -A 5 "Events"
# Should show: node(s) had untolerated taint {PERMISSION: granted}
```

---

# DOMAIN 3: Services & Networking (20%)

---

### Q11 — Expose Deployment with NodePort Service

**Problem:** There is a deployment named `nodeport-deployment` in the relevant namespace.

**Tasks:**

1. Configure the deployment so it can be exposed on port 80, name=`http`, protocol TCP
2. Create a new Service named `nodeport-service` exposing the container port 80, protocol TCP, Node Port 30080
3. Configure the new Service to also expose the individual pods using NodePort

**Reference Doc:** https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport

**Solution Steps:**

1. Patch the deployment to add the container port definition:

```bash
kubectl patch deployment nodeport-deployment -n <namespace> -p '{
  "spec":{"template":{"spec":{"containers":[{
    "name":"nginx",
    "ports":[{"name":"http","containerPort":80,"protocol":"TCP"}]
  }]}}}}'
```

Or via `kubectl edit`:

```yaml
# Add under spec.template.spec.containers[0]:
ports:
  - name: http
    containerPort: 80
    protocol: TCP
```

```bash
kubectl edit deployment nodeport-deployment -n <namespace>
# Add the ports section under the container spec
```

> **TIP:** Check the container name first with `kubectl get deploy nodeport-deployment -n <namespace> -o yaml | grep "name:"` and replace `nginx` with the actual container name.

2. Create the NodePort service on port 30080:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nodeport-service
  namespace: <namespace>
spec:
  type: NodePort
  selector:
    app: nodeport-deployment # Must match pod labels
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
      nodePort: 30080
```

```bash
kubectl apply -f svc.yaml
```

> **Key:** Check the pod labels first: `kubectl get pods -n <namespace> --show-labels` to ensure the `selector` matches the pod labels.

**Verification:**

```bash
kubectl get svc nodeport-service -n <namespace> -o wide
# Should show TYPE=NodePort and PORT(S) column like 80:30080/TCP
kubectl get deploy nodeport-deployment -n <namespace> -o wide

# Test access:
curl http://<node-ip>:30080
# Should return a response from the application
```

---

### Q12 — Create an Ingress Resource

**Problem:**

**Tasks:**

1. Expose the existing deployment with a service called `echo-service` using Service Port 8080, type=NodePort
2. Create a new Ingress resource named `echo` in the `echo-sound` namespace for `http://example.org/echo`
3. The availability of the Service `echo-service` can be checked using `curl NODEIP:NODEPORT/echo`

**Reference Doc:** https://kubernetes.io/docs/concepts/services-networking/ingress/

**Solution Steps:**

1. Expose the deployment as a NodePort service:

```bash
kubectl expose deployment echo -n echo-sound \
  --name echo-service \
  --type NodePort \
  --port 8080 \
  --target-port 8080
```

2. Create the Ingress resource:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: echo
  namespace: echo-sound
spec:
  rules:
    - host: example.org
      http:
        paths:
          - path: /echo
            pathType: Prefix
            backend:
              service:
                name: echo-service
                port:
                  number: 8080
```

```bash
kubectl apply -f ingress.yaml
```

> **TIP:** If the exam gives a verification command like `curl -o /dev/null -s -w "%{http_code}\n" http://example.org/echo`, you may need to add an entry in `/etc/hosts` pointing your NodeIP to `example.org`:
>
> ```bash
> echo "<node-ip> example.org" | sudo tee -a /etc/hosts
> ```

**Verification:**

```bash
kubectl get svc -n echo-sound echo-service
kubectl get ingress -n echo-sound
kubectl describe ingress echo -n echo-sound
# Check ADDRESS is populated and rules are correct

# Test via NodePort:
curl http://<nodeIP>:<nodePort>/echo
```

---

### Q13 — Migrate Ingress to Gateway API with TLS + HTTPRoute

**Problem:** You have an existing web application deployed in a Kubernetes cluster using an Ingress resource named `web`. You must migrate the existing Ingress configuration to the new Kubernetes Gateway API, maintaining the existing HTTPS access configuration.

**Tasks:**

1. Create a Gateway Resource named `web-gateway` with hostname `gateway.web.k8s.local` that maintains the existing TLS and listener configuration from the existing Ingress resource named `web`
2. Create an HTTPRoute resource named `web-route` with hostname `gateway.web.k8s.local` that maintains the existing routing rules from the current Ingress resource named `web`
3. Note: A GatewayClass named `nginx-class` is already installed in the cluster

**Reference Docs (all accessible during CKA exam):**

- **Gateway + HTTPRoute resource model (kubernetes.io):** https://kubernetes.io/docs/concepts/services-networking/gateway/#resource-model — contains Gateway YAML with listeners, HTTPRoute YAML with parentRefs, hostnames, and backendRefs
- **Gateway TLS examples (gateway-api.sigs.k8s.io):** https://gateway-api.sigs.k8s.io/guides/tls/#examples — contains Gateway YAML with HTTPS listeners, `certificateRefs` to Secrets, and TLS termination mode
- **HTTPRoute routing examples (gateway-api.sigs.k8s.io):** https://gateway-api.sigs.k8s.io/guides/http-routing/ — contains HTTPRoute YAML with path matching, hostnames, and backendRefs

**Sample Existing Ingress** (already deployed in the cluster — this is what you're migrating from):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
spec:
  tls:
    - hosts:
        - gateway.web.k8s.local
      secretName: web-tls # ← Use this in Gateway certificateRefs
  rules:
    - host: gateway.web.k8s.local # ← Use this in Gateway hostname + HTTPRoute hostnames
      http:
        paths:
          - path: / # ← Use this in HTTPRoute matches
            pathType: Prefix
            backend:
              service:
                name: web-service # ← Use this in HTTPRoute backendRefs
                port:
                  number: 80 # ← Use this in HTTPRoute backendRefs port
```

**Solution Steps:**

1. Inspect the existing Ingress to extract TLS secret and backend service details:

```bash
kubectl describe ingress web
kubectl describe secret web-tls
# Note: hostname, TLS secret name, backend service name/port, path
```

2. Create the Gateway (TLS config goes HERE, not in HTTPRoute):

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
spec:
  gatewayClassName: nginx-class
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      hostname: gateway.web.k8s.local
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: web-tls # From Ingress spec.tls[].secretName
```

```bash
kubectl apply -f gw.yaml
```

3. Create the HTTPRoute:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
spec:
  parentRefs:
    - name: web-gateway # References the Gateway above
  hostnames:
    - "gateway.web.k8s.local"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: web-service # From Ingress backend
          port: 80 # From Ingress backend port
```

```bash
kubectl apply -f http.yaml
```

> **CRITICAL RULE:** TLS secret goes in the **Gateway** `listeners[].tls.certificateRefs`, **NOT** in the HTTPRoute.

**Verification:**

```bash
kubectl describe gateway web-gateway
kubectl describe httproute web-route
kubectl get gateway                      # Should show READY
kubectl get httproute                    # Should show ACCEPTED
```

---

### Q14 — Select and Apply the Correct NetworkPolicy

**Problem:** There are two deployments: Frontend and Backend. Frontend is in the `frontend` namespace, Backend is in the `backend` namespace.

**Task:** Look at the NetworkPolicy YAML files in `/root/network-policies`. Decide which of the policies provides the functionality to allow interaction between the frontend and the backend deployments in the **least permissive way**, and deploy that YAML.

**Reference Doc:** https://kubernetes.io/docs/concepts/services-networking/network-policies/

**Solution Steps:**

1. Inspect the deployments to find labels:

```bash
kubectl get pods -n frontend --show-labels
kubectl get pods -n backend --show-labels
# Note the labels, e.g., app=frontend, app=backend
```

2. Check namespace labels:

```bash
kubectl get ns frontend --show-labels
kubectl get ns backend --show-labels
```

3. Review each policy file:

```bash
ls /root/network-policies/
cat /root/network-policies/*.yaml
```

4. Compare and choose the **least permissive** one:

```bash
cat /root/network-policies/network-policy-1.yaml   # allows all ingress (too open)
cat /root/network-policies/network-policy-2.yaml   # extra IP block allowed (too open)
cat /root/network-policies/network-policy-3.yaml   # only frontend namespace/pods allowed ✓
```

**Reject policies that:**

- Have an empty `podSelector: {}` (too permissive — targets all pods)
- Have an empty `from: []` or missing `from` (allows all traffic)
- Use `namespaceSelector: {}` (matches ALL namespaces)
- Allow additional IP blocks not needed
- Apply to the wrong namespace

The **correct** policy should look like:

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
              kubernetes.io/metadata.name: frontend
          podSelector:
            matchLabels:
              app: frontend
```

5. Apply only the correct one:

```bash
kubectl apply -f /root/network-policies/network-policy-3.yaml
```

**Verification:**

```bash
kubectl get networkpolicy -n backend
kubectl describe networkpolicy <policy-name> -n backend
```

---

### Q15 — Update NGINX ConfigMap to Add TLSv1.2 Support and Make Immutable

**Problem:** There is an existing deployment in the `nginx-static` namespace. The deployment contains a ConfigMap that currently only supports TLSv1.3, as well as a Secret for TLS. There is a service called `nginx-service` in the `nginx-static` namespace that is currently exposing the deployment.

**Tasks:**

1. Configure the ConfigMap to also support TLSv1.2 (in addition to TLSv1.3)
2. Make the ConfigMap **immutable** after the edit
3. Add the IP address of the service in `/etc/hosts` and name it `ckaquestion.k8s.local`
4. Verify everything is working using the following commands:
   - `curl -vk --tls-max 1.2 https://ckaquestion.k8s.local` — should **work**
   - `curl -vk --tlsv1.3 https://ckaquestion.k8s.local` — should **work**

**Reference Doc:** https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-immutable

**Solution Steps:**

1. Edit the ConfigMap to add TLSv1.2:

```bash
kubectl edit configmap nginx-config -n nginx-static
# Find the ssl_protocols line and add TLSv1.2:
# Change: ssl_protocols TLSv1.3;
# To:     ssl_protocols TLSv1.2 TLSv1.3;
```

2. Make the ConfigMap immutable — add `immutable: true` at the top level:

```bash
kubectl edit configmap nginx-config -n nginx-static
# Add this field at the top level (same level as `data:`):
# immutable: true
```

Or patch it:

```bash
kubectl patch configmap nginx-config -n nginx-static \
  -p '{"immutable": true}'
```

The equivalent YAML field (add at the top level of the ConfigMap, same level as `data:`):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: nginx-static
immutable: true # ← Add this field
data:
  # ... existing data stays unchanged ...
```

> **CRITICAL:** Once a ConfigMap is marked `immutable: true`, it **cannot** be changed back. You cannot edit the data or remove the immutable flag. The only way to undo it is to delete and recreate the ConfigMap. So make sure the TLSv1.2 change is correct **before** making it immutable.

> **TIP:** You can combine both edits (adding TLSv1.2 + setting immutable) in a single `kubectl edit` session.

3. Get the service IP and add to `/etc/hosts`:

```bash
kubectl get svc -n nginx-static nginx-service
# Note the ClusterIP (e.g., 10.96.x.x)

sudo sh -c 'echo "10.96.x.x ckaquestion.k8s.local" >> /etc/hosts'
# Replace 10.96.x.x with the actual service IP

# Verify /etc/hosts was updated:
cat /etc/hosts
```

4. Restart the deployment (NGINX won't auto-reload ConfigMap changes):

```bash
kubectl rollout restart deployment nginx-static -n nginx-static
kubectl rollout status deployment nginx-static -n nginx-static
```

**Verification:**

```bash
# Both should SUCCEED (TLSv1.2 and TLSv1.3 are now supported):
curl -vk --tls-max 1.2 https://ckaquestion.k8s.local
curl -vk --tlsv1.3 https://ckaquestion.k8s.local

# Verify ConfigMap is immutable:
kubectl get configmap nginx-config -n nginx-static -o yaml | grep immutable
# Should show: immutable: true

# Verify it cannot be edited (this should fail):
# kubectl edit configmap nginx-config -n nginx-static
# → Error: "the object ... is invalid: data: Forbidden: field is immutable when `immutable` is set"
```

---

# DOMAIN 4: Storage (10%)

---

### Q16 — Create a StorageClass and Set as Default

**Problem:**

**Tasks:**

1. Create a new StorageClass named `local-storage` with the provisioner `rancher.io/local-path`. Set the VolumeBindingMode to `WaitForFirstConsumer`. Do **not** make the SC default initially.
2. Patch the StorageClass to make it the default StorageClass.
3. Ensure `local-storage` is the **only** default class. Do not modify any existing Deployments or PersistentVolumeClaims.

**Reference Doc:** https://kubernetes.io/docs/concepts/storage/storage-classes/

**Solution Steps:**

1. Create the StorageClass:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
```

```bash
kubectl apply -f sc.yaml
```

2. Patch it to make it the default:

```bash
kubectl patch storageclass local-storage \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

Or declaratively — the annotation to add:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
  annotations:
    storageclass.kubernetes.io/is-default-class: "true" # ← Set to true
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
```

```bash
kubectl apply -f sc.yaml
```

3. Remove default annotation from any other default StorageClass:

```bash
# First, find any other default SC:
kubectl get sc
# Look for "(default)" marker

# Remove default from the old one (e.g., local-path):
kubectl patch storageclass local-path \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

Or declaratively:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
  annotations:
    storageclass.kubernetes.io/is-default-class: "false" # ← Set to false
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
```

```bash
kubectl apply -f sc-old.yaml
```

> **CRITICAL:** Only ONE StorageClass should be the default at a time. The question says "Ensure local-storage is the **only** default class."

**Verification:**

```bash
kubectl get sc
# local-storage should show (default)
# No other SC should show (default)
kubectl describe storageclass local-storage
```

---

### Q17 — Create PVC to Bind an Existing PV and Restore MariaDB Deployment

**Problem:** A user accidentally deleted the MariaDB Deployment in the `mariadb` namespace. The deployment was configured with persistent storage. Your responsibility is to re-establish the deployment while ensuring data is preserved by reusing the available PersistentVolume.

**Tasks:**

- A PersistentVolume already exists and is retained for reuse. Only one PV exists.
- Create a Persistent Volume Claim (PVC) named `mariadb` in the `mariadb` namespace with the spec:
  - Access Mode = `ReadWriteOnce`
  - Storage = `250Mi`
- Edit the MariaDB Deployment file located at `~/mariadb-deploy.yaml` to use the PVC created in the previous step
- Apply the updated Deployment file to the cluster
- Ensure the MariaDB Deployment is running and stable

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
>
> Or via `kubectl edit`:
>
> ```bash
> kubectl edit pv <pv-name>
> # Find and delete the entire `claimRef:` section under `spec:`
> ```

2. Create the PVC to bind to the PV:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb
  namespace: mariadb
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 250Mi
```

> **CRITICAL:** If the PV has a `storageClassName`, the PVC must match it exactly. If the PV has no `storageClassName`, you can omit or set `storageClassName: ""` in the PVC.

```bash
kubectl apply -f pvc.yaml
kubectl get pvc mariadb -n mariadb       # Should be Bound
kubectl get pv                           # PV should be Bound to mariadb/mariadb
```

3. Update the deployment file to use the PVC:

Edit `~/mariadb-deploy.yaml` and ensure the `claimName` references the PVC:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: maria-deployment
  namespace: mariadb
  labels:
    app: maria-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: maria-deployment
  template:
    metadata:
      labels:
        app: maria-deployment
    spec:
      containers:
        - name: mariadb
          image: mariadb:10.5
          volumeMounts:
            - name: mariadb-storage
              mountPath: /var/lib/mysql
      volumes:
        - name: mariadb-storage
          persistentVolumeClaim:
            claimName: mariadb # Must match PVC name
```

```bash
kubectl apply -f ~/mariadb-deploy.yaml
```

**Verification:**

```bash
kubectl get pvc -n mariadb               # STATUS should be Bound
kubectl get pv                           # PV should be Bound to mariadb/mariadb
kubectl get pods -n mariadb              # Pod should be Running
kubectl describe pod <pod-name> -n mariadb | grep -A 5 "Volumes"
```

---

# DOMAIN 5: Troubleshooting (30%)

---

### Q18 — Fix kube-apiserver After Cluster Migration (etcd Port Fix)

**Problem:** After a cluster migration, the controlplane kube-apiserver is not coming up. Before the migration, the etcd was external and in HA. After migration, the kube-apiserver is pointing to the etcd **peer port 2380** instead of the client port.

**Task:** Fix it.

**Reference Doc:** https://kubernetes.io/docs/tasks/debug/debug-cluster/

**Key Insight:** etcd uses **two ports**:

- **2379** — client port (this is what kube-apiserver should connect to)
- **2380** — peer port (used for etcd-to-etcd cluster communication)

After migration, the `--etcd-servers` flag in the apiserver manifest is pointing to port **2380** (peer). It must be changed to **2379** (client).

**Debugging Flowchart:**

```
kubectl get nodes fails?
├── Check kubelet: systemctl status kubelet
├── Check control plane containers: crictl ps -a | grep kube
│   └── kube-apiserver NOT running → check manifest
└── Check logs: crictl logs <container-id>
    └── Look for: "connection refused" or "etcd" errors
```

**Solution Steps:**

1. Check what's running and identify the error:

```bash
sudo systemctl status kubelet              # Should be active
sudo crictl ps -a | grep apiserver         # Check apiserver status
# Check apiserver logs for etcd connection errors:
sudo crictl logs $(sudo crictl ps -a | grep apiserver | awk '{print $1}')
# OR:
sudo journalctl -u kubelet | grep apiserver | tail -30
```

2. Inspect the kube-apiserver manifest:

```bash
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep etcd-servers
# You'll see: --etcd-servers=https://127.0.0.1:2380   ← WRONG (peer port)
```

3. Fix the etcd endpoint — change port from 2380 to 2379:

```bash
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Find: --etcd-servers=https://127.0.0.1:2380
# Change to: --etcd-servers=https://127.0.0.1:2379
```

> **TIP:** Also verify the following flags while editing:
>
> - `--etcd-cafile`, `--etcd-certfile`, `--etcd-keyfile` — ensure cert paths exist
> - `--advertise-address` — should match the node's current IP

4. Wait for kubelet to auto-restart the static pod (~30 seconds):

```bash
sudo crictl ps | grep apiserver
# Wait and watch for the apiserver container to restart
```

5. If the static pod doesn't restart, force kubelet restart:

```bash
sudo systemctl restart kubelet
```

6. If kube-scheduler is also broken:

```bash
kubectl -n kube-system get pods | grep kube-scheduler
sudo vi /etc/kubernetes/manifests/kube-scheduler.yaml
# Verify: --kubeconfig path, API server endpoint, cert references
```

**Verification:**

```bash
kubectl get nodes                          # Should respond and show nodes
kubectl get pods -n kube-system            # All control plane pods should be Running
kubectl cluster-info                       # Should show control plane endpoints
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
kubectl create priorityclass my-pc --value=1000 --description="desc"
```

### Card B — Exam Documentation Bookmarks

| Topic                   | URL                                                                                    |
| ----------------------- | -------------------------------------------------------------------------------------- |
| Container Runtimes      | https://kubernetes.io/docs/setup/production-environment/container-runtimes/            |
| Cluster Troubleshooting | https://kubernetes.io/docs/tasks/debug/debug-cluster/                                  |
| kubectl Cheat Sheet     | https://kubernetes.io/docs/reference/kubectl/cheatsheet/                               |
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
| Taints & Tolerations    | https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/          |
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
├─ 2. Is containerd/cri-dockerd running?
│     systemctl status containerd
│     systemctl status cri-docker
│     FIX: systemctl start containerd / cri-docker
│
├─ 3. Are static pods running?
│     crictl ps -a
│     crictl logs <container-id>
│     FIX: edit /etc/kubernetes/manifests/<component>.yaml
│
└─ 4. Specific component down?
      ├─ apiserver: check --etcd-servers (port 2379 not 2380!), cert paths, --advertise-address
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
6. CRD/HPA/PriorityClass = fast imperative commands = do these first
7. Troubleshooting = follow the flowchart, don't guess
```

---

_18 questions based on the actual CKA exam. Every solution verified against official Kubernetes documentation patterns. Trust your preparation and go claim that CKA._
