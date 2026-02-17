# Kubernetes Cluster & Control Plane Troubleshooting Guide

> **Purpose:** Production-grade, one-stop troubleshooting reference for Kubernetes control plane and node components. Designed for rapid diagnosis under pressure — real-world error logs, root cause analysis, exact commands to fix, and verification steps. Covers kubeadm-based clusters.

---

## Table of Contents

- [1. Architecture Overview](#1-architecture-overview)
- [2. Troubleshooting Methodology](#2-troubleshooting-methodology)
- [3. kube-apiserver](#3-kube-apiserver)
- [4. etcd](#4-etcd)
- [5. kube-controller-manager](#5-kube-controller-manager)
- [6. kube-scheduler](#6-kube-scheduler)
- [7. kubelet](#7-kubelet)
- [8. containerd](#8-containerd)
- [9. kube-proxy](#9-kube-proxy)
- [10. CNI Plugins](#10-cni-plugins)
- [11. Command Cheat Sheets](#11-command-cheat-sheets)
- [12. Cluster Health Verification Checklist](#12-cluster-health-verification-checklist)
- [13. Documentation References](#13-documentation-references)

---

## 1. Architecture Overview

### How the Control Plane Works in kubeadm Clusters

In a kubeadm-managed cluster, the control plane runs as **static pods** managed directly by the kubelet. The kubelet watches a manifest directory (default: `/etc/kubernetes/manifests/`) and automatically creates, restarts, or destroys pods based on the YAML files it finds there.

```
                    ┌──────────────────────────────────────────────┐
                    │            CONTROL PLANE NODE                │
                    │                                              │
  User/API ──────► │  kube-apiserver ◄──────► etcd               │
                    │       │                                      │
                    │       ├──► kube-controller-manager           │
                    │       └──► kube-scheduler                    │
                    │                                              │
                    │  kubelet (systemd) ── manages all above      │
                    │  containerd (systemd) ── runs containers     │
                    └──────────────────────────────────────────────┘
                                        │
                    ┌───────────────────────────────────────────────┐
                    │              WORKER NODE                      │
                    │                                               │
                    │  kubelet (systemd) ── registers with apiserver│
                    │  containerd (systemd) ── runs containers      │
                    │  kube-proxy (DaemonSet) ── manages iptables   │
                    │  CNI plugin ── assigns Pod IPs                │
                    └───────────────────────────────────────────────┘
```

### Component Configuration Map

| Component | Type | Config Location | Managed By |
|---|---|---|---|
| kube-apiserver | Static Pod | `/etc/kubernetes/manifests/kube-apiserver.yaml` | kubelet |
| etcd | Static Pod | `/etc/kubernetes/manifests/etcd.yaml` | kubelet |
| kube-controller-manager | Static Pod | `/etc/kubernetes/manifests/kube-controller-manager.yaml` | kubelet |
| kube-scheduler | Static Pod | `/etc/kubernetes/manifests/kube-scheduler.yaml` | kubelet |
| kubelet | systemd service | `/var/lib/kubelet/config.yaml`, `/etc/systemd/system/kubelet.service.d/10-kubeadm.conf` | systemd |
| containerd | systemd service | `/etc/containerd/config.toml` | systemd |
| kube-proxy | DaemonSet | ConfigMap `kube-proxy` in `kube-system` | Deployment controller |
| CNI | Binary + config | `/opt/cni/bin/`, `/etc/cni/net.d/` | Manually or operator |

### How Static Pods Work

Static pods are special: the kubelet creates them directly without the API server being involved. This is how the control plane bootstraps itself — the kubelet starts the API server, etcd, scheduler, and controller-manager as containers before the API server is even available.

Key behaviors:
- Kubelet watches `/etc/kubernetes/manifests/` (configured via `staticPodPath` in kubelet config)
- Any YAML file added, modified, or removed triggers pod creation/update/deletion
- Static pods are **visible** via `kubectl get pods -n kube-system` (as mirror pods) but **cannot be managed** via kubectl — you must edit the manifest file directly
- The kubelet auto-restarts static pods if they crash — there is a brief delay (10-30 seconds typically)
- If you edit a manifest, the kubelet detects the change and recreates the pod

**Implication for troubleshooting:** If a control plane static pod is failing, you must look at the **manifest YAML file** on the node, not use `kubectl edit`. And if the API server itself is down, `kubectl` won't work at all — you must use `crictl` and `journalctl` directly on the node.

### Certificate Landscape

kubeadm clusters use an extensive PKI. All certs live under `/etc/kubernetes/pki/`:

```
/etc/kubernetes/pki/
├── ca.crt, ca.key                          # Cluster CA
├── apiserver.crt, apiserver.key            # API server serving cert
├── apiserver-kubelet-client.crt, .key      # API server → kubelet
├── apiserver-etcd-client.crt, .key         # API server → etcd
├── front-proxy-ca.crt, front-proxy-ca.key  # Aggregation layer CA
├── front-proxy-client.crt, .key            # Aggregation layer client
├── sa.key, sa.pub                          # Service account signing
└── etcd/
    ├── ca.crt, ca.key                      # etcd CA
    ├── server.crt, server.key              # etcd server
    ├── peer.crt, peer.key                  # etcd peer communication
    ├── healthcheck-client.crt, .key        # etcd health checks
```

Kubeconfig files in `/etc/kubernetes/` reference these certs:

```
/etc/kubernetes/
├── admin.conf              # cluster-admin kubeconfig
├── controller-manager.conf # controller-manager kubeconfig
├── scheduler.conf          # scheduler kubeconfig
└── kubelet.conf            # kubelet kubeconfig (on control plane node)
```

---

## 2. Troubleshooting Methodology

### The Systematic Approach

When a cluster is broken, follow this exact order — it mirrors the dependency chain:

```
Step 1: Is the node OS up?
        └─ Can you SSH in? Is systemd running?

Step 2: Is containerd running?
        └─ systemctl status containerd

Step 3: Is kubelet running?
        └─ systemctl status kubelet
        └─ journalctl -u kubelet --no-pager | tail -50

Step 4: Are static pods running?
        └─ crictl ps -a
        └─ crictl logs <container-id>

Step 5: Is kube-apiserver responding?
        └─ kubectl cluster-info
        └─ curl -k https://localhost:6443/healthz

Step 6: Are other control plane components healthy?
        └─ kubectl get pods -n kube-system
        └─ kubectl get componentstatuses (deprecated but sometimes useful)

Step 7: Are worker nodes registered and Ready?
        └─ kubectl get nodes

Step 8: Is networking functional?
        └─ Can pods get IPs? Can pods communicate?
```

**Rule of thumb:** Work bottom-up. If step N fails, everything above it will also fail. Fix the lowest-level failure first.

### Log Analysis Techniques

#### journalctl for systemd services (kubelet, containerd)

```bash
# Last 50 lines of kubelet logs
journalctl -u kubelet --no-pager -l | tail -50

# Follow kubelet logs in real-time
journalctl -u kubelet -f

# Logs since last boot
journalctl -u kubelet -b

# Logs from a specific time window
journalctl -u kubelet --since "2025-01-15 10:00:00" --until "2025-01-15 10:30:00"

# Only error-level messages
journalctl -u kubelet -p err

# Grep for specific patterns
journalctl -u kubelet --no-pager | grep -i "error\|fail\|unable\|refused"
```

#### crictl for container-level debugging (static pods)

When `kubectl` doesn't work (because the API server is down), `crictl` talks directly to containerd:

```bash
# List all containers (including stopped/failed)
sudo crictl ps -a

# List only running containers
sudo crictl ps

# Filter by name
sudo crictl ps -a | grep apiserver
sudo crictl ps -a | grep etcd

# View logs of a container
sudo crictl logs <container-id>
sudo crictl logs --tail 50 <container-id>

# Inspect container details (env vars, mounts, config)
sudo crictl inspect <container-id>

# List pods (groups of containers)
sudo crictl pods

# List images
sudo crictl images
```

**Important:** If `crictl` gives a socket error, check `/etc/crictl.yaml`:

```yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
```

### Identifying Which Component Failed

Quick diagnostic script:

```bash
echo "=== containerd ==="
systemctl is-active containerd

echo "=== kubelet ==="
systemctl is-active kubelet

echo "=== Static Pods ==="
crictl ps -a 2>/dev/null | grep -E "apiserver|etcd|scheduler|controller" || echo "crictl unavailable"

echo "=== API Server ==="
curl -sk https://localhost:6443/healthz 2>/dev/null || echo "API server unreachable"

echo "=== kubectl ==="
kubectl get nodes 2>/dev/null || echo "kubectl unavailable"
```

---

## 3. kube-apiserver

### Purpose & Responsibilities

The API server is the central hub of the entire cluster. Every component communicates through it. It handles authentication and authorization of all API requests, validates and persists resource definitions to etcd, serves the REST API for kubectl and all controllers, and acts as the gateway between etcd and every other component — nothing else talks to etcd directly.

### Configuration

**Static pod manifest:** `/etc/kubernetes/manifests/kube-apiserver.yaml`

**Key flags to know:**

| Flag | Purpose | Common Value |
|---|---|---|
| `--etcd-servers` | etcd endpoint URL | `https://127.0.0.1:2379` |
| `--etcd-cafile` | CA to verify etcd | `/etc/kubernetes/pki/etcd/ca.crt` |
| `--etcd-certfile` | Client cert for etcd | `/etc/kubernetes/pki/apiserver-etcd-client.crt` |
| `--etcd-keyfile` | Client key for etcd | `/etc/kubernetes/pki/apiserver-etcd-client.key` |
| `--tls-cert-file` | API server serving cert | `/etc/kubernetes/pki/apiserver.crt` |
| `--tls-private-key-file` | API server private key | `/etc/kubernetes/pki/apiserver.key` |
| `--client-ca-file` | CA for client certs | `/etc/kubernetes/pki/ca.crt` |
| `--advertise-address` | IP clients connect to | Node's primary IP |
| `--service-cluster-ip-range` | ClusterIP CIDR | `10.96.0.0/12` |
| `--enable-admission-plugins` | Active admission controllers | `NodeRestriction,...` |
| `--authorization-mode` | Auth modes | `Node,RBAC` |
| `--secure-port` | HTTPS port | `6443` |

### Interactions with Other Components

```
etcd ◄────── kube-apiserver ──────► kubelet (node registration, pod status)
                   │
                   ├──► kube-scheduler (watches unscheduled pods)
                   ├──► kube-controller-manager (watches resource state)
                   ├──► kube-proxy (watches Services/Endpoints)
                   └──► kubectl / client SDKs (user requests)
```

### Failure Scenario 1: etcd Connection Failure

**Sample log (from `crictl logs` or `journalctl`):**

```
E0115 10:23:45.678901  1 controller.go:152] Unable to remove old endpoints from
kubernetes service: StorageError: key not found, Code: 1, Key: /registry/masterleases/192.168.1.10,
AdditionalErrorMsg:
E0115 10:23:45.789012  1 status.go:71] apiserver received an error that is not
an metav1.Status: &errors.errorString{s:"context deadline exceeded"}
W0115 10:23:46.123456  1 clientconn.go:1331] [core] grpc: addrConn.createTransport
failed to connect to {127.0.0.1:2379 127.0.0.1}. Err: connection error:
desc = "transport: Error while dialing: dial tcp 127.0.0.1:2379: connect: connection refused"
```

**Root Cause:** The API server cannot reach etcd. Either etcd is down, the endpoint URL is wrong, or TLS certs are incorrect.

**Diagnosis:**

```bash
# Check if etcd container is running
sudo crictl ps -a | grep etcd

# Check etcd logs
sudo crictl logs $(sudo crictl ps -a | grep etcd | head -1 | awk '{print $1}')

# Verify the etcd endpoint in apiserver manifest
sudo grep etcd-servers /etc/kubernetes/manifests/kube-apiserver.yaml

# Test etcd connectivity directly
sudo curl -k --cert /etc/kubernetes/pki/apiserver-etcd-client.crt \
  --key /etc/kubernetes/pki/apiserver-etcd-client.key \
  https://127.0.0.1:2379/health
```

**Fix:**

```bash
# If etcd is running but apiserver has wrong endpoint:
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Fix: --etcd-servers=https://<correct-ip>:2379

# If etcd cert files are wrong:
ls -la /etc/kubernetes/pki/etcd/
ls -la /etc/kubernetes/pki/apiserver-etcd-client.*
# Fix the paths in the manifest

# If etcd itself is down, see Section 4
```

**Verification:**

```bash
# Wait 30-60 seconds for kubelet to restart the static pod
sudo crictl ps | grep apiserver
curl -sk https://localhost:6443/healthz
# Should return: ok
kubectl get nodes
```

### Failure Scenario 2: TLS Certificate Errors

**Sample log:**

```
E0115 14:05:12.345678  1 secure_serving.go:197] Failed to listen and serve:
tls: failed to find any PEM data in certificate input
E0115 14:05:12.345678  1 secure_serving.go:197] Failed to listen and serve:
tls: private key does not match public key
x509: certificate has expired or is not yet valid:
current time 2025-01-15T14:05:12Z is after 2024-01-15T00:00:00Z
```

**Root Cause:** Certificates are expired, the cert/key pair don't match, or the cert file path is wrong and points to an empty/invalid file.

**Diagnosis:**

```bash
# Check certificate expiry dates
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates
# notBefore=...
# notAfter=...

# Verify cert and key match (the modulus hashes should be identical)
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -modulus | md5sum
sudo openssl rsa -in /etc/kubernetes/pki/apiserver.key -noout -modulus | md5sum

# Check all cert expirations at once
sudo kubeadm certs check-expiration

# Verify the cert's SANs (Subject Alternative Names)
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text | grep -A 1 "Subject Alternative Name"
```

**Fix:**

```bash
# Renew all certificates
sudo kubeadm certs renew all

# Renew only apiserver cert
sudo kubeadm certs renew apiserver

# Regenerate a specific cert from scratch
sudo rm /etc/kubernetes/pki/apiserver.crt /etc/kubernetes/pki/apiserver.key
sudo kubeadm init phase certs apiserver

# After renewing, restart the affected static pods
sudo systemctl restart kubelet
# Or touch the manifest to trigger recreation:
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sleep 10
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
```

**Verification:**

```bash
sudo kubeadm certs check-expiration
sudo crictl ps | grep apiserver
curl -sk https://localhost:6443/healthz
```

### Failure Scenario 3: Admission Plugin Misconfiguration

**Sample log:**

```
E0115 15:30:00.123456  1 plugins.go:158] Error creating admission plugin "AlwaysPullImages":
admission plugin "AlwaysPullImages" is unknown
Error: unknown admission plugin: "AlwaysPullImage"  # Note the typo
F0115 15:30:00.234567  1 instance.go:290] Error creating apiserver:
admission plugin "FakePlugin" is unknown
```

**Root Cause:** A typo in the `--enable-admission-plugins` flag, or a non-existent plugin name.

**Diagnosis:**

```bash
sudo grep enable-admission-plugins /etc/kubernetes/manifests/kube-apiserver.yaml
```

**Fix:**

```bash
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
# Fix the plugin name. Valid plugins include:
# NodeRestriction, NamespaceLifecycle, LimitRanger, ServiceAccount,
# DefaultStorageClass, DefaultTolerationSeconds, MutatingAdmissionWebhook,
# ValidatingAdmissionWebhook, ResourceQuota, PodSecurity
```

### Failure Scenario 4: Volume Mount Failures

**Sample log (from `journalctl -u kubelet`):**

```
E0115 16:00:00.123456 kubelet.go:2394] Error creating pod:
MountVolume.SetUp failed for volume "etcd-certs" :
hostPath type check failed: /etc/kubernetes/pki/etcd is not a directory
E0115 16:00:00.234567 kubelet.go:2394] Error syncing pod "kube-apiserver-node01":
failed to "CreatePodSandbox" for pod: hostPath "/var/log/kubernetes" not found
```

**Root Cause:** The hostPath volume mounts in the static pod manifest reference directories or files that don't exist on the node (moved, deleted, or wrong path after migration).

**Diagnosis:**

```bash
# Check all volume mounts in the manifest
sudo grep -A 3 "hostPath" /etc/kubernetes/manifests/kube-apiserver.yaml

# Verify each path exists
sudo ls -la /etc/kubernetes/pki/
sudo ls -la /etc/kubernetes/pki/etcd/
```

**Fix:**

```bash
# Create missing directories
sudo mkdir -p /etc/kubernetes/pki/etcd
# Or fix the paths in the manifest to point to the correct location
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

### Failure Scenario 5: Port Conflict

**Sample log:**

```
E0115 17:00:00.123456  1 secure_serving.go:197] Failed to listen and serve:
listen tcp 0.0.0.0:6443: bind: address already in use
```

**Root Cause:** Another process is already using port 6443.

**Diagnosis:**

```bash
sudo ss -tlnp | grep 6443
sudo lsof -i :6443
```

**Fix:**

```bash
# Kill the conflicting process, or
# Change the apiserver port in the manifest (not recommended unless necessary):
# --secure-port=6444  (then update all kubeconfigs)
```

---

## 4. etcd

### Purpose & Responsibilities

etcd is the distributed key-value store that holds the entire cluster state — every pod, service, secret, configmap, and RBAC rule. If etcd goes down, the API server cannot read or write state, effectively freezing the cluster. Nothing new can be scheduled, no changes can be made, but existing workloads continue running (they just can't be managed).

### Configuration

**Static pod manifest:** `/etc/kubernetes/manifests/etcd.yaml`

**Key flags:**

| Flag | Purpose | Common Value |
|---|---|---|
| `--data-dir` | Where etcd stores data | `/var/lib/etcd` |
| `--listen-client-urls` | Client listen address | `https://127.0.0.1:2379,https://<node-ip>:2379` |
| `--advertise-client-urls` | URLs advertised to clients | `https://<node-ip>:2379` |
| `--listen-peer-urls` | Peer listen address (multi-node) | `https://<node-ip>:2380` |
| `--initial-advertise-peer-urls` | Peer URLs advertised | `https://<node-ip>:2380` |
| `--cert-file` | Server TLS cert | `/etc/kubernetes/pki/etcd/server.crt` |
| `--key-file` | Server TLS key | `/etc/kubernetes/pki/etcd/server.key` |
| `--trusted-ca-file` | Client CA | `/etc/kubernetes/pki/etcd/ca.crt` |
| `--peer-cert-file` | Peer TLS cert | `/etc/kubernetes/pki/etcd/peer.crt` |
| `--peer-key-file` | Peer TLS key | `/etc/kubernetes/pki/etcd/peer.key` |
| `--peer-trusted-ca-file` | Peer CA | `/etc/kubernetes/pki/etcd/ca.crt` |

### Interactions

```
kube-apiserver ──► etcd (ONLY component that talks to etcd)
                   │
                   ├── Reads: all resource state
                   ├── Writes: all resource changes
                   └── Watches: change notifications
```

**No other component communicates with etcd directly.** The API server is the sole gateway.

### Failure Scenario 1: Connection Refused

**Sample log (from apiserver or etcd container):**

```
{"level":"warn","ts":"2025-01-15T10:00:00.123Z","caller":"rafthttp/stream.go:649",
"msg":"lost the TCP streaming connection with peer",
"stream-id":"abc123","error":"read tcp 192.168.1.10:2380->192.168.1.11:43210: read: connection reset by peer"}

E0115 10:00:01.234567  1 controller.go:152] Unable to remove old endpoints from
kubernetes service: etcdserver: leader changed
```

**Root Cause:** etcd is not running, the listen URL is misconfigured, or firewall is blocking port 2379/2380.

**Diagnosis:**

```bash
# Check etcd container
sudo crictl ps -a | grep etcd
sudo crictl logs $(sudo crictl ps -a | grep etcd | head -1 | awk '{print $1}') 2>&1 | tail -30

# Check etcd health using etcdctl
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  endpoint health

# Check if port is listening
sudo ss -tlnp | grep 2379
```

**Fix:**

```bash
# Verify listen URLs in manifest
sudo grep listen-client /etc/kubernetes/manifests/etcd.yaml
# Should include https://127.0.0.1:2379

# If etcd won't start due to corrupt data, restore from backup:
sudo ETCDCTL_API=3 etcdctl snapshot restore /path/to/backup.db \
  --data-dir=/var/lib/etcd-restored

# Update the manifest to use the new data dir:
sudo vi /etc/kubernetes/manifests/etcd.yaml
# Change --data-dir=/var/lib/etcd-restored
```

### Failure Scenario 2: WAL Corruption / Data Directory Issues

**Sample log:**

```
{"level":"fatal","ts":"2025-01-15T10:05:00.123Z","caller":"etcdmain/etcd.go:204",
"msg":"discovery failed","error":"walpb: crc mismatch"}

{"level":"fatal","ts":"2025-01-15T10:05:00.234Z","msg":"failed to recover WAL",
"error":"fileutil: file already locked"}
```

**Root Cause:** WAL (Write-Ahead Log) is corrupted, often from a hard crash, disk failure, or running two etcd instances on the same data directory.

**Diagnosis:**

```bash
# Check data directory permissions and contents
sudo ls -la /var/lib/etcd/
sudo ls -la /var/lib/etcd/member/
sudo du -sh /var/lib/etcd/

# Check for lock files
sudo lsof +D /var/lib/etcd/
```

**Fix (if backup exists):**

```bash
# Stop etcd (move manifest away)
sudo mv /etc/kubernetes/manifests/etcd.yaml /tmp/

# Back up the corrupted data
sudo mv /var/lib/etcd /var/lib/etcd-corrupted

# Restore from snapshot
sudo ETCDCTL_API=3 etcdctl snapshot restore /path/to/snapshot.db \
  --data-dir=/var/lib/etcd \
  --name=<node-name> \
  --initial-cluster=<node-name>=https://<node-ip>:2380 \
  --initial-advertise-peer-urls=https://<node-ip>:2380

# Restore manifest
sudo mv /tmp/etcd.yaml /etc/kubernetes/manifests/
```

**Fix (if no backup — last resort):**

```bash
# WARNING: This destroys ALL cluster state. Pods will continue running
# but the cluster loses all configuration.
sudo mv /etc/kubernetes/manifests/etcd.yaml /tmp/
sudo rm -rf /var/lib/etcd
sudo mkdir -p /var/lib/etcd
sudo mv /tmp/etcd.yaml /etc/kubernetes/manifests/
# etcd will start fresh with empty state
# You will need to re-initialize the cluster with kubeadm
```

### Failure Scenario 3: Disk Full

**Sample log:**

```
{"level":"warn","ts":"2025-01-15T11:00:00.123Z","caller":"mvcc/kvstore.go:400",
"msg":"database space exceeded","quota-size-bytes":2147483648,"current-size-bytes":2147483648}

etcdserver: mvcc: database space exceeded
```

**Root Cause:** etcd's database has exceeded its quota (default 2GB). This can happen from excessive event generation, large secrets, or not compacting/defragmenting.

**Diagnosis:**

```bash
# Check database size
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  endpoint status --write-out=table

# Check disk space
df -h /var/lib/etcd
```

**Fix:**

```bash
# Set the ETCDCTL environment for convenience
export ETCDCTL_API=3
export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379
export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/healthcheck-client.crt
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/healthcheck-client.key

# Compact old revisions
REV=$(etcdctl endpoint status --write-out="json" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['Status']['header']['revision'])")
etcdctl compact $REV

# Defragment
etcdctl defrag

# Disarm the alarm
etcdctl alarm disarm

# Verify
etcdctl endpoint status --write-out=table
```

### Failure Scenario 4: Quorum Loss (Multi-Node etcd)

**Sample log:**

```
{"level":"warn","ts":"2025-01-15T12:00:00.123Z","caller":"raft/raft.go:924",
"msg":"became inactive","id":"abc123","lost":"peer-id"}
rafthttp: failed to find member for peer abc123 in cluster
etcdserver: publish error: etcdserver: request timed out
```

**Root Cause:** In a 3-node etcd cluster, 2 or more members are down. etcd requires a majority (quorum) to function. With 3 members, you need at least 2 alive.

**Diagnosis:**

```bash
etcdctl member list --write-out=table
etcdctl endpoint health --cluster
```

**Fix:**

```bash
# If a member is permanently gone, remove it and add a replacement:
etcdctl member remove <member-id>
etcdctl member add <new-name> --peer-urls=https://<new-ip>:2380
```

### etcd Backup and Restore (Essential Skill)

```bash
# BACKUP
sudo ETCDCTL_API=3 etcdctl snapshot save /opt/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify backup
sudo ETCDCTL_API=3 etcdctl snapshot status /opt/etcd-backup.db --write-out=table

# RESTORE
sudo mv /etc/kubernetes/manifests/etcd.yaml /tmp/
sudo mv /var/lib/etcd /var/lib/etcd-old
sudo ETCDCTL_API=3 etcdctl snapshot restore /opt/etcd-backup.db \
  --data-dir=/var/lib/etcd
sudo mv /tmp/etcd.yaml /etc/kubernetes/manifests/
```

---

## 5. kube-controller-manager

### Purpose & Responsibilities

The controller manager runs all built-in controllers in a single process. It watches the cluster state via the API server and makes changes to move the actual state toward the desired state. Key controllers include: ReplicaSet controller (ensures correct pod replica count), Deployment controller (manages rollouts), Node controller (monitors node health, evicts pods from unhealthy nodes), Service Account controller (creates default service accounts), Endpoint controller (populates Endpoints objects), and Namespace controller (handles namespace lifecycle).

### Configuration

**Static pod manifest:** `/etc/kubernetes/manifests/kube-controller-manager.yaml`

**Key flags:**

| Flag | Purpose |
|---|---|
| `--kubeconfig` | Path to kubeconfig for API server auth (usually `/etc/kubernetes/controller-manager.conf`) |
| `--cluster-signing-cert-file` | CA cert for signing CSRs |
| `--cluster-signing-key-file` | CA key for signing CSRs |
| `--root-ca-file` | CA cert injected into service account tokens |
| `--service-account-private-key-file` | Key for signing service account tokens |
| `--use-service-account-credentials` | Each controller gets its own SA |
| `--controllers` | Which controllers to enable (default: `*`) |
| `--leader-elect` | Enable leader election (default: true) |
| `--cluster-cidr` | Pod CIDR (used by IPAM) |

### Common Failure Scenarios

**Scenario: Wrong kubeconfig path**

```
F0115 14:00:00.123456  1 controllermanager.go:250] error creating
informerFactory: Get "https://192.168.1.10:6443/api?timeout=32s":
dial tcp 192.168.1.10:6443: connect: connection refused
E0115 14:00:00.234567  1 server.go:302] stat /etc/kubernetes/controller-manager.conf:
no such file or directory
```

**Diagnosis and Fix:**

```bash
# Check the kubeconfig path in the manifest
sudo grep kubeconfig /etc/kubernetes/manifests/kube-controller-manager.yaml
# Should be: --kubeconfig=/etc/kubernetes/controller-manager.conf

# Verify the file exists
sudo ls -la /etc/kubernetes/controller-manager.conf

# If missing, regenerate:
sudo kubeadm init phase kubeconfig controller-manager
```

**Scenario: Service account signing key mismatch**

```
E0115 15:00:00.123456  1 token_generator.go:89] error validating token:
crypto/rsa: verification error
```

**Fix:** Ensure `--service-account-private-key-file` in controller-manager matches `--service-account-key-file` in kube-apiserver (they should reference `sa.key` and `sa.pub` respectively from the same key pair).

**Verification:**

```bash
sudo crictl ps | grep controller-manager
kubectl get pods -n kube-system | grep controller-manager
kubectl logs -n kube-system kube-controller-manager-<node> | tail -20
```

---

## 6. kube-scheduler

### Purpose & Responsibilities

The scheduler watches for newly created pods that have no node assigned, then selects a node for them to run on based on resource requirements, affinity/anti-affinity rules, taints/tolerations, PriorityClass, and node conditions. Without the scheduler, new pods stay in `Pending` state indefinitely.

### Configuration

**Static pod manifest:** `/etc/kubernetes/manifests/kube-scheduler.yaml`

**Key flags:**

| Flag | Purpose |
|---|---|
| `--kubeconfig` | Kubeconfig for API server auth (usually `/etc/kubernetes/scheduler.conf`) |
| `--leader-elect` | Enable leader election (default: true) |
| `--bind-address` | Address to listen on for health/metrics |

### Common Failure Scenarios

**Scenario: Wrong kubeconfig or missing scheduler.conf**

```
E0115 16:00:00.123456  1 leaderelection.go:330] error retrieving resource lock:
Get "https://192.168.1.10:6443/apis/coordination.k8s.io/v1/namespaces/kube-system/leases/kube-scheduler":
dial tcp 192.168.1.10:6443: connect: connection refused
stat /etc/kubernetes/scheduler.conf: no such file or directory
```

**Diagnosis and Fix:**

```bash
# Check the manifest
sudo grep kubeconfig /etc/kubernetes/manifests/kube-scheduler.yaml

# Verify the file
sudo ls -la /etc/kubernetes/scheduler.conf

# Regenerate if missing
sudo kubeadm init phase kubeconfig scheduler
```

**Scenario: Scheduler is down — pods stuck Pending**

```bash
# Symptoms
kubectl get pods -A | grep Pending
kubectl describe pod <pending-pod> -n <ns>
# Events show: "0/3 nodes are available: ... no schedulable nodes"
# OR simply no scheduling events at all (scheduler not running)
```

**Diagnosis:**

```bash
sudo crictl ps -a | grep scheduler
sudo crictl logs $(sudo crictl ps -a | grep scheduler | head -1 | awk '{print $1}')
```

**Verification after fix:**

```bash
sudo crictl ps | grep scheduler
kubectl get pods -A | grep Pending
# Pending pods should start transitioning to ContainerCreating → Running
```

---

## 7. kubelet

### Purpose & Responsibilities

The kubelet is the primary node agent. It registers the node with the API server, receives pod assignments from the scheduler (via the API server), manages the container lifecycle through the container runtime (containerd), reports node status and pod status back to the API server, runs liveness, readiness, and startup probes, manages volumes and mounts for pods, and runs static pods from the manifest directory.

**The kubelet is the only component that runs as a systemd service (not a container).** This is critical — it's what bootstraps everything else. If the kubelet is down, the entire node is dead.

### Configuration

**Systemd service file:** `/etc/systemd/system/kubelet.service.d/10-kubeadm.conf`

```ini
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS
```

**Main config file:** `/var/lib/kubelet/config.yaml`

Key settings in config.yaml:

```yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
staticPodPath: /etc/kubernetes/manifests    # Where static pod manifests live
cgroupDriver: systemd                       # Must match containerd
containerRuntimeEndpoint: unix:///run/containerd/containerd.sock
clusterDNS:
- 10.96.0.10
clusterDomain: cluster.local
```

**Additional args:** `/var/lib/kubelet/kubeadm-flags.env`

### Interactions

```
systemd → starts kubelet
kubelet → starts containerd containers (including static pods)
kubelet → registers node with kube-apiserver
kubelet → reports node/pod status to kube-apiserver
kubelet → receives pod specs from kube-apiserver
kubelet → manages volumes, probes, container lifecycle
```

### Failure Scenario 1: Unable to Register Node

**Sample log:**

```
E0115 10:00:00.123456 kubelet_node_status.go:92] Unable to register node
"worker-01" with API server: Post "https://192.168.1.10:6443/api/v1/nodes":
dial tcp 192.168.1.10:6443: connect: connection refused
E0115 10:00:01.234567 kubelet.go:2394] node "worker-01" not found
```

**Root Cause:** The kubelet cannot reach the API server — either the API server is down, the kubeconfig has the wrong server URL, or there's a network/firewall issue.

**Diagnosis:**

```bash
# Check kubelet status
sudo systemctl status kubelet
sudo journalctl -u kubelet --no-pager | tail -30

# Check what API server URL the kubelet is using
sudo grep server /etc/kubernetes/kubelet.conf

# Test connectivity to the API server
curl -sk https://<api-server-ip>:6443/healthz

# Check firewall
sudo iptables -L -n | grep 6443
```

**Fix:**

```bash
# If the API server IP changed (e.g., after migration):
sudo vi /etc/kubernetes/kubelet.conf
# Update the server: URL

sudo systemctl restart kubelet
```

### Failure Scenario 2: cgroup Driver Mismatch

**Sample log:**

```
E0115 11:00:00.123456 kubelet.go:1445] "Failed to start ContainerManager" err=
"failed to initialize top level QOS containers: root container [kubelet] doesn't exist"
F0115 11:00:00.234567 server.go:302] failed to run Kubelet:
misconfiguration: kubelet cgroup driver: "cgroupfs" is different from
docker/containerd cgroup driver: "systemd"
```

**Root Cause:** The kubelet's cgroup driver doesn't match the container runtime's cgroup driver. Modern setups should use `systemd` for both.

**Diagnosis:**

```bash
# Check kubelet's cgroup driver
sudo grep cgroupDriver /var/lib/kubelet/config.yaml

# Check containerd's cgroup driver
sudo grep SystemdCgroup /etc/containerd/config.toml
```

**Fix:**

```bash
# Option A: Fix kubelet to use systemd (recommended)
sudo vi /var/lib/kubelet/config.yaml
# Set: cgroupDriver: systemd

# Option B: Fix containerd to match kubelet
sudo vi /etc/containerd/config.toml
# Under [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
# Set: SystemdCgroup = true

# Restart the changed component
sudo systemctl daemon-reload
sudo systemctl restart kubelet
# OR
sudo systemctl restart containerd
```

### Failure Scenario 3: Container Runtime Not Reachable

**Sample log:**

```
E0115 12:00:00.123456 remote_runtime.go:616] "Status from runtime service failed"
err="rpc error: code = Unavailable desc = connection error:
desc = \"transport: Error while dialing: dial unix /run/containerd/containerd.sock:
connect: no such file or directory\""
E0115 12:00:01.234567 kubelet.go:1445] "Failed to start ContainerManager"
err="container runtime is not running"
```

**Root Cause:** containerd is not running or the socket path is wrong.

**Diagnosis:**

```bash
sudo systemctl status containerd
sudo ls -la /run/containerd/containerd.sock
sudo grep containerRuntimeEndpoint /var/lib/kubelet/config.yaml
```

**Fix:**

```bash
# Start containerd if it's stopped
sudo systemctl start containerd
sudo systemctl enable containerd

# If the socket path is wrong in kubelet config:
sudo vi /var/lib/kubelet/config.yaml
# Set: containerRuntimeEndpoint: unix:///run/containerd/containerd.sock

sudo systemctl restart kubelet
```

### Failure Scenario 4: Certificate Rotation Failures

**Sample log:**

```
E0115 13:00:00.123456 certificate_manager.go:437] kubelet certificate rotation:
error reading certificate: no certificates found
E0115 13:00:00.234567 server.go:302] failed to run Kubelet:
unable to load client CA file /etc/kubernetes/pki/ca.crt:
open /etc/kubernetes/pki/ca.crt: no such file or directory
```

**Diagnosis:**

```bash
# Check kubelet certs
sudo ls -la /var/lib/kubelet/pki/
sudo openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -noout -dates

# Check CA cert
sudo ls -la /etc/kubernetes/pki/ca.crt
```

**Fix:**

```bash
# If kubelet client cert is expired:
# On the control plane, approve the CSR:
kubectl get csr
kubectl certificate approve <csr-name>

# If CA cert is missing from worker node, copy it from control plane:
# On control plane: cat /etc/kubernetes/pki/ca.crt
# On worker: paste to /etc/kubernetes/pki/ca.crt

sudo systemctl restart kubelet
```

### Failure Scenario 5: Config File Missing or Corrupted

**Sample log:**

```
F0115 14:00:00.123456 server.go:199] failed to load kubelet config file,
error: failed to load Kubelet config file /var/lib/kubelet/config.yaml,
error: open /var/lib/kubelet/config.yaml: no such file or directory
```

**Diagnosis:**

```bash
sudo ls -la /var/lib/kubelet/config.yaml
sudo cat /var/lib/kubelet/config.yaml
```

**Fix:**

```bash
# If the file was accidentally deleted or renamed, check if it was renamed:
sudo ls -la /var/lib/kubelet/

# Regenerate kubelet config from kubeadm:
sudo kubeadm init phase kubelet-start     # on control plane node
# OR for a worker node, re-join:
# sudo kubeadm join <api-server>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
```

**General kubelet restart procedure:**

```bash
sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo systemctl status kubelet
# If it keeps crashing, check the journal:
sudo journalctl -u kubelet -f
```

---

## 8. containerd

### Purpose & Responsibilities

containerd is the container runtime that actually runs containers. It pulls images, creates containers, manages container lifecycle, and provides the CRI (Container Runtime Interface) socket that kubelet communicates through. Without containerd, no containers can start — not even the control plane static pods.

### Configuration

**Systemd service:** `containerd.service`

**Config file:** `/etc/containerd/config.toml`

**Critical section in config.toml:**

```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  SystemdCgroup = true    # Must be true for Kubernetes
```

**CRI socket:** `/run/containerd/containerd.sock`

**crictl config:** `/etc/crictl.yaml`

```yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
```

### Interactions

```
kubelet ──(CRI gRPC)──► containerd ──► runc ──► Linux containers
                              │
                              └──► image pulls from registries
```

### Failure Scenario 1: Socket Unavailable

**Sample log (from kubelet):**

```
E0115 10:00:00.123456 remote_runtime.go:189] "RunPodSandbox from runtime
service failed" err="rpc error: code = Unavailable desc = connection error:
desc = \"transport: Error while dialing: dial unix /run/containerd/containerd.sock:
connect: connection refused\""
```

**Diagnosis:**

```bash
sudo systemctl status containerd
sudo journalctl -u containerd --no-pager | tail -30
sudo ls -la /run/containerd/containerd.sock
```

**Fix:**

```bash
sudo systemctl restart containerd
# If containerd won't start:
sudo journalctl -u containerd -f
# Common: corrupted config
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
```

### Failure Scenario 2: Shim Failures

**Sample log:**

```
E0115 11:00:00.123456 shim.go:295] "Failed to start shim"
containerd-shim-runc-v2: exit status 128
E0115 11:00:00.345678 "RunPodSandbox from runtime service failed" err=
"failed to start sandbox container: containerd-shim-runc-v2 not installed on system"
```

**Root Cause:** The `containerd-shim-runc-v2` binary or `runc` is missing or corrupted.

**Diagnosis:**

```bash
which containerd-shim-runc-v2
which runc
runc --version
containerd-shim-runc-v2 --version
```

**Fix:**

```bash
# Reinstall containerd (includes shim)
sudo apt-get install --reinstall containerd.io
# OR install runc separately
# Download runc from https://github.com/opencontainers/runc/releases
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
```

### Failure Scenario 3: Image Pull Errors

**Sample log (from `kubectl describe pod` or `crictl logs`):**

```
Failed to pull image "nginx:latest": rpc error: code = NotFound desc = failed to pull
and unpack image: failed to resolve reference "docker.io/library/nginx:latest":
pull access denied, repository does not exist or may require authentication

Back-off pulling image "myregistry.com/app:v1"
```

**Root Cause:** Image doesn't exist, registry auth is missing, or network connectivity issues.

**Diagnosis:**

```bash
# Test pulling manually
sudo crictl pull nginx:latest

# Check registry auth config
sudo cat /etc/containerd/config.toml | grep -A 5 registry

# Test DNS resolution
nslookup docker.io
```

**Fix:**

```bash
# For private registries, add auth to containerd config or use imagePullSecrets:
kubectl create secret docker-registry regcred \
  --docker-server=myregistry.com \
  --docker-username=user \
  --docker-password=pass \
  -n <namespace>
# Then add imagePullSecrets to the pod spec
```

**Verification:**

```bash
sudo systemctl status containerd
sudo crictl info
sudo crictl ps
sudo crictl images
```

---

## 9. kube-proxy

### Purpose & Responsibilities

kube-proxy maintains network rules on each node that allow network communication to pods from inside or outside the cluster. It watches the API server for Service and Endpoint changes, then updates iptables (or IPVS) rules to route traffic to the correct pod backends. Without kube-proxy, ClusterIP and NodePort services don't work.

### Configuration

**Deployment type:** DaemonSet in `kube-system` namespace

**Config:** Stored in ConfigMap `kube-proxy` in `kube-system`

```bash
kubectl get configmap kube-proxy -n kube-system -o yaml
```

**Key settings:**

| Setting | Purpose |
|---|---|
| `mode` | Proxy mode: `iptables` (default) or `ipvs` |
| `clusterCIDR` | Pod network CIDR |
| `metricsBindAddress` | Address for metrics endpoint |

### Common Failure Scenarios

**Scenario: kube-proxy pods CrashLooping**

```bash
kubectl get pods -n kube-system -l k8s-app=kube-proxy
# Shows CrashLoopBackOff or Error

kubectl logs -n kube-system <kube-proxy-pod>
```

**Sample log:**

```
E0115 10:00:00.123456 server_others.go:305] can't determine this node's IP:
node "worker-01" had condition "Ready" with status "False"
F0115 10:00:00.234567 server.go:533] unable to create proxier: can't set
sysctl net/ipv4/vs/conntrack: open /proc/sys/net/ipv4/vs/conntrack: no such file or directory
```

**Fix for IPVS mode:**

```bash
# Load required IPVS kernel modules
sudo modprobe ip_vs
sudo modprobe ip_vs_rr
sudo modprobe ip_vs_wrr
sudo modprobe ip_vs_sh
sudo modprobe nf_conntrack

# Make persistent
cat <<EOF | sudo tee /etc/modules-load.d/ipvs.conf
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF
```

**Scenario: Services not routing traffic**

```bash
# Services exist but traffic doesn't reach pods
kubectl get svc
kubectl get endpoints <service-name>
# If Endpoints is empty, the Service selector doesn't match any pods

# Check iptables rules
sudo iptables -t nat -L -n | grep <service-clusterip>
```

**Verification:**

```bash
kubectl get pods -n kube-system -l k8s-app=kube-proxy
kubectl logs -n kube-system <kube-proxy-pod> | tail -20
# Test service connectivity
kubectl run test-curl --image=curlimages/curl --rm -it -- curl http://<service-name>.<namespace>.svc.cluster.local
```

---

## 10. CNI Plugins

### Purpose & Responsibilities

CNI (Container Network Interface) plugins are responsible for assigning IP addresses to pods, setting up network interfaces inside pod namespaces, programming routes so pods can communicate across nodes, and enforcing NetworkPolicies (if supported by the plugin). Without a functioning CNI, pods get stuck in `ContainerCreating` and never receive an IP address.

### Configuration

**CNI binaries:** `/opt/cni/bin/`

**CNI config:** `/etc/cni/net.d/`

```bash
ls /opt/cni/bin/
# bridge, host-local, loopback, portmap, calico, calico-ipam, flannel, etc.

ls /etc/cni/net.d/
# 10-calico.conflist, or 10-flannel.conflist, etc.
```

### Interactions

```
kubelet ──(CNI calls)──► CNI binary ──► creates veth pairs, assigns IPs
                              │
                              └──► CNI config in /etc/cni/net.d/ determines plugin
```

### Failure Scenario 1: Pod Stuck in ContainerCreating

**Sample events (from `kubectl describe pod`):**

```
Warning  FailedCreatePodSandBox  kubelet  Failed to create pod sandbox:
rpc error: code = Unknown desc = failed to setup network for sandbox
"abc123": plugin type="calico" failed (add): error getting ClusterInformation: connection refused

Warning  FailedCreatePodSandBox  kubelet  Failed to create pod sandbox:
rpc error: code = Unknown desc = [failed to set up sandbox container network interface:
networkPlugin cni failed to set up pod network: CNI plugin not initialized]
```

**Root Cause:** CNI plugin is not installed, CNI binary is missing, or the CNI configuration is invalid.

**Diagnosis:**

```bash
# Check if CNI config exists
ls /etc/cni/net.d/

# Check if CNI binaries exist
ls /opt/cni/bin/

# Check CNI pod status (e.g., Calico)
kubectl get pods -n calico-system    # or kube-system, depending on install method
kubectl get pods -n kube-flannel     # for Flannel

# Check kubelet logs for CNI errors
journalctl -u kubelet | grep -i cni | tail -20
```

**Fix:**

```bash
# If CNI was never installed:
# For Calico:
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml

# For Flannel:
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# If binaries are missing, reinstall CNI plugins:
# Download from https://github.com/containernetworking/plugins/releases
sudo tar -xzf cni-plugins-linux-amd64-v1.4.0.tgz -C /opt/cni/bin/
```

### Failure Scenario 2: IP Allocation Failures

**Sample log:**

```
E0115 14:00:00.123456 ipam.go:303] "Failed to allocate IP" pod="default/nginx-abc123"
error="no available IPs in the subnet 10.244.0.0/24"
IPAM: no IPs available in range set: 10.244.0.0/24
```

**Root Cause:** The pod CIDR is exhausted — too many pods for the subnet size.

**Diagnosis:**

```bash
# Check how many pods are running on the node
kubectl get pods -A -o wide | grep <node-name> | wc -l

# Check the pod CIDR allocated to the node
kubectl get node <node-name> -o jsonpath='{.spec.podCIDR}'
# A /24 subnet = 254 usable IPs

# For Calico, check IP pools:
kubectl get ippools -o yaml
```

**Fix:**

```bash
# Clean up completed/failed pods to free IPs
kubectl delete pods --field-selector=status.phase=Failed -A
kubectl delete pods --field-selector=status.phase=Succeeded -A

# For Calico — adjust block size or add new IP pool:
kubectl get ippools
# Edit to expand CIDR or adjust blockSize
```

### Failure Scenario 3: Pod-to-Pod Communication Failure (Across Nodes)

**Diagnosis:**

```bash
# Deploy test pods on different nodes
kubectl run test1 --image=nginx --overrides='{"spec":{"nodeName":"node1"}}'
kubectl run test2 --image=busybox --overrides='{"spec":{"nodeName":"node2"}}' -- sleep 3600

# Get test1's IP
kubectl get pod test1 -o wide
# Try to curl from test2
kubectl exec test2 -- wget -qO- http://<test1-ip>

# Check routes on the node
ip route | grep <pod-cidr>

# Check if overlay network is functioning
# For VXLAN (Calico/Flannel):
ip -d link show vxlan.calico    # or flannel.1
```

**Common fixes:** Ensure `br_netfilter` module is loaded and `net.bridge.bridge-nf-call-iptables = 1` is set. Verify firewall allows VXLAN (UDP 4789) or IP-in-IP (protocol 4) between nodes. Check that the pod CIDR in the CNI config matches what was used during `kubeadm init`.

---

## 11. Command Cheat Sheets

### Cluster Health Checks

```bash
# Overall cluster info
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A -o wide

# Component status (legacy but useful)
kubectl get componentstatuses

# API server health
curl -sk https://localhost:6443/healthz
curl -sk https://localhost:6443/livez
curl -sk https://localhost:6443/readyz

# etcd health
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  endpoint health

# Node conditions
kubectl describe node <node> | grep -A 10 "Conditions"
```

### Control Plane Diagnostics

```bash
# Static pod manifests
ls -la /etc/kubernetes/manifests/

# Control plane container status
sudo crictl ps -a | grep -E "apiserver|etcd|scheduler|controller"

# Container logs
sudo crictl logs <container-id>
sudo crictl logs --tail 100 <container-id>

# Inspect a container
sudo crictl inspect <container-id>

# Pod-level info
sudo crictl pods

# kubelet logs
sudo journalctl -u kubelet --no-pager | tail -100
sudo journalctl -u kubelet -f   # follow

# Certificate status
sudo kubeadm certs check-expiration
```

### Runtime Debugging

```bash
# containerd status
sudo systemctl status containerd
sudo journalctl -u containerd --no-pager | tail -50

# crictl operations
sudo crictl info                    # Runtime info
sudo crictl version                 # Version
sudo crictl ps -a                   # All containers
sudo crictl images                  # All images
sudo crictl pull <image>            # Pull image
sudo crictl rmi <image-id>          # Remove image
sudo crictl stats                   # Container resource usage
sudo crictl exec -it <cid> sh      # Exec into container

# Check runtime socket
ls -la /run/containerd/containerd.sock
```

### Network Troubleshooting

```bash
# CNI config and binaries
ls /etc/cni/net.d/
ls /opt/cni/bin/

# Pod IPs and node assignment
kubectl get pods -A -o wide

# Service endpoints
kubectl get endpoints -A
kubectl get svc -A

# DNS test
kubectl run dnstest --image=busybox:1.36 --rm -it -- nslookup kubernetes.default
kubectl run dnstest --image=busybox:1.36 --rm -it -- nslookup <service>.<namespace>.svc.cluster.local

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# iptables rules (service routing)
sudo iptables -t nat -L -n | grep <service-clusterip>
sudo iptables -t nat -L KUBE-SERVICES -n

# kube-proxy logs
kubectl logs -n kube-system -l k8s-app=kube-proxy | tail -20

# Node network interfaces
ip addr show
ip route
ip link show
```

### Certificate Validation

```bash
# Check all kubeadm-managed cert expiry dates
sudo kubeadm certs check-expiration

# Inspect a specific certificate
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text

# Check expiry
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates

# Check SANs (Subject Alternative Names)
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text | grep -A 1 "Subject Alternative Name"

# Verify cert/key pair match
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -modulus | md5sum
sudo openssl rsa -in /etc/kubernetes/pki/apiserver.key -noout -modulus | md5sum

# Renew all certs
sudo kubeadm certs renew all

# Renew specific cert
sudo kubeadm certs renew apiserver
sudo kubeadm certs renew apiserver-kubelet-client
sudo kubeadm certs renew front-proxy-client

# Regenerate a cert from scratch
sudo rm /etc/kubernetes/pki/apiserver.crt /etc/kubernetes/pki/apiserver.key
sudo kubeadm init phase certs apiserver
```

---

## 12. Cluster Health Verification Checklist

Use this checklist after any repair to confirm the cluster is fully healthy:

### Control Plane

```bash
# 1. All control plane pods Running
kubectl get pods -n kube-system | grep -E "apiserver|etcd|scheduler|controller-manager"
# Expected: all 1/1 Running, 0 restarts (or low restart count)

# 2. API server responding
curl -sk https://localhost:6443/healthz
# Expected: ok

# 3. etcd healthy
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  endpoint health
# Expected: 127.0.0.1:2379 is healthy
```

### Nodes

```bash
# 4. All nodes Ready
kubectl get nodes
# Expected: all nodes show STATUS=Ready

# 5. kubelet running on all nodes
# On each node:
sudo systemctl status kubelet
# Expected: active (running)

# 6. containerd running on all nodes
sudo systemctl status containerd
# Expected: active (running)
```

### Networking

```bash
# 7. CNI functional — pods get IPs
kubectl run net-test --image=nginx --restart=Never
kubectl get pod net-test -o wide
# Expected: pod has an IP in the pod CIDR range

# 8. DNS working
kubectl run dns-test --image=busybox:1.36 --rm -it -- nslookup kubernetes.default
# Expected: resolves to the kubernetes ClusterIP (usually 10.96.0.1)

# 9. CoreDNS pods running
kubectl get pods -n kube-system -l k8s-app=kube-dns
# Expected: 2/2 Running (usually 2 replicas)

# 10. kube-proxy running
kubectl get pods -n kube-system -l k8s-app=kube-proxy
# Expected: one pod per node, all Running

# 11. Service routing works
kubectl expose pod net-test --port=80 --name=net-test-svc
kubectl run curl-test --image=curlimages/curl --rm -it -- curl http://net-test-svc.default.svc.cluster.local
# Expected: returns nginx welcome page
```

### Scheduling

```bash
# 12. Pod scheduling works
kubectl run sched-test --image=nginx --restart=Never
kubectl get pod sched-test
# Expected: quickly transitions from Pending → ContainerCreating → Running

# Clean up test resources
kubectl delete pod net-test sched-test --force --grace-period=0
kubectl delete svc net-test-svc
```

### Certificates

```bash
# 13. No certificates expiring soon
sudo kubeadm certs check-expiration
# Expected: all certs have >30 days remaining
```

### Summary Pass/Fail Table

| Check | Command | Expected |
|---|---|---|
| API server health | `curl -sk https://localhost:6443/healthz` | `ok` |
| etcd health | `etcdctl endpoint health` | `is healthy` |
| All nodes Ready | `kubectl get nodes` | All `Ready` |
| Control plane pods | `kubectl get pods -n kube-system` | All `Running` |
| CNI working | Run test pod, check IP | Pod gets IP |
| DNS working | `nslookup kubernetes.default` | Resolves |
| Scheduling | Run test pod | `Running` within 30s |
| Certs valid | `kubeadm certs check-expiration` | Not expired |

---

## 13. Documentation References

### Kubernetes Official Docs

- [Cluster Architecture](https://kubernetes.io/docs/concepts/architecture/)
- [Container Runtimes](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
- [kubeadm Reference](https://kubernetes.io/docs/reference/setup-tools/kubeadm/)
- [Troubleshooting Clusters](https://kubernetes.io/docs/tasks/debug/debug-cluster/)
- [Troubleshooting Applications](https://kubernetes.io/docs/tasks/debug/debug-application/)
- [PKI Certificates and Requirements](https://kubernetes.io/docs/setup/best-practices/certificates/)
- [kubelet Configuration](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/)
- [kube-apiserver Reference](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/)
- [Static Pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
- [Network Plugins](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)
- [Cluster Networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
- [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Managing TLS in a Cluster](https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/)

### etcd Documentation

- [etcd Official Docs](https://etcd.io/docs/)
- [etcd Operations Guide](https://etcd.io/docs/v3.5/op-guide/)
- [etcd Disaster Recovery](https://etcd.io/docs/v3.5/op-guide/recovery/)
- [etcd Performance](https://etcd.io/docs/v3.5/op-guide/performance/)

### containerd Documentation

- [containerd Getting Started](https://github.com/containerd/containerd/blob/main/docs/getting-started.md)
- [containerd CRI Plugin Configuration](https://github.com/containerd/containerd/blob/main/docs/cri/config.md)
- [crictl User Guide](https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/crictl.md)

### CNI Documentation

- [CNI Specification](https://www.cni.dev/docs/spec/)
- [Calico Documentation](https://docs.tigera.io/calico/latest/about/)
- [Flannel Documentation](https://github.com/flannel-io/flannel#readme)

---

*This guide covers the full diagnostic and repair lifecycle for every major Kubernetes cluster component. For CKA exam prep, focus on the troubleshooting methodology (Section 2), kubelet/apiserver failures (Sections 3 & 7), and the verification checklist (Section 12). For production SRE work, bookmark the etcd backup/restore procedures (Section 4) and certificate management commands (Section 11).*
