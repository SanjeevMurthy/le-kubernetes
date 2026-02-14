# Kubelet & Etcd — Setup, Configuration & Important Commands

> **Reference**: This guide covers kubelet and etcd setup, their configuration file locations, and essential commands for administration and CKA exam preparation.

## 📚 Official Documentation Links

- [Kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/)
- [Kubelet Configuration (v1beta1)](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/)
- [Configuring the kubelet cgroup driver](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/configure-cgroup-driver/)
- [Operating etcd Clusters for Kubernetes](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)
- [etcd Official Documentation](https://etcd.io/docs/)
- [etcd Disaster Recovery](https://etcd.io/docs/current/op-guide/recovery/)

---

# Part 1: Kubelet

## 1. What is Kubelet?

The **kubelet** is the primary node agent that runs on every node in the cluster. It ensures that containers described in PodSpecs are running and healthy.

**Key responsibilities:**

- Registers the node with the API server
- Watches for Pod assignments from the API server
- Mounts volumes, downloads secrets
- Starts and monitors containers via the container runtime (CRI)
- Reports node and pod status back to the API server

---

## 2. Kubelet Configuration File Locations

| Item                           | Location                                                    |
| ------------------------------ | ----------------------------------------------------------- |
| Kubelet service file           | `/usr/lib/systemd/system/kubelet.service`                   |
| Kubelet drop-in config         | `/usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf` |
| Kubelet config file            | `/var/lib/kubelet/config.yaml`                              |
| Kubelet kubeconfig             | `/etc/kubernetes/kubelet.conf`                              |
| Kubelet environment args       | `/var/lib/kubelet/kubeadm-flags.env`                        |
| Static pod manifests directory | `/etc/kubernetes/manifests/`                                |
| Kubelet PKI directory          | `/var/lib/kubelet/pki/`                                     |
| Kubelet data directory         | `/var/lib/kubelet/`                                         |

---

## 3. Kubelet Configuration (`/var/lib/kubelet/config.yaml`)

Example key settings:

```yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
clusterDNS:
  - 10.96.0.10
clusterDomain: cluster.local
resolvConf: /run/systemd/resolve/resolv.conf
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
authorization:
  mode: Webhook
staticPodPath: /etc/kubernetes/manifests
```

---

## 4. Important Kubelet Commands

### Service Management

```bash
# Check kubelet status
sudo systemctl status kubelet

# Start kubelet
sudo systemctl start kubelet

# Stop kubelet
sudo systemctl stop kubelet

# Restart kubelet
sudo systemctl restart kubelet

# Enable kubelet to start on boot
sudo systemctl enable kubelet

# View kubelet logs
journalctl -u kubelet -f

# View kubelet logs (last 100 lines)
journalctl -u kubelet --no-pager -n 100
```

### Kubelet Diagnostics

```bash
# Check kubelet version
kubelet --version

# View current kubelet configuration
kubectl get configmap kubelet-config -n kube-system -o yaml

# Check node conditions
kubectl describe node <node-name> | grep -A 20 "Conditions"

# View kubelet config file
cat /var/lib/kubelet/config.yaml

# View kubelet args
cat /var/lib/kubelet/kubeadm-flags.env
```

---

## 5. Static Pods

Kubelet manages **static pods** directly from manifests in `/etc/kubernetes/manifests/`. These are used for control plane components.

```bash
# List static pod manifests
ls -la /etc/kubernetes/manifests/

# Typical static pods on a control plane node:
# - etcd.yaml
# - kube-apiserver.yaml
# - kube-controller-manager.yaml
# - kube-scheduler.yaml
```

To create a static pod:

```bash
# Place a pod manifest in the static pod directory
sudo cp my-pod.yaml /etc/kubernetes/manifests/

# Kubelet will automatically create the pod

# To delete — remove the manifest
sudo rm /etc/kubernetes/manifests/my-pod.yaml
```

---

## 6. Kubelet Troubleshooting

| Issue                | Command                                              |
| -------------------- | ---------------------------------------------------- |
| Kubelet not starting | `journalctl -u kubelet -f`                           |
| Check kubelet config | `cat /var/lib/kubelet/config.yaml`                   |
| Node NotReady        | `kubectl describe node <node-name>`                  |
| Certificate issues   | `ls -la /var/lib/kubelet/pki/`                       |
| CRI socket issues    | Check `--container-runtime-endpoint` in kubelet args |

---

# Part 2: Etcd

## 7. What is Etcd?

**etcd** is a consistent, highly-available key-value store used as Kubernetes' backing store for **all cluster data**. It stores the cluster state, configurations, secrets, and metadata.

---

## 8. Etcd Configuration & File Locations

| Item                        | Location                              |
| --------------------------- | ------------------------------------- |
| Etcd static pod manifest    | `/etc/kubernetes/manifests/etcd.yaml` |
| Etcd data directory         | `/var/lib/etcd`                       |
| Etcd certificates directory | `/etc/kubernetes/pki/etcd/`           |
| CA certificate              | `/etc/kubernetes/pki/etcd/ca.crt`     |
| Server certificate          | `/etc/kubernetes/pki/etcd/server.crt` |
| Server key                  | `/etc/kubernetes/pki/etcd/server.key` |
| Peer certificate            | `/etc/kubernetes/pki/etcd/peer.crt`   |
| Peer key                    | `/etc/kubernetes/pki/etcd/peer.key`   |

### Etcd Pod Manifest Key Flags

You can inspect these from the etcd static pod YAML:

```bash
cat /etc/kubernetes/manifests/etcd.yaml
```

Key flags to note:

| Flag                      | Description                    |
| ------------------------- | ------------------------------ |
| `--data-dir`              | Data directory for etcd        |
| `--listen-client-urls`    | URLs the client listens on     |
| `--advertise-client-urls` | URLs advertised to the cluster |
| `--cert-file`             | Path to server certificate     |
| `--key-file`              | Path to server key             |
| `--trusted-ca-file`       | Path to trusted CA certificate |
| `--peer-cert-file`        | Path to peer certificate       |
| `--peer-key-file`         | Path to peer key               |
| `--peer-trusted-ca-file`  | Path to peer trusted CA        |
| `--initial-cluster`       | Initial cluster configuration  |

---

## 9. Etcd CLI Tools

### `etcdctl` vs `etcdutl`

| Tool      | Purpose                                                                                                                                |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `etcdctl` | Primary CLI for interacting with etcd over the network (day-to-day operations: get/put keys, manage members, snapshots, health checks) |
| `etcdutl` | Administration utility for direct etcd data file operations (defragmentation, restoring snapshots, validating consistency)             |

---

## 10. Essential etcdctl Commands

### 10.1 Set Environment Variables

```bash
# Set API version (always use v3)
export ETCDCTL_API=3
```

### 10.2 Common Connection Flags

Most `etcdctl` commands require these flags to authenticate with etcd:

```bash
# Connection with TLS certificates
etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  <command>
```

> **Tip**: You can get the certificate paths from the etcd pod manifest:
>
> ```bash
> cat /etc/kubernetes/manifests/etcd.yaml | grep -E "cert|key|ca"
> ```

### 10.3 Health & Status

```bash
# Check etcd cluster health
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# Check endpoint status (with table output)
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint status --write-out=table
```

### 10.4 Member Management

```bash
# List cluster members
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list --write-out=table

# Remove a failed member
etcdctl member remove <MEMBER_ID>

# Add a new member
etcdctl member add <NAME> --peer-urls=http://<IP>:2380
```

---

## 11. Etcd Backup & Restore (CKA Critical Topic)

### 11.1 Create a Snapshot (Backup)

```bash
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /opt/etcd-backup.db
```

### 11.2 Verify a Snapshot

**Using etcdutl (Recommended):**

```bash
etcdutl --write-out=table snapshot status /opt/etcd-backup.db
```

**Using etcdctl (Deprecated):**

```bash
ETCDCTL_API=3 etcdctl --write-out=table snapshot status /opt/etcd-backup.db
```

Expected output:

```
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| fe01cf57 |       10 |          7 |     2.1 MB |
+----------+----------+------------+------------+
```

### 11.3 Restore from Snapshot

> **⚠️ Important**: Stop **all** API server instances before restoring etcd.

**Using etcdutl (Recommended):**

```bash
etcdutl --data-dir=/var/lib/etcd-restored snapshot restore /opt/etcd-backup.db
```

**Using etcdctl (Deprecated):**

```bash
ETCDCTL_API=3 etcdctl \
  --data-dir=/var/lib/etcd-restored \
  snapshot restore /opt/etcd-backup.db
```

### 11.4 After Restoration — Update etcd to Use New Data Directory

Edit the etcd static pod manifest:

```bash
sudo vi /etc/kubernetes/manifests/etcd.yaml
```

Update the `volumes.hostPath.path` for `etcd-data`:

```yaml
volumes:
  - hostPath:
      path: /var/lib/etcd-restored # Changed from /var/lib/etcd
      type: DirectoryOrCreate
    name: etcd-data
```

Then restart:

```bash
# Option 1: Delete the etcd pod (kubelet will recreate it)
kubectl -n kube-system delete pod <etcd-pod-name>

# Option 2: Restart kubelet
sudo systemctl restart kubelet
```

---

## 12. Etcd Troubleshooting

| Issue                    | Command                                             |
| ------------------------ | --------------------------------------------------- |
| Check etcd pod status    | `kubectl get pods -n kube-system -l component=etcd` |
| View etcd logs           | `kubectl logs etcd-<node-name> -n kube-system`      |
| Or via crictl            | `sudo crictl logs <etcd-container-id>`              |
| Check etcd health        | `etcdctl endpoint health` (with cert flags)         |
| Check member list        | `etcdctl member list` (with cert flags)             |
| Inspect etcd manifest    | `cat /etc/kubernetes/manifests/etcd.yaml`           |
| Check etcd data dir size | `du -sh /var/lib/etcd`                              |

---

## 13. Quick Reference — Key File Paths

```
/etc/kubernetes/
├── admin.conf                    # Cluster admin kubeconfig
├── kubelet.conf                  # Kubelet kubeconfig
├── manifests/
│   ├── etcd.yaml                 # Etcd static pod manifest
│   ├── kube-apiserver.yaml       # API server static pod
│   ├── kube-controller-manager.yaml
│   └── kube-scheduler.yaml
└── pki/
    └── etcd/
        ├── ca.crt                # Etcd CA certificate
        ├── ca.key
        ├── server.crt            # Etcd server certificate
        ├── server.key
        ├── peer.crt              # Etcd peer certificate
        ├── peer.key
        ├── healthcheck-client.crt
        └── healthcheck-client.key

/var/lib/
├── kubelet/
│   ├── config.yaml               # Kubelet configuration
│   ├── kubeadm-flags.env         # Kubelet extra args
│   └── pki/                      # Kubelet certificates
└── etcd/                         # Etcd data directory
```
