# CKA Mock Exam 5 — Refined Solutions

> **Source:** Udemy CKA Mock Test 5  
> **Total Questions:** 16  
> **Sections:** Troubleshooting · Workloads & Scheduling · Cluster Architecture, Installation & Configuration · Storage · Services & Networking

---

## Table of Contents

| #           | Section                                     | Topic                                                |
| ----------- | ------------------------------------------- | ---------------------------------------------------- |
| [Q1](#q1)   | Troubleshooting                             | Fix Crashing Pod — Image Tag, Log Path & Service     |
| [Q2](#q2)   | Workloads & Scheduling                      | Priority Classes — Find Highest Value                |
| [Q3](#q3)   | Cluster Architecture, Installation & Config | Sysctl Network Parameters for kubeadm                |
| [Q4](#q4)   | Storage                                     | Sidecar Pod with Shared Volume                       |
| [Q5](#q5)   | Workloads & Scheduling                      | Vertical Pod Autoscaler (VPA) in Auto Mode           |
| [Q6](#q6)   | Workloads & Scheduling                      | ConfigMap for Deployment Environment Variable        |
| [Q7](#q7)   | Cluster Architecture, Installation & Config | Helm — Update Repo & Upgrade Chart                   |
| [Q8](#q8)   | Troubleshooting                             | DaemonSet Not Scheduling on Control Plane            |
| [Q9](#q9)   | Services & Networking                       | Create Ingress Resource                              |
| [Q10](#q10) | Storage                                     | PV with Node Affinity & PVC with Label Selector      |
| [Q11](#q11) | Cluster Architecture, Installation & Config | Kustomize — Fix RBAC Permissions                     |
| [Q12](#q12) | Troubleshooting                             | Multi-Issue Deployment — PVC, Init Container & Probe |
| [Q13](#q13) | Services & Networking                       | Gateway API — HTTPRoute with Header Matching         |
| [Q14](#q14) | Workloads & Scheduling                      | HPA with Scale-Down Behavior Policies                |
| [Q15](#q15) | Storage                                     | Create StorageClass                                  |
| [Q16](#q16) | Services & Networking                       | Install Calico CNI with VXLAN                        |

---

<a id="q1"></a>

## Q1 — Fix Crashing Pod (Image Tag, Log Path & Service Selector)

**Section:** Troubleshooting  
**Cluster:** `ssh cluster1-controlplane`

### Question

A pod called `nginx-cka01-trb` is running in the `default` namespace with two containers:

- `nginx-container` — uses `nginx:latest`
- `logs-container` — a co-located sidecar

The pod is continuously crashing. Identify and fix the issue. Ensure the pod is **Running** and accessible via `curl http://cluster1-controlplane:30001`.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Check container logs for the first issue

```bash
kubectl logs nginx-cka01-trb -c nginx-container
```

You'll see an image pull error — the image tag is misspelled.

#### Step 3 — Fix the image tag

```bash
kubectl get pod nginx-cka01-trb -o yaml > /tmp/nginx-fix.yaml
vi /tmp/nginx-fix.yaml
```

```diff
- image: nginx:latst
+ image: nginx:latest
```

Delete and recreate:

```bash
kubectl delete pod nginx-cka01-trb
kubectl apply -f /tmp/nginx-fix.yaml
```

#### Step 4 — Fix the log path in the sidecar container

The pod is still crashing. Check the sidecar logs:

```bash
kubectl logs nginx-cka01-trb -c logs-container
```

```
cat: can't open '/var/log/httpd/access.log': No such file or directory
cat: can't open '/var/log/httpd/error.log': No such file or directory
```

The sidecar's `command` references `/var/log/httpd/` but the volume is mounted at `/var/log/nginx`. Fix the path:

```bash
vi /tmp/nginx-fix.yaml
```

```diff
  command:
    - /bin/sh
    - -c
-   - cat /var/log/httpd/access.log /var/log/httpd/error.log
+   - cat /var/log/nginx/access.log /var/log/nginx/error.log
```

```bash
kubectl delete pod nginx-cka01-trb
kubectl apply -f /tmp/nginx-fix.yaml
```

#### Step 5 — Fix the service selector

The pod is running, but `curl` fails:

```bash
curl http://cluster1-controlplane:30001
# curl: (7) Failed to connect to cluster1-controlplane port 30001: Connection refused
```

Check the service:

```bash
kubectl get svc nginx-service-cka01-trb -o yaml
```

The selector label is wrong:

```bash
kubectl edit svc nginx-service-cka01-trb
```

```diff
  selector:
-   app: httpd-app-cka01-trb
+   app: nginx-app-cka01-trb
```

### Validation

```bash
# Pod should be Running with all containers ready
kubectl get pod nginx-cka01-trb

# Service should now route to the pod
curl http://cluster1-controlplane:30001
# Should return the nginx welcome page

# Verify service endpoints are populated
kubectl get endpoints nginx-service-cka01-trb
```

### 📖 Official Documentation

- [Debug Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/)
- [Debug Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)
- [Volumes — Shared Data Between Containers](https://kubernetes.io/docs/tasks/access-application-cluster/communicate-containers-same-pod-shared-volume/)

---

<a id="q2"></a>

## Q2 — Priority Classes — Find Highest User-Defined Value

**Section:** Workloads & Scheduling  
**Cluster:** `ssh cluster2-controlplane`

### Question

Inspect the user-defined priority classes on the cluster and output the **highest user-defined priority class value** to `/root/highest-user-prio.txt` on `cluster2-controlplane`.

> **Note:** Only the numeric value should be recorded.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster2-controlplane
```

#### Step 2 — List all priority classes

```bash
kubectl get priorityclasses
```

> **Important:** Ignore system priority classes (`system-cluster-critical`, `system-node-critical`) as they are not user-defined.

#### Step 3 — Find the highest user-defined priority value

```bash
kubectl get priorityclasses -o jsonpath='{range .items[?(@.metadata.name!="system-cluster-critical")]}{range @}{?(@.metadata.name!="system-node-critical")}{.metadata.name}{" "}{.value}{"\n"}{end}'
```

Or more practically, list all and manually identify:

```bash
kubectl get priorityclasses --no-headers | grep -v system | sort -k2 -n -r | head -1
```

#### Step 4 — Save the value

```bash
# Replace <VALUE> with the highest user-defined priority value from the output
echo "<VALUE>" > /root/highest-user-prio.txt
```

### Validation

```bash
cat /root/highest-user-prio.txt
# Should contain only the numeric value
```

### 📖 Official Documentation

- [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)
- [PriorityClass](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#priorityclass)

---

<a id="q3"></a>

## Q3 — Sysctl Network Parameters for kubeadm Setup

**Section:** Cluster Architecture, Installation & Configuration  
**Cluster:** `ssh cluster5-controlplane`

### Question

Adjust the following network parameters and ensure they **persist across reboots**:

```
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
net.ipv4.conf.all.forwarding        = 1
```

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster5-controlplane
```

#### Step 2 — Create a persistent sysctl configuration file

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
net.ipv4.conf.all.forwarding        = 1
EOF
```

> **Why `/etc/sysctl.d/`?** Files placed in `/etc/sysctl.d/` are loaded automatically on boot, making the settings persistent. The `k8s.conf` filename makes it clear these are Kubernetes-specific settings.

#### Step 3 — Apply the changes immediately

```bash
sudo sysctl --system
```

### Validation

```bash
# Verify all parameters are set
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
sysctl net.ipv4.ip_forward
sysctl net.ipv4.conf.all.forwarding
# All should return = 1

# Verify the file exists for persistence
cat /etc/sysctl.d/k8s.conf
```

### 📖 Official Documentation

- [Forwarding IPv4 and Letting iptables See Bridged Traffic](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#forwarding-ipv4-and-letting-iptables-see-bridged-traffic)
- [Installing kubeadm — Before You Begin](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin)

---

<a id="q4"></a>

## Q4 — Sidecar Pod with Shared Volume

**Section:** Storage  
**Cluster:** `ssh cluster2-controlplane`

### Question

In the `cka-multi-containers` namespace, create a pod named `cka-sidecar-pod`:

- **main-container** — image `nginx:1.27`, writes `"$(date) Hi I am from Sidecar container"` to `/log/app.log`
- **sidecar-container** — image `nginx:1.25`, serves `/usr/share/nginx/html` (where `app.log` is available at `/app.log` via nginx)

> **Note:** Do not rename `app.log` to `index.html`.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster2-controlplane
```

#### Step 2 — Create the pod manifest

```bash
cat <<'EOF' > /tmp/cka-sidecar-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: cka-sidecar-pod
  namespace: cka-multi-containers
spec:
  containers:
    - name: main-container
      image: nginx:1.27
      command: ["/bin/sh"]
      args:
        - -c
        - |
          while true; do
            echo "$(date) Hi I am from Sidecar container" >> /log/app.log;
            sleep 5;
          done
      volumeMounts:
        - name: shared-logs
          mountPath: /log

    - name: sidecar-container
      image: nginx:1.25
      volumeMounts:
        - name: shared-logs
          mountPath: /usr/share/nginx/html

  volumes:
    - name: shared-logs
      emptyDir: {}
EOF
```

#### Step 3 — Apply the manifest

```bash
kubectl apply -f /tmp/cka-sidecar-pod.yaml
```

### Validation

```bash
# Verify pod is Running with 2/2 containers
kubectl get pod cka-sidecar-pod -n cka-multi-containers

# Verify the sidecar serves the log file
kubectl exec -it cka-sidecar-pod -n cka-multi-containers -c sidecar-container -- curl http://localhost/app.log
# Expected: lines with timestamps and "Hi I am from Sidecar container"
```

### 📖 Official Documentation

- [Communicate Between Containers Using a Shared Volume](https://kubernetes.io/docs/tasks/access-application-cluster/communicate-containers-same-pod-shared-volume/)
- [Volumes — emptyDir](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)
- [Multi-Container Pods](https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers)

---

<a id="q5"></a>

## Q5 — Vertical Pod Autoscaler (VPA) in Auto Mode

**Section:** Workloads & Scheduling  
**Cluster:** `ssh cluster1-controlplane`

### Question

Create a VPA named `api-vpa` in **Auto** mode for `api-deployment` in the `services` namespace. Configure:

- CPU requests: **min 600m**, **max 1 core**
- Memory requests: **min 600Mi**, **max 1Gi**
- The `containerName` must explicitly match the container in `api-deployment`.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Identify the container name

```bash
kubectl get deploy api-deployment -n services -o jsonpath='{.spec.template.spec.containers[*].name}'
```

Note the container name from the output (e.g., `api-container`).

#### Step 3 — Create the VPA manifest

```bash
cat <<'EOF' > /tmp/api-vpa.yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: api-vpa
  namespace: services
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-deployment
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
      - containerName: "api-container"   # Replace with actual container name
        minAllowed:
          cpu: "600m"
          memory: "600Mi"
        maxAllowed:
          cpu: "1"
          memory: "1Gi"
EOF
```

> **Important:** Replace `api-container` with the actual container name from Step 2.

#### Step 4 — Apply the manifest

```bash
kubectl apply -f /tmp/api-vpa.yaml
```

### Validation

```bash
# Verify VPA is created
kubectl get vpa api-vpa -n services

# Check VPA details and recommendations
kubectl describe vpa api-vpa -n services

# Verify the resource policy boundaries
kubectl get vpa api-vpa -n services -o yaml | grep -A 10 containerPolicies
```

### 📖 Official Documentation

- [Vertical Pod Autoscaler](https://kubernetes.io/docs/concepts/workloads/autoscaling/#vertical-pod-autoscaler)
- [VPA API Reference](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)

---

<a id="q6"></a>

## Q6 — ConfigMap for Deployment Environment Variable

**Section:** Workloads & Scheduling  
**Cluster:** `ssh cluster3-controlplane`

### Question

A deployment `webapp-color-wl10` uses an environment variable. Extract it into a ConfigMap and update the deployment:

1. Create ConfigMap `webapp-wl10-config-map` with `APP_COLOR=red`
2. Update the deployment to use the ConfigMap
3. Delete and recreate the deployment if necessary

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster3-controlplane
```

#### Step 2 — Create the ConfigMap

```bash
kubectl create configmap webapp-wl10-config-map --from-literal=APP_COLOR=red
```

#### Step 3 — Check the current deployment

```bash
kubectl get deploy webapp-color-wl10 -o yaml > /tmp/webapp-color.yaml
```

#### Step 4 — Update the deployment to use the ConfigMap

```bash
kubectl edit deploy webapp-color-wl10
```

Replace the hardcoded `env` entry with a ConfigMap reference:

```diff
  env:
    - name: APP_COLOR
-     value: red
+     valueFrom:
+       configMapKeyRef:
+         name: webapp-wl10-config-map
+         key: APP_COLOR
```

Or alternatively, inject all keys from the ConfigMap:

```yaml
envFrom:
  - configMapRef:
      name: webapp-wl10-config-map
```

#### Step 5 — Verify rollout

```bash
kubectl rollout status deploy webapp-color-wl10
```

### Validation

```bash
# Verify ConfigMap exists
kubectl get configmap webapp-wl10-config-map -o yaml
# Should show APP_COLOR: red

# Verify the deployment uses the ConfigMap
kubectl get deploy webapp-color-wl10 -o yaml | grep -A 5 configMap

# Verify the pod has the environment variable
kubectl exec $(kubectl get pod -l app=webapp-color-wl10 -o name | head -1) -- env | grep APP_COLOR
# Expected: APP_COLOR=red
```

### 📖 Official Documentation

- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)

---

<a id="q7"></a>

## Q7 — Helm — Update Repo & Upgrade Chart Version

**Section:** Cluster Architecture, Installation & Configuration  
**Cluster:** `ssh cluster1-controlplane`

### Question

A KubeSphere NGINX helm chart `lvm-crystal-apd` is deployed. Update the helm repository, then upgrade the chart to version **1.3.4** and set replicas to **3**.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — List current releases and repos

```bash
helm ls -A
helm repo ls
```

Identify the namespace (e.g., `crystal-apd-ns`) and the repo name (e.g., `kubesphere`).

#### Step 3 — Update the helm repository

```bash
helm repo update kubesphere
```

#### Step 4 — Verify chart version availability

```bash
helm search repo kubesphere/nginx -l | head -n 10
```

Confirm version `1.3.4` is available.

#### Step 5 — Upgrade the release

```bash
helm upgrade lvm-crystal-apd kubesphere/nginx \
  -n crystal-apd-ns \
  --version=1.3.4 \
  --set replicaCount=3
```

### Validation

```bash
# Verify the chart version
helm ls -n crystal-apd-ns
# CHART column should show nginx-1.3.4

# Verify replica count
kubectl get deploy -n crystal-apd-ns
# AVAILABLE should be 3
```

### 📖 Official Documentation

- [Helm Upgrade](https://helm.sh/docs/helm/helm_upgrade/)
- [Helm Repo Update](https://helm.sh/docs/helm/helm_repo_update/)
- [Managing Kubernetes Objects with Helm](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/managing-kubernetes-objects-using-helm/)

---

<a id="q8"></a>

## Q8 — DaemonSet Not Scheduling on Control Plane Node

**Section:** Troubleshooting  
**Cluster:** `ssh cluster2-controlplane`

### Question

A DaemonSet `logs-cka26-trb` in `kube-system` should run on **all nodes** including the control plane, but it's not creating a pod on the control plane node. Fix it.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster2-controlplane
```

#### Step 2 — Check the DaemonSet status

```bash
kubectl get ds logs-cka26-trb -n kube-system
kubectl get pods -n kube-system -l name=logs-cka26-trb -o wide
```

DESIRED count is less than total node count. The pod is missing from the control plane node.

#### Step 3 — Check for taints on the control plane

```bash
kubectl describe node cluster2-controlplane | grep -i taint
```

The control plane has a `NoSchedule` taint:

```
Taints: node-role.kubernetes.io/control-plane:NoSchedule
```

#### Step 4 — Add the required toleration

```bash
kubectl edit ds logs-cka26-trb -n kube-system
```

Add the toleration under `spec.template.spec.tolerations`:

```yaml
tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
```

### Validation

```bash
# Wait a few seconds, then check
kubectl get ds logs-cka26-trb -n kube-system
# DESIRED, CURRENT, READY should all equal total node count (e.g., 2)

kubectl get pods -n kube-system -l name=logs-cka26-trb -o wide
# Should show pods on ALL nodes including the controlplane
```

### 📖 Official Documentation

- [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)

---

<a id="q9"></a>

## Q9 — Create Ingress Resource

**Section:** Services & Networking  
**Cluster:** `ssh cluster3-controlplane`

### Question

Create an ingress resource `nginx-ingress-cka04-svcn` for the deployment `nginx-deployment-cka04-svcn` exposed via `nginx-service-cka04-svcn`:

- `pathType: Prefix`, `path: /`
- Backend: `nginx-service-cka04-svcn` on port `80`
- `ssl-redirect` set to `false`

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster3-controlplane
```

#### Step 2 — Create the ingress manifest

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress-cka04-svcn
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-service-cka04-svcn
                port:
                  number: 80
EOF
```

### Validation

```bash
# Verify ingress is created
kubectl get ingress nginx-ingress-cka04-svcn
# Should show an ADDRESS assigned

# Test the ingress (use traefik/ingress controller IP)
curl -I http://<INGRESS_ADDRESS>
# Should return HTTP/1.1 200 OK
```

### 📖 Official Documentation

- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)

---

<a id="q10"></a>

## Q10 — PV with Node Affinity & PVC with Label Selector

**Section:** Storage  
**Cluster:** `ssh cluster1-controlplane`

### Question

Using storage class `coconut-stc-cka01-str`:

**PV** (`coconut-pv-cka01-str`):

- Capacity: `100Mi`, type: `hostPath` at `/opt/coconut-stc-cka01-str`
- Must be created on `cluster1-node01` (directory already exists)
- Label: `storage-tier: gold`

**PVC** (`coconut-pvc-cka01-str`):

- Request `50Mi` from the PV using `matchLabels`
- Access mode: `ReadWriteMany`

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Create the PV and PVC manifest

```bash
cat <<'EOF' > /tmp/coconut-storage.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: coconut-pv-cka01-str
  labels:
    storage-tier: gold
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: /opt/coconut-stc-cka01-str
  storageClassName: coconut-stc-cka01-str
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - cluster1-node01
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: coconut-pvc-cka01-str
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Mi
  storageClassName: coconut-stc-cka01-str
  selector:
    matchLabels:
      storage-tier: gold
EOF
```

> **Key Concepts:**
>
> - **Node Affinity on PV:** Ensures the PV is only used on `cluster1-node01` where the hostPath directory exists.
> - **Label Selector on PVC:** The `matchLabels` in the PVC's `selector` binds it specifically to the PV with `storage-tier: gold`.
> - **Storage Class:** Both PV and PVC reference the same `storageClassName` for matching.

#### Step 3 — Apply

```bash
kubectl apply -f /tmp/coconut-storage.yaml
```

### Validation

```bash
# PV should be Bound
kubectl get pv coconut-pv-cka01-str

# PVC should be Bound to the PV
kubectl get pvc coconut-pvc-cka01-str
# VOLUME column should show coconut-pv-cka01-str

# Verify label on PV
kubectl get pv coconut-pv-cka01-str --show-labels
```

### 📖 Official Documentation

- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [PersistentVolumeClaims — Selector](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector)
- [Node Affinity on PV](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#node-affinity)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)

---

<a id="q11"></a>

## Q11 — Kustomize — Fix RBAC Permissions

**Section:** Cluster Architecture, Installation & Configuration  
**Cluster:** `ssh cluster2-controlplane`

### Question

A Kustomize configuration at `/root/web-dashboard-kustomize` deploys a web dashboard to monitor pods in the `default` namespace. The application is failing due to **insufficient permissions**. Fix the Kustomize `overlays/dev` configuration.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster2-controlplane
```

#### Step 2 — Review current deployment and logs

```bash
# Preview what Kustomize deploys
kubectl kustomize /root/web-dashboard-kustomize/overlays/dev

# Check application logs
kubectl logs deploy/web-dashboard
```

Error shows `403 Forbidden` — the service account `dashboard-sa` cannot `list` or `watch` pods.

#### Step 3 — Fix the Role in the Kustomize overlay

```bash
vi /root/web-dashboard-kustomize/overlays/dev/patch-role.yaml
```

Update the role to include missing verbs:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

> **Root Cause:** The original role was missing `list` and/or `watch` verbs, which the dashboard needs to monitor pods.

#### Step 4 — Apply the updated configuration

```bash
kubectl kustomize /root/web-dashboard-kustomize/overlays/dev | kubectl apply -f -
```

#### Step 5 — Restart the deployment

```bash
kubectl rollout restart deployment web-dashboard
```

### Validation

```bash
# Verify pods are running
kubectl get pods -l app=web-dashboard

# Check logs — should no longer show 403 errors
kubectl logs deploy/web-dashboard

# Verify the role has correct verbs
kubectl get role pod-reader -o yaml | grep -A 5 verbs
```

### 📖 Official Documentation

- [Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Role and ClusterRole](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole)

---

<a id="q12"></a>

## Q12 — Multi-Issue Deployment (PVC Size, Init Container & Liveness Probe)

**Section:** Troubleshooting  
**Cluster:** `ssh cluster1-controlplane`

### Question

The deployment `web-dp-cka17-trb` has 0/1 pods running. The app runs on port **80** and is exposed on NodePort **30090**. Troubleshoot and fix all issues.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Identify Issue 1: PVC capacity mismatch

```bash
kubectl get pod
kubectl get events --field-selector involvedObject.name=<pod-name>
```

Error: `persistentvolumeclaim "web-pvc-cka17-trbl" not found` or PVC is `Pending`.

```bash
kubectl get pv,pvc
kubectl get pvc web-pvc-cka17-trb -o yaml
```

The PVC requests `150Mi` but the PV only has `100Mi`.

```bash
kubectl edit pv web-pv-cka17-trb
```

```diff
  capacity:
-   storage: 100Mi
+   storage: 150Mi
```

#### Step 3 — Identify Issue 2: Init container command typo

After PVC binds, the pod moves to `Init:CrashLoopBackOff`:

```bash
kubectl get events --field-selector involvedObject.name=<pod-name>
```

Error: `exec: "/bin/bsh\": no such file or directory`

```bash
kubectl edit deploy web-dp-cka17-trb
```

```diff
  initContainers:
    - command:
-       - /bin/bsh\
+       - /bin/bash
```

#### Step 4 — Identify Issue 3: Liveness probe wrong port

Pod starts but keeps restarting. Events show:

```
Liveness probe failed: dial tcp ...:81: connect: connection refused
```

```bash
kubectl edit deploy web-dp-cka17-trb
```

```diff
  livenessProbe:
    httpGet:
-     port: 81
+     port: 80
```

### Validation

```bash
# Pod should be Running and stable
kubectl get pod -w
# Wait ~60 seconds — RESTARTS should stay at 0

# Test the application
curl http://cluster1-controlplane:30090
# Should return a response
```

### 📖 Official Documentation

- [Troubleshooting Applications](https://kubernetes.io/docs/tasks/debug/debug-application/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [Configure Liveness Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

---

<a id="q13"></a>

## Q13 — Gateway API — HTTPRoute with Header-Based Routing

**Section:** Services & Networking  
**Cluster:** `ssh cluster3-controlplane`

### Question

Create an HTTPRoute named `web-app-route` in the `ck2145` namespace:

- Requests with header `X-Environment: canary` → route to `web-service-canary` on port `8080`
- All other traffic → route to `web-service` on port `8080`

A Gateway already exists in the `nginx-gateway` namespace.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster3-controlplane
```

#### Step 2 — Create the HTTPRoute manifest

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-app-route
  namespace: ck2145
spec:
  parentRefs:
    - name: nginx-gateway
      namespace: nginx-gateway
  rules:
    - matches:
        - headers:
            - name: X-Environment
              value: canary
      backendRefs:
        - name: web-service-canary
          port: 8080
    - backendRefs:
        - name: web-service
          port: 8080
EOF
```

> **Key Concepts:**
>
> - **Gateway API** is the successor to Ingress, offering more expressive routing.
> - The `parentRefs` ties this route to the existing Gateway.
> - Rules are evaluated in order — the first matching rule wins.
> - The second rule (no `matches`) acts as the **default** catch-all.

### Validation

```bash
# Verify the HTTPRoute
kubectl get httproute web-app-route -n ck2145

# Test canary header routing
curl -H 'X-Environment: canary' http://localhost:30080
# Should hit web-service-canary

# Test default routing
curl http://localhost:30080
# Should hit web-service
```

### 📖 Official Documentation

- [Gateway API — HTTPRoute](https://gateway-api.sigs.k8s.io/guides/http-routing/)
- [Gateway API — Header-Based Routing](https://gateway-api.sigs.k8s.io/guides/http-routing/#http-header-matching)
- [Gateway API — Kubernetes Docs](https://kubernetes.io/docs/concepts/services-networking/gateway/)

---

<a id="q14"></a>

## Q14 — HPA with Scale-Down Behavior Policies

**Section:** Workloads & Scheduling  
**Cluster:** `ssh cluster3-controlplane`

### Question

Create an HPA named `backend-hpa` in `cka0841` namespace for `backend-deployment`:

- Min replicas: **3**, Max replicas: **15**
- Scale on **CPU utilization** at **50%**
- Scale-down: max **5 pods** or **20%** of replicas (whichever is fewer) within **60 seconds**

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster3-controlplane
```

#### Step 2 — Create the HPA manifest

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: cka0841
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend-deployment
  minReplicas: 3
  maxReplicas: 15
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
  behavior:
    scaleDown:
      policies:
        - type: Pods
          value: 5
          periodSeconds: 60
        - type: Percent
          value: 20
          periodSeconds: 60
      selectPolicy: Min
EOF
```

> **Key Concepts:**
>
> - `selectPolicy: Min` means Kubernetes picks the policy that removes the **fewest** pods.
> - Two policies: absolute (max 5 pods) and percentage (20%). The smaller result is used.
> - `periodSeconds: 60` = evaluation window for each policy.

### Validation

```bash
# Verify HPA is created
kubectl get hpa backend-hpa -n cka0841

# Check HPA details including behavior policies
kubectl describe hpa backend-hpa -n cka0841

# Verify the scale-down behavior in YAML
kubectl get hpa backend-hpa -n cka0841 -o yaml | grep -A 15 behavior
```

### 📖 Official Documentation

- [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [HPA Scaling Policies](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#scaling-policies)
- [HPA API — autoscaling/v2](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v2/)

---

<a id="q15"></a>

## Q15 — Create StorageClass

**Section:** Storage  
**Cluster:** `ssh cluster1-controlplane`

### Question

Create a StorageClass `banana-sc-cka08-str`:

- Provisioner: `kubernetes.io/no-provisioner`
- Volume binding mode: `WaitForFirstConsumer`
- Volume expansion: **enabled**

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Create the StorageClass manifest

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: banana-sc-cka08-str
provisioner: kubernetes.io/no-provisioner
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF
```

> **Key Concepts:**
>
> - `kubernetes.io/no-provisioner` — used for manually provisioned (static) PVs.
> - `WaitForFirstConsumer` — delays volume binding until a pod using the PVC is scheduled, ensuring node-local volumes are bound to the correct node.
> - `allowVolumeExpansion: true` — enables PVC resize requests.

### Validation

```bash
# Verify the StorageClass
kubectl get sc banana-sc-cka08-str

# Check all fields
kubectl get sc banana-sc-cka08-str -o yaml
# provisioner: kubernetes.io/no-provisioner
# volumeBindingMode: WaitForFirstConsumer
# allowVolumeExpansion: true
```

### 📖 Official Documentation

- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Volume Binding Mode](https://kubernetes.io/docs/concepts/storage/storage-classes/#volume-binding-mode)
- [Allow Volume Expansion](https://kubernetes.io/docs/concepts/storage/storage-classes/#allow-volume-expansion)

---

<a id="q16"></a>

## Q16 — Install Calico CNI with VXLAN Encapsulation

**Section:** Services & Networking  
**Cluster:** `ssh cluster4-controlplane`

### Question

Deploy Calico CNI using the official installation guide. Configure:

- CIDR: `172.17.0.0/16`
- Encapsulation: `VXLAN`

Verify pod-to-pod communication after installation.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster4-controlplane
```

#### Step 2 — Install the Tigera operator

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/tigera-operator.yaml
```

#### Step 3 — Download and customize the resources

```bash
curl https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/custom-resources.yaml -O
```

Edit `custom-resources.yaml` to set CIDR and VXLAN:

```bash
vi custom-resources.yaml
```

Ensure the file looks like:

```yaml
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
      - name: default-ipv4-ippool
        blockSize: 26
        cidr: 172.17.0.0/16
        encapsulation: VXLAN
        natOutgoing: Enabled
        nodeSelector: all()
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
```

#### Step 4 — Apply the custom resources

```bash
kubectl create -f custom-resources.yaml
```

#### Step 5 — Wait for Calico pods to be ready

```bash
watch kubectl get pods -n calico-system
# Wait until all pods show Running/Ready
```

#### Step 6 — Test pod-to-pod communication

```bash
# Create a test pod
kubectl run web-app --image=nginx

# Get the pod IP
kubectl get pod web-app -o jsonpath='{.status.podIP}'

# Test connectivity from another pod
kubectl run test --rm -it -n kube-public --image=busybox --restart=Never -- wget -qO- http://<POD_IP>
# Should return the nginx welcome page
```

### Validation

```bash
# All Calico pods should be Running
kubectl get pods -n calico-system

# All nodes should be Ready
kubectl get nodes

# Verify the CIDR
kubectl get installation default -o jsonpath='{.spec.calicoNetwork.ipPools[0].cidr}'
# Expected: 172.17.0.0/16

# Verify encapsulation
kubectl get installation default -o jsonpath='{.spec.calicoNetwork.ipPools[0].encapsulation}'
# Expected: VXLAN
```

### 📖 Official Documentation

- [Calico — Quickstart](https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart)
- [Calico — Installation Reference](https://docs.tigera.io/calico/latest/reference/installation/api)
- [Kubernetes — Cluster Networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
- [Kubernetes — Install a Network Plugin](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network)

---

## Quick Reference — `kubectl` Commands

### Pod Operations

```bash
# Create a pod quickly
kubectl run <name> --image=<image> --restart=Never

# Create a pod with a command
kubectl run <name> --image=<image> --restart=Never -- <command>

# Get pod with wide output (shows node)
kubectl get pods -o wide

# Watch pods in real-time
kubectl get pods -w

# Describe a pod (events, probe status, etc.)
kubectl describe pod <name>

# Get pod logs
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>     # multi-container pod
kubectl logs <pod-name> --previous               # previous crashed container

# Execute command in a pod
kubectl exec <pod-name> -- <command>
kubectl exec -it <pod-name> -- /bin/sh           # interactive shell
kubectl exec <pod-name> -c <container> -- <cmd>  # specific container

# Delete a pod
kubectl delete pod <name>
kubectl delete pod <name> --force --grace-period=0  # force delete
```

### Deployments & Rollouts

```bash
# Create a deployment
kubectl create deploy <name> --image=<image> --replicas=3

# Scale a deployment
kubectl scale deploy <name> --replicas=5

# Rollout status
kubectl rollout status deploy <name>

# Rollout history
kubectl rollout history deploy <name>

# Undo a rollout
kubectl rollout undo deploy <name>

# Restart a deployment (rolling restart)
kubectl rollout restart deploy <name>
```

### Debugging & Events

```bash
# Get events for a specific object
kubectl get events --field-selector involvedObject.name=<name>

# Sort events by timestamp
kubectl get events --sort-by='.lastTimestamp'

# Get events in a namespace
kubectl get events -n <namespace>

# Describe for detailed status
kubectl describe pod|svc|deploy|node <name>
```

### Resource Management

```bash
# Get resource YAML
kubectl get <resource> <name> -o yaml

# Edit a resource live
kubectl edit <resource> <name>

# Apply a manifest
kubectl apply -f <file.yaml>

# Delete using manifest
kubectl delete -f <file.yaml>

# Dry-run (client-side) — useful for generating YAML
kubectl run nginx --image=nginx --restart=Never --dry-run=client -o yaml > pod.yaml
kubectl create deploy nginx --image=nginx --dry-run=client -o yaml > deploy.yaml
```

### Services & Networking

```bash
# Expose a deployment as a service
kubectl expose deploy <name> --port=80 --target-port=8080 --type=NodePort

# Get service endpoints
kubectl get endpoints <svc-name>

# Test connectivity from within the cluster
kubectl run test --rm -it --image=busybox --restart=Never -- wget -qO- http://<svc-name>:<port>
```

### ConfigMaps & Secrets

```bash
# Create ConfigMap from literal
kubectl create configmap <name> --from-literal=key=value

# Create ConfigMap from file
kubectl create configmap <name> --from-file=<path>

# View ConfigMap
kubectl get cm <name> -o yaml
```

### Storage

```bash
# List PVs and PVCs
kubectl get pv,pvc

# List StorageClasses
kubectl get sc

# Check PV/PVC binding
kubectl describe pvc <name>
```

### Troubleshooting Control Plane

```bash
# Check control plane pods
kubectl get pods -n kube-system

# When kubectl is unavailable, use crictl
crictl ps -a
crictl ps -a | grep kube-apiserver
crictl logs <container_id>

# Static pod manifests
ls /etc/kubernetes/manifests/
```

### Helm Commands

```bash
# List releases
helm ls -A

# List repos
helm repo ls

# Update repos
helm repo update [repo-name]

# Search Artifact Hub
helm search hub <chart> --list-repo-url

# Search local repos (with all versions)
helm search repo <name> -l

# Install a chart
helm install <release> <chart> -n <namespace>

# Upgrade a chart
helm upgrade <release> <chart> -n <namespace> --version=<ver> --set key=value

# Uninstall
helm uninstall <release> -n <namespace>
```

### Kustomize

```bash
# Preview rendered resources
kubectl kustomize <directory>

# Apply with Kustomize
kubectl kustomize <directory> | kubectl apply -f -

# Or use the -k flag
kubectl apply -k <directory>
```

### JSONPath Queries

```bash
# Get container names
kubectl get pod <name> -o jsonpath='{.spec.containers[*].name}'

# Get node names
kubectl get nodes -o jsonpath='{.items[*].metadata.name}'

# Get pod IPs
kubectl get pods -o jsonpath='{.items[*].status.podIP}'

# Get specific field with custom columns
kubectl get pods -o custom-columns='NAME:.metadata.name,IMAGE:.spec.containers[0].image'
```

---

## Quick Reference — `kubeadm` Commands

### Cluster Bootstrap

```bash
# Initialize a control plane
kubeadm init --pod-network-cidr=10.244.0.0/16

# Generate a join token
kubeadm token create --print-join-command

# List tokens
kubeadm token list

# Join a worker node
kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

### Cluster Upgrades

```bash
# Check available versions
apt list -a kubeadm      # Debian/Ubuntu

# Upgrade plan
kubeadm upgrade plan

# Apply upgrade on control plane
kubeadm upgrade apply v1.xx.x

# Upgrade kubelet and kubectl
apt-get update && apt-get install -y kubelet=1.xx.x-00 kubectl=1.xx.x-00
systemctl daemon-reload && systemctl restart kubelet

# Drain node before upgrade
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data

# Upgrade worker nodes
kubeadm upgrade node
```

### Certificate Management

```bash
# Check certificate expiration
kubeadm certs check-expiration

# Renew all certificates
kubeadm certs renew all

# View certificate details
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
```

### etcd Operations

```bash
# Snapshot etcd
ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify snapshot
ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db --write-table

# Restore from snapshot
ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db \
  --data-dir=/var/lib/etcd-restored
```

### Network Setup (Pre-kubeadm)

```bash
# Required sysctl parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply immediately
sudo sysctl --system
```

### PKI Paths (kubeadm default)

```
/etc/kubernetes/pki/
├── ca.crt / ca.key                   # Kubernetes cluster CA
├── apiserver.crt / apiserver.key     # API server TLS cert
├── apiserver-kubelet-client.crt      # API server → kubelet client cert
├── front-proxy-ca.crt                # Front proxy CA
├── sa.key / sa.pub                   # ServiceAccount signing keys
└── etcd/
    ├── ca.crt / ca.key               # etcd CA (separate from cluster CA)
    ├── server.crt / server.key       # etcd server TLS cert
    ├── peer.crt / peer.key           # etcd peer communication
    └── healthcheck-client.crt        # etcd health check client cert
```

---

> **💡 Exam Tips:**
>
> - Always **SSH into the correct cluster** before running commands
> - Use `crictl` when `kubectl` is unavailable (API server down)
> - Static pod manifests are in `/etc/kubernetes/manifests/` — editing them auto-restarts the pod
> - Use `kubectl get events` to quickly understand pod issues
> - Use `--dry-run=client -o yaml` to generate YAML templates fast
> - Use `kubectl explain <resource>` to look up field specifications during the exam
> - Gateway API is the modern replacement for Ingress — know both
> - For HPA, remember `autoscaling/v2` supports custom metrics and behavior policies
> - Bookmark the [Kubernetes Documentation](https://kubernetes.io/docs/) — it's allowed during the exam
