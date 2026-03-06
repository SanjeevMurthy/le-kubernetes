# CKA Mock Exam 4 — Refined Solutions

> **Source:** Udemy CKA Mock Test 4  
> **Total Questions:** 5 (Q4 not captured in draft)  
> **Sections:** Troubleshooting · Cluster Architecture, Installation & Configuration · Storage

---

## Table of Contents

| #         | Section                                     | Topic                                          |
| --------- | ------------------------------------------- | ---------------------------------------------- |
| [Q1](#q1) | Troubleshooting                             | Fix Liveness Probe — httpGet → exec            |
| [Q2](#q2) | Cluster Architecture, Installation & Config | Helm — Find Bitnami Nginx Repo URL             |
| [Q3](#q3) | Troubleshooting                             | API Server — etcd Connection & Certificate Fix |
| [Q4](#q4) | _(Not captured)_                            | —                                              |
| [Q5](#q5) | Storage                                     | Shared emptyDir Volume Between Two Containers  |

---

<a id="q1"></a>

## Q1 — Fix Liveness Probe (httpGet → exec)

**Section:** Troubleshooting  
**Cluster:** `ssh cluster1-controlplane`

### Question

A template to create a Kubernetes pod is stored at `/root/red-probe-cka12-trb.yaml` on `cluster1-controlplane`. Using this template as-is results in an error.

Fix the issue and ensure the pod is **stable** (not crashing or restarting).

> **Constraint:** Do not update the `args:` section of the template.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Attempt to apply the template

```bash
kubectl apply -f /root/red-probe-cka12-trb.yaml
```

You will see validation errors:

```
error: error validating "red-probe-cka12-trb.yaml":
  ValidationError(Pod.spec.containers[0].livenessProbe.httpGet): unknown field "command"
  ValidationError(Pod.spec.containers[0].livenessProbe.httpGet): missing required field "port"
```

**Root Cause:** The `livenessProbe` type is set to `httpGet`, but the probe options (`command`) are exec-based.

#### Step 3 — Fix the probe type

```bash
vi /root/red-probe-cka12-trb.yaml
```

Change `httpGet` to `exec`:

```diff
    livenessProbe:
-     httpGet:
+     exec:
        command:
          - cat
          - /healthcheck
```

#### Step 4 — Apply the corrected template

```bash
kubectl apply -f /root/red-probe-cka12-trb.yaml
```

The pod will be created, but after a few seconds it will start **restarting**.

#### Step 5 — Diagnose the restart

```bash
kubectl get event --field-selector involvedObject.name=red-probe-cka12-trb
```

You will see:

```
Warning  Unhealthy  pod/red-probe-cka12-trb  Liveness probe failed: cat: can't open '/healthcheck': No such file or directory
```

**Root Cause:** The container's `args` runs `sleep 3 ; touch /healthcheck; sleep 30; sleep 30000`. It takes **3 seconds** to create `/healthcheck`, but `initialDelaySeconds` is set to `1` and `failureThreshold` is `1`. The probe fires before the file exists.

#### Step 6 — Fix the initialDelaySeconds

```bash
vi /root/red-probe-cka12-trb.yaml
```

```diff
    livenessProbe:
      exec:
        command:
          - cat
          - /healthcheck
-     initialDelaySeconds: 1
+     initialDelaySeconds: 5
      failureThreshold: 1
      periodSeconds: 5
```

> **Why 5?** The `touch /healthcheck` command runs after a 3-second `sleep`. Setting `initialDelaySeconds: 5` gives a comfortable margin for the file to be created before the first probe.

#### Step 7 — Delete and recreate the pod

```bash
kubectl delete pod red-probe-cka12-trb
kubectl apply -f /root/red-probe-cka12-trb.yaml
```

### Validation

```bash
# Watch the pod for ~60 seconds — should remain Running with 0 restarts
kubectl get pod red-probe-cka12-trb -w

# After 60 seconds, confirm stability
sleep 60 && kubectl get pod red-probe-cka12-trb
# RESTARTS should be 0

# Double check events for any probe failures
kubectl get events --field-selector involvedObject.name=red-probe-cka12-trb --sort-by='.lastTimestamp'
# Should have no recent "Unhealthy" events

# Verify the probe configuration
kubectl get pod red-probe-cka12-trb -o jsonpath='{.spec.containers[0].livenessProbe}' | python3 -m json.tool
```

### 📖 Official Documentation

- [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Define a Liveness Command](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-command)
- [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)

---

<a id="q2"></a>

## Q2 — Helm — Find Bitnami Nginx Repository URL

**Section:** Cluster Architecture, Installation & Configuration  
**Cluster:** `ssh cluster3-controlplane`

### Question

Use Helm to search for the repository URL of the **Bitnami** version of the Nginx repository. Save the repository URL in `/root/nginx-helm-url.txt` on `cluster3-controlplane`.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster3-controlplane
```

#### Step 2 — Search for the Bitnami Nginx chart on Artifact Hub

```bash
helm search hub nginx --list-repo-url | grep bitnami
```

Output will include a line like:

```
https://artifacthub.io/packages/helm/bitnami/nginx  19.0.2  1.27.4  ...  https://charts.bitnami.com/bitnami
```

> **Key Points:**
>
> - `helm search hub` — searches [Artifact Hub](https://artifacthub.io/) (the public Helm chart registry)
> - `--list-repo-url` — adds a `REPO URL` column to the output
> - Look for the row where the chart name path contains `bitnami/nginx` (not `bitnami-aks` or other forks)

#### Step 3 — Save the repository URL

```bash
echo "https://charts.bitnami.com/bitnami" > /root/nginx-helm-url.txt
```

### Validation

```bash
# Verify the file contents
cat /root/nginx-helm-url.txt
# Expected: https://charts.bitnami.com/bitnami

# (Optional) Add the repo and verify it works
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo bitnami/nginx
# Should list the nginx chart
```

### 📖 Official Documentation

- [Helm Search Hub](https://helm.sh/docs/helm/helm_search_hub/)
- [Helm Repo Add](https://helm.sh/docs/helm/helm_repo_add/)
- [Artifact Hub](https://artifacthub.io/)
- [Kubernetes — Managing Kubernetes Objects with Helm](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/managing-kubernetes-objects-using-helm/)

---

<a id="q3"></a>

## Q3 — API Server — etcd Connection & Certificate Fix

**Section:** Troubleshooting  
**Cluster:** `ssh cluster4-controlplane`

### Question

Identify and fix the issue causing `kubectl` commands to fail on cluster4.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster4-controlplane
```

#### Step 2 — Inspect the kube-apiserver container

Since `kubectl` is failing, use `crictl` to check container status:

```bash
crictl ps -a | grep kube-apiserver
```

If the API server container is continuously restarting, get its logs:

```bash
crictl logs <container_id>
```

#### Step 3 — Identify Issue 1: etcd connection error

You will see repeated errors:

```
grpc: addrConn.createTransport failed to connect to {Addr: "127.0.0.1:2379"}
Err: connection error: desc = "error reading server preface: read tcp ... connection reset by peer"
```

This means the API server cannot connect to etcd.

#### Step 4 — Fix the etcd flag name and protocol

```bash
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Find the `--etcd-server` flag (note: **missing the "s"** and uses **HTTP** instead of HTTPS):

```diff
-    - --etcd-server=http://127.0.0.1:2379
+    - --etcd-servers=https://127.0.0.1:2379
```

> **Two issues fixed:**
>
> 1. Flag name: `--etcd-server` → `--etcd-servers` (plural)
> 2. Protocol: `http://` → `https://` (etcd uses TLS by default in kubeadm clusters)

Save and exit. The kubelet will auto-restart the API server static pod.

#### Step 5 — Wait and check for Issue 2

```bash
# Wait for the API server to restart
sleep 15
crictl logs $(crictl ps -a --name kube-apiserver -q | head -1)
```

If you see TLS errors:

```
transport: authentication handshake failed: tls: failed to verify certificate:
x509: certificate signed by unknown authority
```

#### Step 6 — Fix the etcd CA certificate path

```bash
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

The API server is using the Kubernetes CA to verify etcd, but etcd has its own CA:

```diff
-    - --etcd-cafile=/etc/kubernetes/pki/ca.crt
+    - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
```

Save and exit.

> **Why this matters:** kubeadm generates separate PKI hierarchies:
>
> - `/etc/kubernetes/pki/ca.crt` — Kubernetes cluster CA (for API server, kubelet, etc.)
> - `/etc/kubernetes/pki/etcd/ca.crt` — etcd-specific CA

#### Step 7 — Wait for stabilization

```bash
# Wait for the API server to fully restart
sleep 30

# Verify kubectl now works
kubectl get nodes
```

### Validation

```bash
# All nodes should be Ready
kubectl get nodes

# All system pods should be Running
kubectl get pods -n kube-system

# Verify kube-apiserver is running and not restarting
crictl ps | grep kube-apiserver
# STATUS should be "Running" with a stable uptime

# Run kubectl multiple times to confirm no intermittent failures
for i in {1..5}; do kubectl get nodes && echo "Attempt $i: OK"; sleep 3; done

# Verify the corrected flags in the manifest
grep -E "etcd-servers|etcd-cafile" /etc/kubernetes/manifests/kube-apiserver.yaml
# Expected:
#   --etcd-servers=https://127.0.0.1:2379
#   --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
```

### 📖 Official Documentation

- [kube-apiserver Reference](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/)
- [PKI Certificates and Requirements](https://kubernetes.io/docs/setup/best-practices/certificates/)
- [Troubleshooting kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/)
- [Static Pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
- [etcd Configuration](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)

---

<a id="q4"></a>

## Q4 — _(Not Captured)_

> This question was not recorded in the draft. Placeholder for future reference.

---

<a id="q5"></a>

## Q5 — Shared emptyDir Volume Between Two Containers

**Section:** Storage  
**Cluster:** `ssh cluster1-controlplane`

### Question

Create a pod with a shared volume between two containers:

- Pod name: `grape-pod-cka06-str`
- Main container: `nginx` (image: `nginx`), mount `grape-vol-cka06-str` at `/var/log/nginx`
- Sidecar container: `busybox-sidecar` (image: `busybox`), command: `sleep 7200`, mount same volume at `/usr/src`
- Volume type: `emptyDir`

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Create the pod manifest

```bash
cat <<'EOF' > /tmp/grape-pod-cka06-str.yaml
apiVersion: v1
kind: Pod
metadata:
  name: grape-pod-cka06-str
spec:
  containers:
    - name: nginx
      image: nginx
      volumeMounts:
        - name: grape-vol-cka06-str
          mountPath: /var/log/nginx

  initContainers:
    - name: busybox-sidecar
      image: busybox
      restartPolicy: Always
      command: ["sleep", "7200"]
      volumeMounts:
        - name: grape-vol-cka06-str
          mountPath: /usr/src

  volumes:
    - name: grape-vol-cka06-str
      emptyDir: {}
EOF
```

> **Key Concepts:**
>
> - **Sidecar as `initContainers` with `restartPolicy: Always`:** Since Kubernetes 1.28+, [native sidecar containers](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/) are defined as init containers with `restartPolicy: Always`. They start before the main containers and run for the lifetime of the pod.
> - **`emptyDir`:** A temporary directory created when the pod is assigned to a node. It's shared between all containers in the pod and deleted when the pod is removed.
> - Both containers mount the **same volume** (`grape-vol-cka06-str`) at **different paths**, enabling data sharing.

#### Step 3 — Apply the manifest

```bash
kubectl apply -f /tmp/grape-pod-cka06-str.yaml
```

### Validation

```bash
# Verify the pod is Running with 2/2 containers ready
kubectl get pod grape-pod-cka06-str
# READY: 2/2, STATUS: Running

# Verify volume mounts for each container
kubectl get pod grape-pod-cka06-str -o jsonpath='{range .spec.containers[*]}{.name}: {.volumeMounts[*].mountPath}{"\n"}{end}'
# nginx: /var/log/nginx

kubectl get pod grape-pod-cka06-str -o jsonpath='{range .spec.initContainers[*]}{.name}: {.volumeMounts[*].mountPath}{"\n"}{end}'
# busybox-sidecar: /usr/src

# Test data sharing: write from nginx container, read from busybox sidecar
kubectl exec grape-pod-cka06-str -c nginx -- sh -c 'echo "shared-data" > /var/log/nginx/testfile'
kubectl exec grape-pod-cka06-str -c busybox-sidecar -- cat /usr/src/testfile
# Expected output: shared-data

# Verify the volume type is emptyDir
kubectl get pod grape-pod-cka06-str -o jsonpath='{.spec.volumes[*]}'
# Should show: {"emptyDir":{},"name":"grape-vol-cka06-str"}
```

### 📖 Official Documentation

- [Volumes — emptyDir](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)
- [Sidecar Containers](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/)
- [Communicate Between Containers in the Same Pod Using a Shared Volume](https://kubernetes.io/docs/tasks/access-application-cluster/communicate-containers-same-pod-shared-volume/)
- [Multi-Container Pods](https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers)

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

### Troubleshooting Control Plane

```bash
# Check control plane component status
kubectl get pods -n kube-system

# Check node status
kubectl get nodes

# Use crictl when kubectl is unavailable
crictl ps -a                          # list all containers
crictl ps -a | grep kube-apiserver    # find specific container
crictl logs <container_id>            # get container logs

# Static pod manifests location
ls /etc/kubernetes/manifests/
# kube-apiserver.yaml
# kube-controller-manager.yaml
# kube-scheduler.yaml
# etcd.yaml
```

### ConfigMaps & Secrets

```bash
# Create ConfigMap from file
kubectl create configmap <name> --from-file=<path>

# Create ConfigMap from literal
kubectl create configmap <name> --from-literal=key=value

# View ConfigMap
kubectl get cm <name> -o yaml
```

### JSONPath Queries

```bash
# Get container resource limits
kubectl get pod <name> -o jsonpath='{.spec.containers[0].resources}'

# Get node names
kubectl get nodes -o jsonpath='{.items[*].metadata.name}'

# Get pod names on a specific node
kubectl get pods --field-selector spec.nodeName=<node> -o jsonpath='{.items[*].metadata.name}'
```

### Helm Commands

```bash
# Search Artifact Hub
helm search hub <chart> --list-repo-url

# Add a repo
helm repo add <name> <url>

# Update repos
helm repo update

# Search local repos
helm search repo <name>

# Install a chart
helm install <release> <chart>

# List releases
helm list -A

# Uninstall
helm uninstall <release>
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
yum list kubeadm         # RHEL/CentOS

# Upgrade plan (see what will change)
kubeadm upgrade plan

# Apply upgrade on control plane
kubeadm upgrade apply v1.xx.x

# Upgrade kubelet and kubectl
apt-get update && apt-get install -y kubelet=1.xx.x-00 kubectl=1.xx.x-00
systemctl daemon-reload && systemctl restart kubelet

# Upgrade worker nodes (after draining)
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
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
> - Bookmark the [Kubernetes Documentation](https://kubernetes.io/docs/) — it's allowed during the exam
