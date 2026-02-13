# 🚀 CKA Exam — Last-Minute Command Cheatsheet

> **Purpose:** Quick-glance reference for all critical commands, YAML snippets, and troubleshooting workflows  
> **Structure:** Organized by failure domain — when something breaks, find the section and follow the steps

---

## Table of Contents

| #   | Section                                                                 | Quick Jump                                      |
| --- | ----------------------------------------------------------------------- | ----------------------------------------------- |
| 1   | [kubeadm Troubleshooting](#1-kubeadm-troubleshooting)                   | Cluster init, join failures, reset              |
| 2   | [Certificate Management](#2-certificate-management)                     | kubeadm certs, openssl inspection, renewal      |
| 3   | [Kubelet Troubleshooting](#3-kubelet-troubleshooting)                   | Service status, logs, config                    |
| 4   | [Containerd Troubleshooting](#4-containerd-troubleshooting)             | crictl, runtime errors                          |
| 5   | [Kubeconfig & Contexts](#5-kubeconfig--contexts)                        | Config, context switching, troubleshooting      |
| 6   | [Static Pods & Control Plane](#6-static-pods--control-plane)            | Manifest paths, common fixes                    |
| 7   | [Control Plane Components Failing](#7-control-plane-components-failing) | API server, etcd, scheduler, controller-manager |
| 8   | [Cluster Upgrades](#8-cluster-upgrades-kubeadm)                         | Step-by-step upgrade workflow                   |
| 9   | [etcd Backup & Restore](#9-etcd-backup--restore)                        | Snapshot, restore, verify                       |
| 10  | [Services & Networking](#10-services--networking)                       | Service types, DNS, Ingress, Gateway API        |
| 11  | [Network Policies](#11-network-policies)                                | Allow/deny patterns, YAML templates             |
| 12  | [RBAC & Service Accounts](#12-rbac--service-accounts)                   | Roles, bindings, testing permissions            |
| 13  | [Debugging Pods & Deployments](#13-debugging-pods--deployments)         | Common failure patterns                         |
| 14  | [Storage](#14-storage-troubleshooting)                                  | PV, PVC, StorageClass, binding issues           |
| 15  | [Essential kubectl Patterns](#15-essential-kubectl-patterns)            | Imperative commands, dry-run, jsonpath          |

---

## 1. kubeadm Troubleshooting

### Init & Join

```bash
# Initialize control plane
kubeadm init --pod-network-cidr=10.244.0.0/16

# Generate join command (run on control plane)
kubeadm token create --print-join-command

# List active tokens
kubeadm token list

# Join worker node
kubeadm join <CP_IP>:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>

# If token expired, regenerate on control plane
kubeadm token create --print-join-command
```

### Common Failures

| Error                      | Cause                   | Fix                                         |
| -------------------------- | ----------------------- | ------------------------------------------- |
| `connection refused :6443` | API server not running  | Check static pod manifest, kubelet status   |
| `token expired`            | Join token TTL exceeded | `kubeadm token create --print-join-command` |
| `preflight failed`         | Missing prerequisites   | Check swap off, ports, container runtime    |
| `kubelet not healthy`      | Kubelet crashed         | `journalctl -u kubelet -f`, fix config      |

```bash
# Reset a failed kubeadm setup (DESTRUCTIVE)
kubeadm reset -f
rm -rf /etc/cni/net.d
iptables -F && iptables -t nat -F
```

### Pre-flight Checks (before kubeadm init)

```bash
# Disable swap (required)
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Load required kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay && modprobe br_netfilter

# Set required sysctl params (persist across reboots)
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
```

---

## 2. Certificate Management

### Check Expiration (kubeadm)

```bash
# All certificates at once
kubeadm certs check-expiration

# Output shows:
# CERTIFICATE                EXPIRES          RESIDUAL TIME
# admin.conf                 Feb 10, 2027     364d
# apiserver                  Feb 10, 2027     364d
# ...
```

### Renew Certificates

```bash
# Renew ALL certificates
kubeadm certs renew all

# Renew specific certificate
kubeadm certs renew apiserver
kubeadm certs renew apiserver-kubelet-client

# After renewal, restart control plane components
# (move manifests out and back, or restart kubelet)
systemctl restart kubelet
```

### Inspect with OpenSSL

```bash
# View full certificate details
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout

# Check expiry date only
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -enddate

# Check subject (CN, O)
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -subject

# Check issuer
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -issuer

# Check SANs (Subject Alternative Names)
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text | grep -A1 "Subject Alternative Name"

# Verify cert is signed by CA
openssl verify -CAfile /etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/apiserver.crt
```

### PKI Directory Layout

```
/etc/kubernetes/pki/
├── ca.crt / ca.key                    # Cluster CA
├── apiserver.crt / apiserver.key      # API server TLS
├── apiserver-kubelet-client.crt/key   # API → kubelet
├── apiserver-etcd-client.crt/key      # API → etcd
├── front-proxy-ca.crt/key             # Front proxy CA
├── sa.key / sa.pub                    # ServiceAccount signing
└── etcd/
    ├── ca.crt / ca.key                # etcd CA (SEPARATE!)
    ├── server.crt / server.key        # etcd TLS
    ├── peer.crt / peer.key            # etcd peer
    └── healthcheck-client.crt/key     # etcd health checks
```

> ⚠️ **Common Exam Trap:** API server must use `etcd/ca.crt` (not `ca.crt`) to connect to etcd. They have **separate** CA chains!

### Decode Certs from Kubeconfig

```bash
# Decode the client certificate from admin.conf
sudo grep client-certificate-data /etc/kubernetes/admin.conf \
  | awk '{print $2}' | base64 -d | openssl x509 -noout -subject
# Output: CN = kubernetes-admin, O = system:masters

# Decode the CA certificate
sudo grep certificate-authority-data /etc/kubernetes/admin.conf \
  | awk '{print $2}' | base64 -d | openssl x509 -noout -subject -issuer
```

### CSR (CertificateSigningRequest) Management

```bash
# List CSRs
kubectl get csr

# Approve a CSR
kubectl certificate approve <csr-name>

# Deny a CSR
kubectl certificate deny <csr-name>
```

---

## 3. Kubelet Troubleshooting

### Quick Diagnosis Flow

```
Node NotReady? → Check kubelet → Check container runtime → Check certificates
```

### Essential Commands

```bash
# Check kubelet status
systemctl status kubelet

# View kubelet logs (live)
journalctl -u kubelet -f

# View recent kubelet logs
journalctl -u kubelet --no-pager -n 50

# Restart kubelet
systemctl restart kubelet

# Enable kubelet on boot
systemctl enable kubelet

# Check kubelet config
cat /var/lib/kubelet/config.yaml

# Check kubelet service file
systemctl cat kubelet
# or
cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
```

### Common Kubelet Errors

| Symptom                         | Likely Cause        | Fix                                  |
| ------------------------------- | ------------------- | ------------------------------------ |
| Node `NotReady`                 | Kubelet stopped     | `systemctl start kubelet`            |
| `certificate has expired`       | Client cert expired | `kubeadm certs renew all`            |
| `failed to load kubelet config` | Bad config.yaml     | Check `/var/lib/kubelet/config.yaml` |
| `Cannot connect to runtime`     | containerd down     | `systemctl restart containerd`       |
| `static pod not starting`       | Bad manifest YAML   | Check `/etc/kubernetes/manifests/`   |

```bash
# Full debug: check everything in order
systemctl status kubelet
journalctl -u kubelet --no-pager -n 30
systemctl status containerd
ls /etc/kubernetes/manifests/
cat /var/lib/kubelet/config.yaml | head -20
```

---

## 4. Containerd Troubleshooting

### Essential Commands

```bash
# Check containerd status
systemctl status containerd

# Restart containerd
systemctl restart containerd

# View containerd logs
journalctl -u containerd -f

# Check containerd config
cat /etc/containerd/config.toml
```

### crictl — Container Runtime Interface CLI

```bash
# List all containers (including stopped)
crictl ps -a

# List running containers only
crictl ps

# Find specific container
crictl ps -a | grep kube-apiserver

# View container logs
crictl logs <container-id>

# Tail logs
crictl logs -f <container-id>

# List images
crictl images

# Inspect a container
crictl inspect <container-id>

# List pods
crictl pods
```

> 💡 **When to use crictl:** When `kubectl` is unavailable (API server down), `crictl` talks directly to the container runtime on the node.

---

## 5. Kubeconfig & Contexts

### View & Switch

```bash
# View current config
kubectl config view

# View with secrets shown
kubectl config view --raw

# See current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context-name>

# Set namespace for current context
kubectl config set-context --current --namespace=<ns>
```

### Kubeconfig Structure

```yaml
apiVersion: v1
kind: Config
clusters: # WHERE to connect
  - cluster:
      server: https://192.168.1.10:6443
      certificate-authority-data: <base64-ca-cert>
    name: my-cluster
contexts: # WHICH cluster + user + namespace combo
  - context:
      cluster: my-cluster
      user: admin
      namespace: default
    name: my-context
current-context: my-context
users: # WHO you are
  - name: admin
    user:
      client-certificate-data: <base64-cert>
      client-key-data: <base64-key>
```

### Troubleshooting

```bash
# Check which kubeconfig file is being used
echo $KUBECONFIG
# Default: ~/.kube/config

# Test connectivity with specific kubeconfig
kubectl --kubeconfig=/path/to/config get nodes

# Common fix: copy admin.conf
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# Verify API server reachability
kubectl cluster-info
```

---

## 6. Static Pods & Control Plane

### Key Facts

- **Location:** `/etc/kubernetes/manifests/`
- **Managed by:** kubelet (NOT the API server)
- **Auto-restart:** Editing a manifest auto-restarts the pod
- **Mirror pods:** Appear in `kubectl get pods -n kube-system` but can only be modified via the manifest file

### Static Pod Files

```bash
ls /etc/kubernetes/manifests/
# etcd.yaml
# kube-apiserver.yaml
# kube-controller-manager.yaml
# kube-scheduler.yaml
```

### Common Tasks

```bash
# Create a static pod
cat <<EOF > /etc/kubernetes/manifests/my-static-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-static-pod
  namespace: kube-system
spec:
  containers:
    - name: nginx
      image: nginx
EOF

# Delete a static pod
rm /etc/kubernetes/manifests/my-static-pod.yaml

# Force restart a static pod (move out and back)
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
# Wait 10 seconds
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

# Find static pod config path
cat /var/lib/kubelet/config.yaml | grep staticPodPath
```

---

## 7. Control Plane Components Failing

### Diagnosis Workflow

```
kubectl not working?
  ├─ YES → Use crictl (API server issue)
  │         crictl ps -a | grep kube-apiserver
  │         crictl logs <container-id>
  │         vi /etc/kubernetes/manifests/kube-apiserver.yaml
  │
  └─ NO (kubectl works but things are broken)
      ├─ Pods stuck Pending? → Scheduler issue
      │   kubectl get pods -n kube-system | grep scheduler
      │
      ├─ Deployments not scaling? → Controller Manager issue
      │   kubectl get pods -n kube-system | grep controller
      │
      └─ Data inconsistency? → etcd issue
          kubectl get pods -n kube-system | grep etcd
```

### kube-apiserver Common Fixes

```bash
# Check manifest
vi /etc/kubernetes/manifests/kube-apiserver.yaml

# Common errors:
# 1. Wrong etcd endpoint
#    --etcd-servers=https://127.0.0.1:2379  (NOT http, NOT --etcd-server)
#
# 2. Wrong etcd CA
#    --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt  (NOT /pki/ca.crt)
#
# 3. Wrong service-cluster-ip-range or service-node-port-range
#
# 4. Volume mount path doesn't match data-dir

# After fixing, wait for kubelet to restart the pod
sleep 30
crictl ps | grep kube-apiserver
```

### kube-scheduler Common Fixes

```bash
# Check if scheduler manifest exists
ls /etc/kubernetes/manifests/kube-scheduler.yaml

# If missing (moved to /tmp or elsewhere)
find / -name "kube-scheduler*" 2>/dev/null
mv /tmp/kube-scheduler.yaml /etc/kubernetes/manifests/

# Check scheduler logs
crictl logs $(crictl ps -a --name kube-scheduler -q | head -1)

# Common error: wrong kubeconfig path
# Fix: --kubeconfig=/etc/kubernetes/scheduler.conf
```

### kube-controller-manager Common Fixes

```bash
# Check logs
crictl logs $(crictl ps -a --name kube-controller -q | head -1)

# Common errors:
# 1. Wrong --service-account-private-key-file
#    Fix: /etc/kubernetes/pki/sa.key
#
# 2. Wrong --root-ca-file
#    Fix: /etc/kubernetes/pki/ca.crt
#
# 3. Wrong kubeconfig path
```

### etcd Common Fixes

```bash
# Check etcd logs
crictl logs $(crictl ps -a --name etcd -q | head -1)

# Common errors:
# 1. data-dir mismatch with volume mount
# 2. Wrong peer/client cert paths
# 3. Database space exceeded

# Check etcd health
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

---

## 8. Cluster Upgrades (kubeadm)

### Upgrade Workflow — Control Plane

```bash
# 1. Check available versions
apt list -a kubeadm 2>/dev/null | head -10

# 2. Upgrade kubeadm
apt-get update
apt-get install -y kubeadm=1.31.0-1.1

# 3. Verify upgrade plan
kubeadm upgrade plan

# 4. Apply the upgrade
kubeadm upgrade apply v1.31.0

# 5. Drain the control plane node
kubectl drain <cp-node> --ignore-daemonsets --delete-emptydir-data

# 6. Upgrade kubelet & kubectl
apt-get install -y kubelet=1.31.0-1.1 kubectl=1.31.0-1.1
systemctl daemon-reload
systemctl restart kubelet

# 7. Uncordon the node
kubectl uncordon <cp-node>
```

### Upgrade Workflow — Worker Node

```bash
# (From control plane) Drain the worker
kubectl drain <worker-node> --ignore-daemonsets --delete-emptydir-data

# (SSH to worker node)
ssh <worker-node>

# 1. Upgrade kubeadm
apt-get update
apt-get install -y kubeadm=1.31.0-1.1

# 2. Upgrade node config
kubeadm upgrade node

# 3. Upgrade kubelet & kubectl
apt-get install -y kubelet=1.31.0-1.1 kubectl=1.31.0-1.1
systemctl daemon-reload
systemctl restart kubelet

# 4. (Back on control plane) Uncordon
kubectl uncordon <worker-node>
```

### Verification

```bash
kubectl get nodes
# All nodes should show the new version
```

---

## 9. etcd Backup & Restore

### Backup

```bash
ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify the snapshot
ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db --write-table
```

### Restore

```bash
# 1. Stop kube-apiserver (move manifest away)
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/

# 2. Restore snapshot to a NEW directory
ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db \
  --data-dir=/var/lib/etcd-restored

# 3. Update etcd manifest to use the new data dir
vi /etc/kubernetes/manifests/etcd.yaml
```

```diff
# In the etcd manifest, update BOTH:
# a) The --data-dir flag
-    - --data-dir=/var/lib/etcd
+    - --data-dir=/var/lib/etcd-restored

# b) The hostPath volume
  volumes:
    - hostPath:
-       path: /var/lib/etcd
+       path: /var/lib/etcd-restored
      name: etcd-data
```

```bash
# 4. Restore the API server manifest
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

# 5. Wait and verify
sleep 30
kubectl get pods -n kube-system | grep etcd
kubectl get nodes
```

### Find etcd Cert Paths (if you forget)

```bash
# From the etcd pod manifest
grep -E "cert|key|trusted|data-dir" /etc/kubernetes/manifests/etcd.yaml
```

---

## 10. Services & Networking

### Service Types Quick Reference

| Type           | Scope         | Port                        | Use Case                        |
| -------------- | ------------- | --------------------------- | ------------------------------- |
| `ClusterIP`    | Internal only | Cluster-internal IP         | Default, internal communication |
| `NodePort`     | External      | `30000-32767` on every node | Dev/test external access        |
| `LoadBalancer` | External      | Cloud LB → NodePort → Pod   | Production (cloud)              |

### Imperative Service Commands

```bash
# Expose deployment as ClusterIP
kubectl expose deploy <name> --port=80 --target-port=8080

# Expose as NodePort
kubectl expose deploy <name> --port=80 --target-port=8080 --type=NodePort

# Expose with specific NodePort
kubectl expose deploy <name> --port=80 --type=NodePort --name=my-svc \
  --dry-run=client -o yaml > svc.yaml
# Then add nodePort: 30080 under ports and apply

# Check endpoints (are pods selected?)
kubectl get endpoints <svc-name>
# If <none> → selector doesn't match pod labels!
```

### DNS Troubleshooting

```bash
# Test DNS resolution from inside the cluster
kubectl run dns-test --rm -it --image=busybox --restart=Never -- nslookup kubernetes
kubectl run dns-test --rm -it --image=busybox --restart=Never -- nslookup <svc-name>.<namespace>.svc.cluster.local

# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check CoreDNS configmap (Corefile)
kubectl get cm coredns -n kube-system -o yaml

# Check if CoreDNS service exists
kubectl get svc -n kube-system kube-dns
```

### Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
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
                name: my-service
                port:
                  number: 80
```

### Gateway API — HTTPRoute

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-route
  namespace: my-ns
spec:
  parentRefs:
    - name: my-gateway
      namespace: gateway-ns
  rules:
    - matches:
        - headers:
            - name: X-Env
              value: canary
      backendRefs:
        - name: canary-svc
          port: 8080
    - backendRefs: # default (no match = catch-all)
        - name: main-svc
          port: 8080
```

---

## 11. Network Policies

### Key Rules

- **No NetworkPolicy = Allow All** traffic
- Adding ANY NetworkPolicy to a pod **denies all unmatched** traffic for that direction
- Must specify both `ingress` AND `egress` if you want to control both
- Network policies are **additive** (union of all policies)

### Deny All Ingress (Isolate a Namespace)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: my-ns
spec:
  podSelector: {} # applies to ALL pods
  policyTypes:
    - Ingress # results in deny-all ingress
```

### Allow Specific Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
  namespace: my-ns
spec:
  podSelector:
    matchLabels:
      app: backend # applies to pods with app=backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend # allow from pods with app=frontend
      ports:
        - port: 80
          protocol: TCP
```

### Allow Egress to Specific CIDR

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external
spec:
  podSelector:
    matchLabels:
      app: my-app
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 10.0.0.0/8
      ports:
        - port: 443
```

### Troubleshooting

```bash
# List network policies
kubectl get netpol -n <namespace>

# Describe a policy
kubectl describe netpol <name> -n <namespace>

# Test connectivity
kubectl exec <pod> -- curl -s --max-time 2 http://<target-svc>
kubectl exec <pod> -- wget -qO- --timeout=2 http://<target-svc>
```

---

## 12. RBAC & Service Accounts

### Quick Create Commands

```bash
# Create a ServiceAccount
kubectl create sa <sa-name> -n <namespace>

# Create a Role (namespaced)
kubectl create role <role-name> \
  --verb=get,list,watch \
  --resource=pods \
  -n <namespace>

# Create a RoleBinding
kubectl create rolebinding <binding-name> \
  --role=<role-name> \
  --serviceaccount=<namespace>:<sa-name> \
  -n <namespace>

# Create a ClusterRole (cluster-wide)
kubectl create clusterrole <role-name> \
  --verb=get,list,watch \
  --resource=nodes

# Create a ClusterRoleBinding
kubectl create clusterrolebinding <binding-name> \
  --clusterrole=<role-name> \
  --serviceaccount=<namespace>:<sa-name>
```

### Test Permissions

```bash
# Check what YOU can do
kubectl auth can-i create pods
kubectl auth can-i '*' '*'                      # admin check

# Check what a USER can do
kubectl auth can-i create pods --as=jane

# Check what a ServiceAccount can do
kubectl auth can-i list pods \
  --as=system:serviceaccount:<namespace>:<sa-name> \
  -n <namespace>

# List all permissions for a user
kubectl auth can-i --list --as=jane -n <namespace>
```

### YAML Templates

**Role (namespaced)**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
  - apiGroups: [""] # core API group
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list"]
```

**RoleBinding**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
  - kind: ServiceAccount
    name: my-sa
    namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Troubleshooting RBAC

```bash
# Forbidden error? Check:
# 1. Does the Role have the right verbs?
kubectl get role <name> -n <ns> -o yaml

# 2. Is the RoleBinding linking the right subject?
kubectl get rolebinding -n <ns> -o yaml

# 3. Is the ServiceAccount mounted in the pod?
kubectl get pod <name> -o yaml | grep serviceAccount
```

---

## 13. Debugging Pods & Deployments

### Pod Lifecycle Debugging

```bash
# Quick status check
kubectl get pods -o wide

# Detailed status (events at the bottom!)
kubectl describe pod <name>

# Pod events only
kubectl get events --field-selector involvedObject.name=<pod-name>

# Sorted by time
kubectl get events --sort-by='.lastTimestamp' -n <ns>

# Container logs
kubectl logs <pod>                              # single container
kubectl logs <pod> -c <container>               # specific container
kubectl logs <pod> --previous                   # previous crash
kubectl logs <pod> -f                           # follow/tail
```

### Common Pod Statuses & Fixes

| Status                 | Cause                    | Debug                                                              |
| ---------------------- | ------------------------ | ------------------------------------------------------------------ |
| `Pending`              | No node can schedule     | `describe pod` → check Events, node resources, taints              |
| `ImagePullBackOff`     | Wrong image/tag/registry | Check image name, registry auth                                    |
| `CrashLoopBackOff`     | Container keeps crashing | `kubectl logs --previous`, check command/args                      |
| `Init:Error`           | Init container failed    | `kubectl logs <pod> -c <init-container>`                           |
| `CreateContainerError` | Missing ConfigMap/Secret | `describe pod`, check volume mounts                                |
| `Terminating (stuck)`  | Finalizer or PDB         | Force delete: `kubectl delete pod <name> --force --grace-period=0` |

### Deployment Troubleshooting

```bash
# Check rollout status
kubectl rollout status deploy <name>

# Check rollout history
kubectl rollout history deploy <name>

# Undo last rollout
kubectl rollout undo deploy <name>

# Undo to specific revision
kubectl rollout undo deploy <name> --to-revision=2

# Rolling restart (no config change)
kubectl rollout restart deploy <name>

# Scale
kubectl scale deploy <name> --replicas=5
```

### Exec Into Pod

```bash
# Interactive shell
kubectl exec -it <pod> -- /bin/sh
kubectl exec -it <pod> -- /bin/bash

# Specific container in multi-container pod
kubectl exec -it <pod> -c <container> -- /bin/sh

# Run a command
kubectl exec <pod> -- cat /etc/config/app.conf
kubectl exec <pod> -- env | grep APP
```

### Temporary Debug Pod

```bash
# Quick busybox for network/DNS testing
kubectl run tmp --rm -it --image=busybox --restart=Never -- sh

# With curl available
kubectl run tmp --rm -it --image=curlimages/curl --restart=Never -- sh

# In a specific namespace
kubectl run tmp --rm -it -n <ns> --image=busybox --restart=Never -- sh
```

---

## 14. Storage Troubleshooting

### Quick Reference

```bash
# List StorageClasses
kubectl get sc

# List PVs and PVCs
kubectl get pv
kubectl get pvc -A

# Check PV/PVC binding
kubectl describe pvc <name>
```

### PVC Stuck in Pending?

| Cause                 | How to Check                 | Fix                                   |
| --------------------- | ---------------------------- | ------------------------------------- |
| No matching PV        | `describe pvc` → Events      | Create PV with matching spec          |
| Capacity mismatch     | PVC requests > PV capacity   | Increase PV `storage`                 |
| Access mode mismatch  | PVC ≠ PV access mode         | Match `ReadWriteOnce`/`ReadWriteMany` |
| StorageClass mismatch | Different `storageClassName` | Match names or use `""` for no class  |
| WaitForFirstConsumer  | Normal for this binding mode | PVC binds when a pod uses it          |

### StorageClass Template

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: my-sc
provisioner: kubernetes.io/no-provisioner # for static PVs
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

### PV + PVC Template (with Node Affinity & Label Selector)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
  labels:
    tier: gold # for PVC selector
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: /opt/data
  storageClassName: my-sc
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - node01
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Mi
  storageClassName: my-sc
  selector:
    matchLabels:
      tier: gold
```

---

## 15. Essential kubectl Patterns

### Imperative Commands (Save Time in Exam!)

```bash
# Generate YAML without creating
kubectl run nginx --image=nginx --restart=Never --dry-run=client -o yaml > pod.yaml
kubectl create deploy web --image=nginx --replicas=3 --dry-run=client -o yaml > deploy.yaml
kubectl create svc clusterip my-svc --tcp=80:8080 --dry-run=client -o yaml > svc.yaml
kubectl create configmap my-cm --from-literal=key=value --dry-run=client -o yaml > cm.yaml
kubectl create secret generic my-secret --from-literal=pass=s3cr3t --dry-run=client -o yaml

# Create and expose in one go
kubectl run nginx --image=nginx --restart=Never --port=80
kubectl expose pod nginx --port=80 --type=NodePort
```

### JSONPath — Get Exactly What You Need

```bash
# Single resource field
kubectl get pod <name> -o jsonpath='{.spec.containers[0].image}'

# All items
kubectl get nodes -o jsonpath='{.items[*].metadata.name}'

# Formatted output with range
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'

# Filter
kubectl get pods -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'

# Node internal IPs
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'

# Custom columns (easier for tables)
kubectl get pods -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image,NODE:.spec.nodeName
```

### Sorting

```bash
kubectl get pods --sort-by='.metadata.creationTimestamp'
kubectl get pv --sort-by='.spec.capacity.storage'
kubectl get pods --sort-by='.status.containerStatuses[0].restartCount'
```

### Labels & Selectors

```bash
# Add a label
kubectl label pod <name> env=prod

# Remove a label
kubectl label pod <name> env-

# Filter by label
kubectl get pods -l app=nginx
kubectl get pods -l 'app in (nginx,web)'
kubectl get pods -l app!=frontend
```

### Taints & Tolerations

```bash
# Add taint
kubectl taint nodes <node> key=value:NoSchedule

# Remove taint
kubectl taint nodes <node> key:NoSchedule-

# View taints
kubectl describe node <node> | grep -i taint
```

### Node Operations

```bash
# Drain (for maintenance/upgrade)
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data

# Cordon (prevent new scheduling)
kubectl cordon <node>

# Uncordon (allow scheduling again)
kubectl uncordon <node>
```

### Helm Commands

```bash
# List all releases
helm ls -A

# List repos
helm repo ls

# Update repos
helm repo update [repo-name]

# Search Artifact Hub
helm search hub <chart> --list-repo-url

# Search local repos with versions
helm search repo <name> -l

# Install
helm install <release> <chart> -n <ns> --version=<ver>

# Upgrade
helm upgrade <release> <chart> -n <ns> --version=<ver> --set key=value

# Uninstall
helm uninstall <release> -n <ns>
```

### Kustomize

```bash
# Preview rendered output
kubectl kustomize <directory>

# Apply
kubectl apply -k <directory>
# or
kubectl kustomize <directory> | kubectl apply -f -
```

---

## 🧠 Exam Day Reminders

> - **Always SSH to the correct cluster before running commands**
> - Use `kubectl explain <resource>.spec` to look up fields live during the exam
> - Use `--dry-run=client -o yaml` for fast YAML generation
> - Bookmark these K8s docs pages: [kubectl cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/), [tasks](https://kubernetes.io/docs/tasks/)
> - When `kubectl` is broken → use `crictl` + check `/etc/kubernetes/manifests/`
> - Always check `kubectl get events` first when a pod is misbehaving
> - For PVC issues: check capacity, access mode, storageClassName, and labels
> - For service issues: check selector labels and endpoints
> - **Time management:** Skip hard questions, come back later
