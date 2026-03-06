# CKA Simulator 1 - Complete Study Guide

> [!NOTE]
> This is a comprehensive study guide for the CKA (Certified Kubernetes Administrator) exam based on the Killer.sh Simulator. Each question includes detailed context, step-by-step solutions, troubleshooting tips, and official documentation links.

---

## Table of Contents

1. [Question 1: Kubeconfig Contexts](#question-1-kubeconfig-contexts)
2. [Question 2: MinIO Operator, CRD Config, Helm Install](#question-2-minio-operator-crd-config-helm-install)
3. [Question 3: Scale Down StatefulSet](#question-3-scale-down-statefulset)
4. [Question 4: Find Pods First to be Terminated](#question-4-find-pods-first-to-be-terminated)
5. [Question 5: Kustomize Configure HPA Autoscaler](#question-5-kustomize-configure-hpa-autoscaler)
6. [Question 6: Storage, PV, PVC, Pod Volume](#question-6-storage-pv-pvc-pod-volume)
7. [Question 7: Node and Pod Resource Usage](#question-7-node-and-pod-resource-usage)
8. [Question 8: Update Kubernetes Version and Join Cluster](#question-8-update-kubernetes-version-and-join-cluster)
9. [Question 9: Contact K8s API from Inside Pod](#question-9-contact-k8s-api-from-inside-pod)
10. [Question 10: RBAC ServiceAccount Role RoleBinding](#question-10-rbac-serviceaccount-role-rolebinding)
11. [Question 11: DaemonSet on All Nodes](#question-11-daemonset-on-all-nodes)
12. [Question 12: Deployment on All Nodes](#question-12-deployment-on-all-nodes)
13. [Question 13: Gateway API HTTPRoute](#question-13-gateway-api-httproute)
14. [Question 14: Check Certificate Validity](#question-14-check-certificate-validity)
15. [Question 15: NetworkPolicy](#question-15-networkpolicy)
16. [Question 16: Update CoreDNS Configuration](#question-16-update-coredns-configuration)
17. [Question 17: Find Container of Pod and Check Info](#question-17-find-container-of-pod-and-check-info)
18. [Preview Question 1: ETCD Information](#preview-question-1-etcd-information)
19. [Preview Question 2: Kube-Proxy iptables](#preview-question-2-kube-proxy-iptables)
20. [Preview Question 3: Change Service CIDR](#preview-question-3-change-service-cidr)

---

## Question 1: Kubeconfig Contexts

### Context

**What is being tested:** Your ability to work with kubeconfig files, extract context information, and decode Base64-encoded certificates.

**Why this matters:** In production environments, you often work with multiple clusters and need to understand how kubeconfig files store authentication and context information. The CKA tests your ability to manipulate these files using `kubectl config` commands.

**Task Summary:**

1. Write all context names from a kubeconfig file
2. Write the current context name
3. Extract and decode a user's client certificate

> [!IMPORTANT]
> **Solve this question on:** `ssh cka9412`

### Solution

#### Step 1: List all context names

```bash
# Connect to the instance
ssh cka9412

# List all contexts using kubectl config
kubectl --kubeconfig /opt/course/1/kubeconfig config get-contexts -o name

# Save to file
kubectl --kubeconfig /opt/course/1/kubeconfig config get-contexts -o name > /opt/course/1/contexts
```

#### Step 2: Get the current context

```bash
# Get current context
kubectl --kubeconfig /opt/course/1/kubeconfig config current-context

# Save to file
kubectl --kubeconfig /opt/course/1/kubeconfig config current-context > /opt/course/1/current-context
```

#### Step 3: Extract and decode the client certificate

```bash
# View the raw kubeconfig to see certificate data
kubectl --kubeconfig /opt/course/1/kubeconfig config view --raw -o yaml

# Extract the client-certificate-data and decode it
# Method 1: Using jsonpath (automated)
kubectl --kubeconfig /opt/course/1/kubeconfig config view --raw \
  -o jsonpath="{.users[?(@.name=='account-0027@internal')].user.client-certificate-data}" \
  | base64 -d > /opt/course/1/cert

# Method 2: If you know the user index
kubectl --kubeconfig /opt/course/1/kubeconfig config view --raw \
  -o jsonpath="{.users[0].user.client-certificate-data}" | base64 -d > /opt/course/1/cert
```

### Tips & Troubleshooting

> [!TIP]
> **Alternative approaches:**
>
> - You can open the kubeconfig file directly with `vim` or `cat` and manually copy the Base64 data
> - Use `yq` for YAML parsing: `yq '.users[] | select(.name=="account-0027@internal") | .user.client-certificate-data' kubeconfig | base64 -d`

> [!WARNING]
>
> - The `--raw` flag is essential to see sensitive data like certificates
> - Without `--raw`, kubectl redacts certificate data for security

**Common Issues:**

- If `base64 -d` doesn't work, try `base64 --decode` (depends on OS)
- Ensure you're extracting data for the correct user

### References

- [Configure Access to Multiple Clusters](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)
- [Organizing Cluster Access Using kubeconfig Files](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)

---

## Question 2: MinIO Operator, CRD Config, Helm Install

### Context

**What is being tested:** Your ability to install Helm charts, understand Custom Resource Definitions (CRDs), and work with Kubernetes Operators.

**Why this matters:** Operators extend Kubernetes functionality by managing complex applications. Understanding how to deploy operators via Helm and configure their CRDs is essential for managing production workloads.

**Key Concepts:**

- **Helm Chart**: Kubernetes YAML templates bundled into a package
- **Helm Release**: An installed instance of a Chart
- **Operator**: A Pod that manages CRDs and communicates with the K8s API
- **CRD**: Custom Resource Definition - extends the Kubernetes API

**Task Summary:**

1. Create namespace `minio`
2. Install MinIO Operator Helm chart
3. Update Tenant CRD to enable SFTP
4. Create the Tenant resource

> [!IMPORTANT]
> **Solve this question on:** `ssh cka7968`

### Solution

#### Step 1: Create the Namespace

```bash
ssh cka7968

kubectl create namespace minio
```

#### Step 2: Install the MinIO Operator via Helm

```bash
# Check available Helm repos
helm repo list

# Search for available charts
helm search repo minio

# Install the operator
helm -n minio install minio-operator minio/operator

# Verify installation
helm -n minio list
kubectl -n minio get pods
```

#### Step 3: Update the Tenant YAML

```bash
# View the CRD to understand available fields
kubectl describe crd tenants.minio.min.io | grep -i feature -A 20

# Edit the tenant yaml
vim /opt/course/2/minio-tenant.yaml
```

Add `enableSFTP: true` under `features`:

```yaml
apiVersion: minio.min.io/v2
kind: Tenant
metadata:
  name: tenant
  namespace: minio
spec:
  features:
    bucketDNS: false
    enableSFTP: true # Add this line
  image: quay.io/minio/minio:latest
  # ... rest of spec
```

#### Step 4: Apply the Tenant Resource

```bash
kubectl apply -f /opt/course/2/minio-tenant.yaml

# Verify
kubectl -n minio get tenant
```

### Tips & Troubleshooting

> [!TIP]
> **Exploring CRDs:**
>
> ```bash
> # List all CRDs
> kubectl get crd
>
> # Describe a CRD to see its structure
> kubectl describe crd <crd-name>
>
> # View a specific field structure
> kubectl explain tenant.spec.features
> ```

> [!TIP]
> **Helm Commands:**
>
> ```bash
> # Rollback if needed
> helm -n minio rollback minio-operator 1
>
> # Uninstall
> helm -n minio uninstall minio-operator
>
> # Get release values
> helm -n minio get values minio-operator
> ```

### References

- [Helm Documentation](https://helm.sh/docs/)
- [Custom Resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
- [Operator Pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)

---

## Question 3: Scale Down StatefulSet

### Context

**What is being tested:** Your ability to identify the controller managing Pods and scale a StatefulSet.

**Why this matters:** StatefulSets are used for stateful applications (databases, message queues) where Pod identity matters. Unlike Deployments, StatefulSets maintain stable network identities and ordered deployment/scaling.

**Task Summary:** Scale down o3db StatefulSet from 2 to 1 replica in namespace `project-h800`

> [!IMPORTANT]
> **Solve this question on:** `ssh cka3962`

### Solution

#### Step 1: Identify the Controller

```bash
ssh cka3962

# Check the Pods
kubectl -n project-h800 get pods | grep o3db

# Find what manages these Pods
kubectl -n project-h800 get deploy,sts,ds | grep o3db

# Alternative: Check Pod labels to identify controller
kubectl -n project-h800 get pod --show-labels | grep o3db
```

#### Step 2: Scale the StatefulSet

```bash
kubectl -n project-h800 scale statefulset o3db --replicas=1

# Verify
kubectl -n project-h800 get sts o3db
kubectl -n project-h800 get pods | grep o3db
```

### Tips & Troubleshooting

> [!TIP]
> **Identifying Pod Controllers:**
>
> - Pod name ending with random string (e.g., `-7b5f4c9d8-xyzab`): Likely managed by Deployment
> - Pod name ending with ordinal (e.g., `-0`, `-1`): Likely managed by StatefulSet
> - Pod running on every node: Likely managed by DaemonSet

> [!TIP]
> **Alternative Scaling:**
>
> ```bash
> # Using patch
> kubectl -n project-h800 patch sts o3db -p '{"spec":{"replicas":1}}'
>
> # Using edit
> kubectl -n project-h800 edit sts o3db
> ```

### References

- [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Scaling a StatefulSet](https://kubernetes.io/docs/tasks/run-application/scale-stateful-set/)

---

## Question 4: Find Pods First to be Terminated

### Context

**What is being tested:** Understanding Kubernetes Quality of Service (QoS) classes and how resource requests/limits affect Pod eviction priority.

**Why this matters:** When nodes run low on resources, Kubernetes uses QoS classes to decide which Pods to evict first. Understanding this helps you design resilient applications.

**QoS Classes (from most to least protected):**

1. **Guaranteed**: All containers have equal memory/CPU requests and limits
2. **Burstable**: At least one container has a memory or CPU request
3. **BestEffort**: No containers have any requests or limits (evicted first!)

**Task Summary:** Find Pods without resource requests (BestEffort) that would be evicted first

> [!IMPORTANT]
> **Solve this question on:** `ssh cka2556`

### Solution

#### Step 1: Analyze Pod Resources

```bash
ssh cka2556

# Method 1: Manual inspection
kubectl -n project-c13 describe pod | less -p Requests

# Method 2: Using grep to find Pods and their requests
kubectl -n project-c13 describe pod | grep -A 3 -E 'Requests|^Name:'
```

#### Step 2: Use JSONPath for Automated Analysis

```bash
# List Pods with their resource requests
kubectl -n project-c13 get pod -o jsonpath="{range .items[*]} {.metadata.name}{.spec.containers[*].resources}{'\n'}{end}"

# Check QoS classes directly
kubectl -n project-c13 get pods -o jsonpath="{range .items[*]}{.metadata.name} {.status.qosClass}{'\n'}{end}"
```

#### Step 3: Write the Answer

```bash
# Find BestEffort Pods and write to file
kubectl -n project-c13 get pods -o jsonpath="{range .items[*]}{.metadata.name} {.status.qosClass}{'\n'}{end}" \
  | grep BestEffort | awk '{print $1}' > /opt/course/4/pods-terminated-first.txt
```

### Tips & Troubleshooting

> [!TIP]
> **Understanding Eviction Priority:**
>
> 1. Pods exceeding their requests are evicted before those at or below
> 2. BestEffort Pods are always evicted first
> 3. Priority and PriorityClass also affect eviction order

> [!TIP]
> **Best Practice:** Always set resource requests and limits! Use monitoring tools like Prometheus to determine appropriate values.

```bash
# Check actual resource usage
kubectl top pod -n project-c13
```

### References

- [Configure Quality of Service for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/)
- [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

---

## Question 5: Kustomize Configure HPA Autoscaler

### Context

**What is being tested:** Using Kustomize to manage environment-specific configurations and creating HorizontalPodAutoscalers (HPA).

**Why this matters:** Kustomize allows you to maintain a base configuration and customize it for different environments (dev, staging, prod) without duplicating YAML files.

**Kustomize Key Concepts:**

- **Base**: Common configuration shared across environments
- **Overlay**: Environment-specific customizations
- **Patches**: Modifications applied to base resources
- **Transformers**: Modify resources (e.g., add namespace)

**Task Summary:**

1. Remove ConfigMap from base, staging, and prod
2. Add HPA with min 2, max 4 replicas, 50% CPU target
3. Make prod use max 6 replicas
4. Apply changes

> [!IMPORTANT]
> **Solve this question on:** `ssh cka5774`

### Solution

#### Step 1: Understand the Structure

```bash
ssh cka5774
cd /opt/course/5/api-gateway

# View directory structure
ls -la
# base/  prod/  staging/

# Preview current staging config
kubectl kustomize staging

# Preview current prod config
kubectl kustomize prod
```

#### Step 2: Remove ConfigMap from All Environments

Edit `base/api-gateway.yaml`, `staging/api-gateway.yaml`, and `prod/api-gateway.yaml` to remove the ConfigMap.

```bash
# Verify removal
kubectl kustomize staging | grep -i configmap
```

#### Step 3: Add HPA to Base

Edit `base/api-gateway.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-gateway
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-gateway
  minReplicas: 2
  maxReplicas: 4
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
---
# ... rest of base resources
```

#### Step 4: Override maxReplicas in Prod

Edit `prod/api-gateway.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-gateway
spec:
  maxReplicas: 6
---
# ... rest of prod patches
```

#### Step 5: Apply Changes

```bash
# Preview and apply staging
kubectl kustomize staging | kubectl diff -f -
kubectl kustomize staging | kubectl apply -f -

# Preview and apply prod
kubectl kustomize prod | kubectl diff -f -
kubectl kustomize prod | kubectl apply -f -

# Verify
kubectl -n api-gateway-staging get hpa
kubectl -n api-gateway-prod get hpa
```

#### Step 6: Clean Up Old ConfigMaps

```bash
# Kustomize doesn't delete resources - do it manually
kubectl -n api-gateway-staging delete cm horizontal-scaling-config
kubectl -n api-gateway-prod delete cm horizontal-scaling-config
```

### Tips & Troubleshooting

> [!TIP]
> **Kustomize vs Helm:**
>
> - **Kustomize**: No state management, simple patching, built into kubectl
> - **Helm**: Maintains release state, can track and delete resources

> [!WARNING]
> When using Kustomize, you must manually delete resources that are removed from your manifests. Kustomize doesn't track state.

### References

- [Kustomize Documentation](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

---

## Question 6: Storage, PV, PVC, Pod Volume

### Context

**What is being tested:** Creating PersistentVolumes (PV), PersistentVolumeClaims (PVC), and mounting volumes in Deployments.

**Why this matters:** Persistent storage is essential for stateful applications. Understanding the binding between PV and PVC and how to mount volumes is fundamental for the CKA.

**Storage Concepts:**

- **PersistentVolume (PV)**: Cluster resource representing physical storage
- **PersistentVolumeClaim (PVC)**: Request for storage by a user
- **StorageClass**: Defines "classes" of storage with different properties

**Task Summary:**

1. Create a PV (2Gi, ReadWriteOnce, hostPath)
2. Create a PVC that binds to the PV
3. Create a Deployment mounting the volume

> [!IMPORTANT]
> **Solve this question on:** `ssh cka7968`

### Solution

#### Step 1: Create the PersistentVolume

```bash
ssh cka7968

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: safari-pv
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/Volumes/Data"
EOF
```

#### Step 2: Create the PersistentVolumeClaim

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: safari-pvc
  namespace: project-t230
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
EOF
```

#### Step 3: Verify Binding

```bash
kubectl -n project-t230 get pv,pvc
# Both should show status: Bound
```

#### Step 4: Create the Deployment with Volume Mount

```bash
# Generate base YAML
kubectl -n project-t230 create deployment safari --image=httpd:2-alpine \
  --dry-run=client -o yaml > safari-deploy.yaml
```

Edit to add volume:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: safari
  namespace: project-t230
spec:
  replicas: 1
  selector:
    matchLabels:
      app: safari
  template:
    metadata:
      labels:
        app: safari
    spec:
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: safari-pvc
      containers:
        - name: httpd
          image: httpd:2-alpine
          volumeMounts:
            - name: data
              mountPath: /tmp/safari-data
```

```bash
kubectl apply -f safari-deploy.yaml

# Verify mount
kubectl -n project-t230 describe pod -l app=safari | grep -A2 Mounts
```

### Tips & Troubleshooting

> [!TIP]
> **PV and PVC Binding Rules:**
>
> - Capacity: PVC request ≤ PV capacity
> - Access Modes: Must match
> - StorageClass: Must match (or both be empty)
> - Selector: If PVC has selector, PV must match labels

> [!WARNING]
> **hostPath Warning:** Using hostPath is a security risk and data is node-specific. Only use for testing!

### References

- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Configure a Pod to Use a PersistentVolume](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/)

---

## Question 7: Node and Pod Resource Usage

### Context

**What is being tested:** Using `kubectl top` to view resource consumption, which requires the metrics-server.

**Why this matters:** Monitoring resource usage helps with capacity planning, troubleshooting performance issues, and setting appropriate resource requests/limits.

**Task Summary:** Create scripts to show node and pod resource usage

> [!IMPORTANT]
> **Solve this question on:** `ssh cka5774`

### Solution

#### Step 1: Create Node Resource Script

```bash
ssh cka5774

cat > /opt/course/7/node.sh << 'EOF'
kubectl top node
EOF

chmod +x /opt/course/7/node.sh
```

#### Step 2: Create Pod Resource Script

```bash
cat > /opt/course/7/pod.sh << 'EOF'
kubectl top pod --containers=true
EOF

chmod +x /opt/course/7/pod.sh
```

### Tips & Troubleshooting

> [!TIP]
> **Useful kubectl top Options:**
>
> ```bash
> # Sort by CPU
> kubectl top pod --sort-by=cpu
>
> # Sort by memory
> kubectl top pod --sort-by=memory
>
> # Specific namespace
> kubectl top pod -n kube-system
>
> # All namespaces
> kubectl top pod -A
> ```

> [!WARNING]
> Don't use aliases like `k` in scripts - they may not be available in all environments.

### References

- [Resource Metrics Pipeline](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/)
- [Tools for Monitoring Resources](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-usage-monitoring/)

---

## Question 8: Update Kubernetes Version and Join Cluster

### Context

**What is being tested:** Upgrading Kubernetes components on a worker node and joining it to a cluster using kubeadm.

**Why this matters:** Cluster maintenance includes keeping all nodes on compatible Kubernetes versions. Understanding the upgrade process and how to add nodes is critical for cluster administration.

**Upgrade Order:**

1. kubeadm (already at correct version in this case)
2. kubelet
3. kubectl
4. Join cluster (if not yet joined)

**Task Summary:**

1. Update worker node to controlplane's Kubernetes version
2. Join the node to the cluster

> [!IMPORTANT]
> **Solve this question on:** `ssh cka3962`

### Solution

#### Step 1: Check Versions

```bash
ssh cka3962

# Check controlplane version
kubectl get nodes

# Connect to worker
ssh cka3962-node1
sudo -i

# Check current versions
kubelet --version
kubeadm version
```

#### Step 2: Update kubelet and kubectl

```bash
# Update package index
apt update

# Check available versions
apt show kubelet -a | grep 1.34

# Install specific versions
apt install kubelet=1.34.1-1.1 kubectl=1.34.1-1.1 -y

# Verify
kubelet --version
```

#### Step 3: Generate Join Command on Controlplane

```bash
# Exit back to controlplane
exit
exit

# On controlplane, generate join command
sudo kubeadm token create --print-join-command
```

#### Step 4: Join the Cluster

```bash
# SSH to worker node
ssh cka3962-node1
sudo -i

# Run the join command (from previous step)
kubeadm join 192.168.100.31:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>

# Restart kubelet
systemctl restart kubelet
systemctl status kubelet
```

#### Step 5: Verify

```bash
# On controlplane
kubectl get nodes
```

### Tips & Troubleshooting

> [!TIP]
> **If join fails:**
>
> ```bash
> # Reset kubeadm state on worker
> kubeadm reset
>
> # Then try join again
> ```

> [!TIP]
> **Token Management:**
>
> ```bash
> # List existing tokens
> kubeadm token list
>
> # Create token with custom TTL
> kubeadm token create --ttl 2h --print-join-command
> ```

### References

- [Upgrading kubeadm clusters](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
- [Adding additional nodes](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#join-nodes)

---

## Question 9: Contact K8s API from Inside Pod

### Context

**What is being tested:** Understanding how to authenticate to the Kubernetes API from within a Pod using ServiceAccount tokens.

**Why this matters:** Many applications (operators, controllers, CI/CD tools) need to interact with the Kubernetes API from inside the cluster. Understanding ServiceAccount authentication is essential.

**Key Concepts:**

- ServiceAccount tokens are automatically mounted at `/var/run/secrets/kubernetes.io/serviceaccount/`
- The token file contains a JWT for API authentication
- The CA certificate validates the API server's TLS

**Task Summary:**

1. Create a Pod using a specific ServiceAccount
2. Query the Kubernetes API for all Secrets using curl
3. Save the result to a file

> [!IMPORTANT]
> **Solve this question on:** `ssh cka9412`

### Solution

#### Step 1: Create Pod with ServiceAccount

```bash
ssh cka9412

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: api-contact
  namespace: project-swan
spec:
  serviceAccountName: secret-reader
  containers:
  - name: api-contact
    image: nginx:1-alpine
EOF
```

#### Step 2: Exec into Pod and Query API

```bash
kubectl -n project-swan exec api-contact -it -- sh

# Inside the pod:
# Set up variables
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Query secrets (with proper TLS)
curl --cacert ${CACERT} \
  -H "Authorization: Bearer ${TOKEN}" \
  https://kubernetes.default/api/v1/secrets

# Or with -k to skip certificate verification (not recommended)
curl -k -H "Authorization: Bearer ${TOKEN}" \
  https://kubernetes.default/api/v1/secrets > result.json

exit
```

#### Step 3: Copy Result to Host

```bash
kubectl -n project-swan exec api-contact -- cat result.json > /opt/course/9/result.json
```

### Tips & Troubleshooting

> [!TIP]
> **Verify ServiceAccount Permissions:**
>
> ```bash
> kubectl auth can-i get secrets --as system:serviceaccount:project-swan:secret-reader
> ```

> [!TIP]
> **API Endpoints:**
>
> - `https://kubernetes.default` - Default service for API
> - `/api/v1/` - Core API
> - `/apis/apps/v1/` - Apps API group

> [!TIP]
> **Finding the API Server:**
>
> ```bash
> # Inside pod
> env | grep KUBERNETES
> # Shows KUBERNETES_SERVICE_HOST and KUBERNETES_SERVICE_PORT
> ```

### References

- [Access Clusters Using the Kubernetes API](https://kubernetes.io/docs/tasks/administer-cluster/access-cluster-api/)
- [Accessing the API from within a Pod](https://kubernetes.io/docs/tasks/run-application/access-api-from-pod/)

---

## Question 10: RBAC ServiceAccount Role RoleBinding

### Context

**What is being tested:** Creating RBAC resources to grant specific permissions to a ServiceAccount.

**Why this matters:** RBAC (Role-Based Access Control) is the standard authorization mechanism in Kubernetes. Understanding how to grant least-privilege access is essential for security.

**RBAC Combinations:**
| Role Type | Binding Type | Scope |
|-----------|--------------|-------|
| Role | RoleBinding | Single namespace |
| ClusterRole | ClusterRoleBinding | Cluster-wide |
| ClusterRole | RoleBinding | ClusterRole limited to namespace |

**Task Summary:** Create ServiceAccount, Role, and RoleBinding allowing create on Secrets and ConfigMaps

> [!IMPORTANT]
> **Solve this question on:** `ssh cka3962`

### Solution

#### Step 1: Create ServiceAccount

```bash
ssh cka3962

kubectl -n project-hamster create serviceaccount processor
```

#### Step 2: Create Role

```bash
kubectl -n project-hamster create role processor \
  --verb=create \
  --resource=secrets \
  --resource=configmaps
```

#### Step 3: Create RoleBinding

```bash
kubectl -n project-hamster create rolebinding processor \
  --role=processor \
  --serviceaccount=project-hamster:processor
```

#### Step 4: Verify Permissions

```bash
# Should return "yes"
kubectl -n project-hamster auth can-i create secret \
  --as system:serviceaccount:project-hamster:processor

kubectl -n project-hamster auth can-i create configmap \
  --as system:serviceaccount:project-hamster:processor

# Should return "no"
kubectl -n project-hamster auth can-i delete secret \
  --as system:serviceaccount:project-hamster:processor
```

### Tips & Troubleshooting

> [!TIP]
> **View Role Definition:**
>
> ```bash
> kubectl -n project-hamster get role processor -o yaml
> ```

> [!TIP]
> **Common Verbs:** `get`, `list`, `watch`, `create`, `update`, `patch`, `delete`

> [!TIP]
> **Using ClusterRole for Reusability:**
> Create a ClusterRole, then use RoleBinding to limit it to specific namespaces.

### References

- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Configure Service Accounts for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)

---

## Question 11: DaemonSet on All Nodes

### Context

**What is being tested:** Creating a DaemonSet that runs on all nodes, including control-plane nodes with taints.

**Why this matters:** DaemonSets are used for cluster-wide services like log collectors, monitoring agents, and networking plugins. Understanding tolerations is crucial for running Pods on tainted nodes.

**Key Concepts:**

- DaemonSets run exactly one Pod per node
- Control-plane nodes have a `NoSchedule` taint
- Tolerations allow Pods to run on tainted nodes

**Task Summary:** Create a DaemonSet running on ALL nodes including control-plane

> [!IMPORTANT]
> **Solve this question on:** `ssh cka2556`

### Solution

#### Step 1: Create DaemonSet YAML

```bash
ssh cka2556

# Generate deployment template and convert to DaemonSet
kubectl -n project-tiger create deployment ds-important \
  --image=httpd:2-alpine --dry-run=client -o yaml > 11.yaml
```

Edit to create DaemonSet:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ds-important
  namespace: project-tiger
  labels:
    id: ds-important
    uuid: 18426a0b-5f59-4e10-923f-c0e078e82462
spec:
  selector:
    matchLabels:
      id: ds-important
      uuid: 18426a0b-5f59-4e10-923f-c0e078e82462
  template:
    metadata:
      labels:
        id: ds-important
        uuid: 18426a0b-5f59-4e10-923f-c0e078e82462
    spec:
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          effect: NoSchedule
      containers:
        - name: ds-important
          image: httpd:2-alpine
          resources:
            requests:
              cpu: 10m
              memory: 10Mi
```

#### Step 2: Apply and Verify

```bash
kubectl apply -f 11.yaml

# Check DaemonSet
kubectl -n project-tiger get ds

# Verify Pods on all nodes
kubectl -n project-tiger get pod -l id=ds-important -o wide
```

### Tips & Troubleshooting

> [!TIP]
> **View Node Taints:**
>
> ```bash
> kubectl describe node <node-name> | grep -A5 Taints
> ```

> [!TIP]
> **Tolerate All Taints:**
>
> ```yaml
> tolerations:
>   - operator: Exists
> ```

### References

- [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)

---

## Question 12: Deployment on All Nodes

### Context

**What is being tested:** Using Pod Anti-Affinity or Topology Spread Constraints to ensure Pods are distributed across nodes.

**Why this matters:** High availability requires spreading Pods across failure domains. Anti-affinity and topology spread constraints prevent all replicas from landing on the same node.

**Two Approaches:**

1. **Pod Anti-Affinity**: Pods avoid nodes where matching Pods exist
2. **Topology Spread Constraints**: Ensure even distribution across topology domains

**Task Summary:** Create a Deployment where each Pod runs on a different worker node

> [!IMPORTANT]
> **Solve this question on:** `ssh cka2556`

### Solution

#### Option A: Using Pod Anti-Affinity

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-important
  namespace: project-tiger
  labels:
    id: very-important
spec:
  replicas: 3
  selector:
    matchLabels:
      id: very-important
  template:
    metadata:
      labels:
        id: very-important
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: id
                    operator: In
                    values:
                      - very-important
              topologyKey: kubernetes.io/hostname
      containers:
        - name: container1
          image: nginx:1-alpine
        - name: container2
          image: google/pause
```

#### Option B: Using Topology Spread Constraints

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-important
  namespace: project-tiger
  labels:
    id: very-important
spec:
  replicas: 3
  selector:
    matchLabels:
      id: very-important
  template:
    metadata:
      labels:
        id: very-important
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              id: very-important
      containers:
        - name: container1
          image: nginx:1-alpine
        - name: container2
          image: google/pause
```

#### Verify

```bash
kubectl apply -f 12.yaml

# Check deployment status (2/3 ready expected)
kubectl -n project-tiger get deploy deploy-important

# One Pod should be Pending
kubectl -n project-tiger get pod -l id=very-important -o wide
```

### Tips & Troubleshooting

> [!TIP]
> **Debugging Pending Pods:**
>
> ```bash
> kubectl describe pod <pending-pod-name>
> # Look for Events showing why scheduling failed
> ```

> [!TIP]
> **Soft vs Hard Constraints:**
>
> - `requiredDuringSchedulingIgnoredDuringExecution`: Hard requirement
> - `preferredDuringSchedulingIgnoredDuringExecution`: Soft preference

### References

- [Pod Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)
- [Affinity and Anti-Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)

---

## Question 13: Gateway API HTTPRoute

### Context

**What is being tested:** Using the Kubernetes Gateway API to create HTTPRoutes, the modern replacement for Ingress.

**Why this matters:** Gateway API is the next generation of Kubernetes ingress. It provides more flexibility, better extensibility, and a cleaner separation between infrastructure (Gateway) and routing (HTTPRoute).

**Gateway API Resources:**

- **GatewayClass**: Defines a class of gateways (like StorageClass)
- **Gateway**: Infrastructure configuration (ports, TLS)
- **HTTPRoute**: Routing rules for HTTP traffic

**Task Summary:**

1. Create HTTPRoute replicating existing Ingress routes
2. Add conditional routing based on User-Agent header

> [!IMPORTANT]
> **Solve this question on:** `ssh cka7968`

### Solution

#### Step 1: Create HTTPRoute

```bash
ssh cka7968

cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: traffic-director
  namespace: project-r500
spec:
  parentRefs:
    - name: main
  hostnames:
    - "r500.gateway"
  rules:
    # Route /desktop to web-desktop service
    - matches:
        - path:
            type: PathPrefix
            value: /desktop
      backendRefs:
        - name: web-desktop
          port: 80
    # Route /mobile to web-mobile service
    - matches:
        - path:
            type: PathPrefix
            value: /mobile
      backendRefs:
        - name: web-mobile
          port: 80
    # Route /auto to mobile if User-Agent is "mobile"
    - matches:
        - path:
            type: PathPrefix
            value: /auto
          headers:
            - type: Exact
              name: user-agent
              value: mobile
      backendRefs:
        - name: web-mobile
          port: 80
    # Route /auto to desktop otherwise (catch-all)
    - matches:
        - path:
            type: PathPrefix
            value: /auto
      backendRefs:
        - name: web-desktop
          port: 80
EOF
```

#### Step 2: Test

```bash
curl r500.gateway:30080/desktop
curl r500.gateway:30080/mobile
curl -H "User-Agent: mobile" r500.gateway:30080/auto
curl r500.gateway:30080/auto
```

### Tips & Troubleshooting

> [!TIP]
> **Rule Order Matters!** More specific rules must come before catch-all rules.

> [!WARNING]
> **AND vs OR in matches:**
>
> ```yaml
> # AND - both conditions must match
> - path: /auto
>   headers:
>     - name: user-agent
>       value: mobile
>
> # OR - either condition matches
> - path: /auto
> - headers:
>     - name: user-agent
>       value: mobile
> ```

### References

- [Gateway API Documentation](https://gateway-api.sigs.k8s.io/)
- [HTTPRoute](https://gateway-api.sigs.k8s.io/api-types/httproute/)

---

## Question 14: Check Certificate Validity

### Context

**What is being tested:** Inspecting TLS certificates and understanding certificate management in Kubernetes.

**Why this matters:** Kubernetes uses TLS certificates extensively. Knowing how to check expiration dates and renew certificates is critical for cluster maintenance.

**Task Summary:**

1. Check kube-apiserver certificate expiration using openssl
2. Write the renewal command

> [!IMPORTANT]
> **Solve this question on:** `ssh cka9412`

### Solution

#### Step 1: Find and Check Certificate

```bash
ssh cka9412
sudo -i

# Find apiserver certificate
find /etc/kubernetes/pki -name "*apiserver*"

# Check expiration
openssl x509 -noout -text -in /etc/kubernetes/pki/apiserver.crt | grep Validity -A2

# Write expiration to file
openssl x509 -noout -enddate -in /etc/kubernetes/pki/apiserver.crt > /opt/course/14/expiration
```

#### Step 2: Compare with kubeadm

```bash
kubeadm certs check-expiration
```

#### Step 3: Write Renewal Command

```bash
echo "kubeadm certs renew apiserver" > /opt/course/14/kubeadm-renew-certs.sh
chmod +x /opt/course/14/kubeadm-renew-certs.sh
```

### Tips & Troubleshooting

> [!TIP]
> **Check All Certificates:**
>
> ```bash
> kubeadm certs check-expiration
> ```

> [!TIP]
> **Renew All Certificates:**
>
> ```bash
> kubeadm certs renew all
> ```

> [!WARNING]
> After renewing certificates, restart control plane components!

### References

- [Certificate Management with kubeadm](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)
- [PKI certificates and requirements](https://kubernetes.io/docs/setup/best-practices/certificates/)

---

## Question 15: NetworkPolicy

### Context

**What is being tested:** Creating NetworkPolicies to control Pod-to-Pod traffic.

**Why this matters:** NetworkPolicies implement micro-segmentation for security. By default, all Pods can communicate; policies restrict this to only allowed traffic.

**Key Concepts:**

- Policies are additive (union of all policies)
- An empty `podSelector` selects all Pods in the namespace
- If no policy matches, traffic is allowed by default

**Task Summary:** Create NetworkPolicy allowing backend Pods to connect only to specific database Pods on specific ports

> [!IMPORTANT]
> **Solve this question on:** `ssh cka7968`

### Solution

#### Step 1: Understand Current State

```bash
ssh cka7968

kubectl -n project-snake get pod -L app -o wide

# Test current connectivity
kubectl -n project-snake exec backend-0 -- curl -s db1-0:1111
kubectl -n project-snake exec backend-0 -- curl -s db2-0:2222
kubectl -n project-snake exec backend-0 -- curl -s vault-0:3333
```

#### Step 2: Create NetworkPolicy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np-backend
  namespace: project-snake
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Egress
  egress:
    # Rule 1: Allow to db1 on port 1111
    - to:
        - podSelector:
            matchLabels:
              app: db1
      ports:
        - protocol: TCP
          port: 1111
    # Rule 2: Allow to db2 on port 2222
    - to:
        - podSelector:
            matchLabels:
              app: db2
      ports:
        - protocol: TCP
          port: 2222
```

```bash
kubectl apply -f np.yaml
```

#### Step 3: Verify

```bash
# Should work
kubectl -n project-snake exec backend-0 -- curl -s db1-0:1111
kubectl -n project-snake exec backend-0 -- curl -s db2-0:2222

# Should timeout/fail
kubectl -n project-snake exec backend-0 -- curl -s vault-0:3333 --connect-timeout 2
```

### Tips & Troubleshooting

> [!WARNING]
> **Common Mistake - Incorrect Rule Structure:**
> Separate rules = different conditions (OR)
> Same rule with multiple `to` entries = alternative destinations
> Same rule with multiple `ports` = alternative ports

> [!TIP]
> **Debug NetworkPolicy:**
>
> ```bash
> kubectl describe netpol np-backend
> ```

### References

- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Declare Network Policy](https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/)

---

## Question 16: Update CoreDNS Configuration

### Context

**What is being tested:** Modifying CoreDNS configuration to add custom DNS domains.

**Why this matters:** CoreDNS provides DNS resolution in Kubernetes clusters. Understanding how to customize it enables advanced networking configurations like split-horizon DNS or custom domains.

**Task Summary:**

1. Backup CoreDNS ConfigMap
2. Add custom domain that works like cluster.local
3. Test and verify

> [!IMPORTANT]
> **Solve this question on:** `ssh cka5774`

### Solution

#### Step 1: Backup Current Configuration

```bash
ssh cka5774

kubectl -n kube-system get cm coredns -o yaml > /opt/course/16/coredns_backup.yaml
```

#### Step 2: Edit CoreDNS ConfigMap

```bash
kubectl -n kube-system edit cm coredns
```

Add `custom-domain` to the kubernetes plugin line:

```
kubernetes custom-domain cluster.local in-addr.arpa ip6.arpa {
```

#### Step 3: Restart CoreDNS

```bash
kubectl -n kube-system rollout restart deploy coredns

# Verify Pods are running
kubectl -n kube-system get pods -l k8s-app=kube-dns
```

#### Step 4: Test

```bash
kubectl run bb --image=busybox:1 -- sleep 1d
kubectl exec bb -- nslookup kubernetes.default.svc.custom-domain
kubectl exec bb -- nslookup kubernetes.default.svc.cluster.local
```

### Tips & Troubleshooting

> [!TIP]
> **Recover from Backup:**
>
> ```bash
> kubectl delete -f /opt/course/16/coredns_backup.yaml
> kubectl apply -f /opt/course/16/coredns_backup.yaml
> kubectl -n kube-system rollout restart deploy coredns
> ```

> [!TIP]
> **Check CoreDNS Logs:**
>
> ```bash
> kubectl -n kube-system logs -l k8s-app=kube-dns
> ```

### References

- [Customizing DNS Service](https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/)
- [CoreDNS](https://coredns.io/manual/toc/)

---

## Question 17: Find Container of Pod and Check Info

### Context

**What is being tested:** Using `crictl` to interact with container runtime (containerd) at the node level.

**Why this matters:** Sometimes you need to troubleshoot at the container runtime level, below Kubernetes. Understanding crictl helps debug container-specific issues.

**Task Summary:**

1. Create a Pod and find which node it's on
2. Use crictl to find the container and its runtime type
3. Get container logs

> [!IMPORTANT]
> **Solve this question on:** `ssh cka2556`

### Solution

#### Step 1: Create Pod and Find Node

```bash
ssh cka2556

kubectl -n project-tiger run tigers-reunite \
  --image=httpd:2-alpine \
  --labels="pod=container,container=pod"

# Find the node
kubectl -n project-tiger get pod tigers-reunite -o wide
```

#### Step 2: SSH to Node and Find Container

```bash
ssh cka2556-node1
sudo -i

# Find container
crictl ps | grep tigers-reunite
# Note the CONTAINER ID
```

#### Step 3: Get Container Info

```bash
# Get runtime type
crictl inspect <container-id> | grep runtimeType

# Write to file (on main node)
echo "<container-id> io.containerd.runc.v2" > /opt/course/17/pod-container.txt
```

#### Step 4: Get Container Logs

```bash
crictl logs <container-id> > /opt/course/17/pod-container.log
```

### Tips & Troubleshooting

> [!TIP]
> **Common crictl Commands:**
>
> ```bash
> crictl ps                    # List running containers
> crictl pods                  # List pods
> crictl inspect <id>          # Container details
> crictl logs <id>             # Container logs
> crictl exec -it <id> sh      # Exec into container
> ```

### References

- [Debugging Kubernetes nodes with crictl](https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/)
- [Container Runtime Interface (CRI)](https://kubernetes.io/docs/concepts/architecture/cri/)

---

## Preview Question 1: ETCD Information

### Context

**What is being tested:** Understanding etcd configuration in a kubeadm-managed cluster.

**Task Summary:** Find etcd server key location, certificate expiration, and client auth status

> [!IMPORTANT]
> **Solve this question on:** `ssh cka9412`

### Solution

```bash
ssh cka9412
sudo -i

# Check etcd manifest
cat /etc/kubernetes/manifests/etcd.yaml | grep -E "key-file|cert-file|client-cert-auth"

# Check certificate expiration
openssl x509 -noout -text -in /etc/kubernetes/pki/etcd/server.crt | grep Validity -A2

# Write answers
cat > /opt/course/p1/etcd-info.txt << EOF
Server private key location: /etc/kubernetes/pki/etcd/server.key
Server certificate expiration date: Oct 29 14:19:27 2025 GMT
Is client certificate authentication enabled: yes
EOF
```

### References

- [Operating etcd clusters for Kubernetes](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)

---

## Preview Question 2: Kube-Proxy iptables

### Context

**What is being tested:** Understanding how kube-proxy uses iptables to implement Services.

### Solution

```bash
ssh cka3962

# Create Pod and Service
kubectl -n project-hamster run p2-pod --image=nginx:1-alpine
kubectl -n project-hamster expose pod p2-pod --name p2-service --port 3000 --target-port 80

# Check iptables rules
sudo iptables-save | grep p2-service > /opt/course/p2/iptables.txt

# Delete service and verify rules are gone
kubectl -n project-hamster delete svc p2-service
sudo iptables-save | grep p2-service  # Should return nothing
```

### References

- [Virtual IPs and Service Proxies](https://kubernetes.io/docs/reference/networking/virtual-ips/)

---

## Preview Question 3: Change Service CIDR

### Context

**What is being tested:** Modifying the cluster's Service CIDR range.

### Solution

1. Create Pod and initial Service
2. Edit `/etc/kubernetes/manifests/kube-apiserver.yaml` - change `--service-cluster-ip-range`
3. Edit `/etc/kubernetes/manifests/kube-controller-manager.yaml` - change `--service-cluster-ip-range`
4. Create new ServiceCIDR resource
5. Create new Service and verify it gets IP from new range

### References

- [Changing the Service IP Range](https://kubernetes.io/docs/tasks/network/extend-service-ip-ranges/)

---

## Exam Tips

### Time Management

- 15-20 questions in 2 hours
- Flag difficult questions and return later
- Some questions are worth more than others

### Essential Commands

```bash
# Quick Pod deletion
kubectl delete pod x --grace-period=0 --force

# Generate YAML templates
kubectl run pod --image=nginx --dry-run=client -o yaml
kubectl create deploy name --image=nginx --dry-run=client -o yaml

# Quick debugging
kubectl describe pod <name>
kubectl logs <pod>
kubectl get events --sort-by='.lastTimestamp'
```

### Allowed Documentation

- https://kubernetes.io/docs
- https://kubernetes.io/blog
- https://helm.sh/docs
- https://gateway-api.sigs.k8s.io

---

_Good luck with your CKA exam!_ 🎓
