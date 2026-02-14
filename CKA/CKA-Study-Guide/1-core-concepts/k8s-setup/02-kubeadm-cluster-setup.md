# Kubeadm Installation & Cluster Setup

> **Reference**: This guide follows the official Kubernetes documentation for installing kubeadm and bootstrapping a Kubernetes cluster with control plane and worker nodes.

## 📚 Official Documentation Links

- [Installing kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [Creating a Cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
- [kubeadm init Reference](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/)
- [kubeadm join Reference](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-join/)
- [Adding Linux Worker Nodes](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/adding-linux-nodes/)
- [Installing kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Required Ports and Protocols](https://kubernetes.io/docs/reference/networking/ports-and-protocols/)
- [Pod Network Add-ons](https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy)

---

## 1. Prerequisites (All Nodes)

### 1.1 System Requirements

| Requirement    | Minimum                                 |
| -------------- | --------------------------------------- |
| RAM            | 2 GB                                    |
| CPUs           | 2 (control plane)                       |
| OS             | Compatible Linux (Debian/Red Hat based) |
| Network        | Full connectivity between all nodes     |
| Hostname       | Unique per node                         |
| MAC Address    | Unique per node                         |
| `product_uuid` | Unique per node                         |

### 1.2 Verify Uniqueness

```bash
# Check MAC address
ip link

# Check product_uuid
sudo cat /sys/class/dmi/id/product_uuid
```

### 1.3 Check Required Ports

```bash
# Test if port 6443 is open (API server)
nc 127.0.0.1 6443 -zv -w 2
```

**Control Plane Ports:**

| Port Range | Purpose                 |
| ---------- | ----------------------- |
| 6443       | Kubernetes API server   |
| 2379-2380  | etcd server client API  |
| 10250      | Kubelet API             |
| 10259      | kube-scheduler          |
| 10257      | kube-controller-manager |

**Worker Node Ports:**

| Port Range  | Purpose           |
| ----------- | ----------------- |
| 10250       | Kubelet API       |
| 10256       | kube-proxy        |
| 30000-32767 | NodePort Services |

### 1.4 Disable Swap

```bash
# Disable swap temporarily
sudo swapoff -a

# Disable swap permanently (comment out swap entries)
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

### 1.5 Install Container Runtime

A container runtime (e.g., containerd) must be installed on all nodes **before** installing kubeadm.

> See [01-containerd-setup.md](./01-containerd-setup.md) for detailed containerd installation steps.

---

## 2. Install kubeadm, kubelet, and kubectl (All Nodes)

### 2.1 Debian/Ubuntu

```bash
# 1. Update apt package index and install prerequisite packages
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# 2. Download the public signing key for Kubernetes package repositories
# Create keyrings directory if it doesn't exist
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# 3. Add the Kubernetes apt repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 4. Update apt package index, install kubelet, kubeadm, kubectl, and pin their version
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# 5. (Optional) Enable kubelet service
sudo systemctl enable --now kubelet
```

> **Note**: Change `v1.32` in the URL to match the Kubernetes minor version you want to install.

### 2.2 RHEL/CentOS/Fedora

```bash
# 1. Set SELinux to permissive mode
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# 2. Add the Kubernetes yum repository
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

# 3. Install kubelet, kubeadm, and kubectl
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# 4. Enable kubelet service
sudo systemctl enable --now kubelet
```

---

## 3. Initialize Control Plane Node

### 3.1 Initialize the Cluster

```bash
# Basic initialization
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# With a control plane endpoint (recommended for HA setup)
sudo kubeadm init \
  --control-plane-endpoint=<LOAD_BALANCER_DNS_OR_IP>:6443 \
  --pod-network-cidr=10.244.0.0/16

# Specify a specific CRI socket (if multiple runtimes installed)
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --cri-socket=unix:///run/containerd/containerd.sock
```

> **Tip**: `--pod-network-cidr` depends on the CNI plugin you choose. `10.244.0.0/16` is commonly used with Flannel.

### 3.2 Configure kubectl for Regular User

After `kubeadm init` completes, set up `kubectl` access:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

For the **root** user:

```bash
export KUBECONFIG=/etc/kubernetes/admin.conf
```

### 3.3 Save the Join Command

When `kubeadm init` completes, it outputs a `kubeadm join` command. **Save this command** — it is needed to add worker nodes:

```
kubeadm join <control-plane-host>:<control-plane-port> --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

### 3.4 Regenerate Join Token (If Expired)

```bash
# Generate a new join token
kubeadm token create --print-join-command
```

---

## 4. Install Pod Network Add-on (Control Plane)

A CNI plugin **must** be installed before any pods can communicate. CoreDNS will remain in `Pending` state until a network is installed.

### 4.1 Option A — Calico

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
```

### 4.2 Option B — Flannel

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

### 4.3 Option C — Weave Net

```bash
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
```

### 4.4 Verify Pod Network

```bash
# Check that CoreDNS pods are Running
kubectl get pods --all-namespaces

# Check all nodes are Ready
kubectl get nodes
```

> **⚠️ Important**: Only one Pod network add-on can be installed per cluster. Ensure the `--pod-network-cidr` passed during `kubeadm init` matches the CNI plugin's expected CIDR.

---

## 5. Join Worker Nodes

### 5.1 Run the Join Command on Each Worker Node

On each worker node (after installing kubeadm, kubelet, kubectl, and the container runtime):

```bash
# Use the join command from kubeadm init output
sudo kubeadm join <control-plane-host>:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

### 5.2 Verify Worker Nodes (From Control Plane)

```bash
kubectl get nodes
```

Expected output:

```
NAME            STATUS   ROLES           AGE     VERSION
control-plane   Ready    control-plane   10m     v1.32.x
worker-1        Ready    <none>          2m      v1.32.x
worker-2        Ready    <none>          1m      v1.32.x
```

---

## 6. (Optional) Control Plane Node Isolation

By default, pods are **not** scheduled on control plane nodes for security. To allow scheduling on control plane nodes (e.g., single-node cluster):

```bash
# Remove the control plane taint
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

---

## 7. (Optional) Access Cluster from Remote Machine

```bash
# Copy kubeconfig from control plane node to your workstation
scp root@<control-plane-host>:/etc/kubernetes/admin.conf .

# Use it with kubectl
kubectl --kubeconfig ./admin.conf get nodes
```

---

## 8. Cluster Teardown / Reset

### 8.1 Remove a Worker Node

```bash
# On control plane: drain the node
kubectl drain <node-name> --delete-emptydir-data --force --ignore-daemonsets

# On the worker node: reset kubeadm
sudo kubeadm reset

# On control plane: delete the node
kubectl delete node <node-name>
```

### 8.2 Reset the Control Plane

```bash
# Reset kubeadm state
sudo kubeadm reset

# Clean up iptables
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X

# Reset IPVS tables (if used)
sudo ipvsadm -C
```

---

## 9. Useful kubeadm Commands

| Command                                     | Description                                 |
| ------------------------------------------- | ------------------------------------------- |
| `kubeadm init`                              | Initialize a control plane node             |
| `kubeadm join`                              | Join a node to the cluster                  |
| `kubeadm reset`                             | Revert changes made by `init` or `join`     |
| `kubeadm token create --print-join-command` | Generate a new join token with full command |
| `kubeadm token list`                        | List active bootstrap tokens                |
| `kubeadm version`                           | Print kubeadm version                       |
| `kubeadm config print init-defaults`        | Print default init configuration            |
| `kubeadm config images list`                | List required container images              |
| `kubeadm config images pull`                | Pre-pull required container images          |
| `kubeadm upgrade plan`                      | Check for available upgrades                |
| `kubeadm upgrade apply v1.32.x`             | Upgrade the cluster to specified version    |
| `kubeadm certs check-expiration`            | Check certificate expiration dates          |
| `kubeadm certs renew all`                   | Renew all certificates                      |

---

## 10. Quick Summary — Complete Cluster Setup Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     ALL NODES                                │
│  1. Disable swap                                             │
│  2. Enable IPv4 forwarding & kernel modules                  │
│  3. Install containerd (+ configure systemd cgroup driver)   │
│  4. Install kubeadm, kubelet, kubectl                        │
├─────────────────────────────────────────────────────────────┤
│                   CONTROL PLANE NODE                         │
│  5. kubeadm init --pod-network-cidr=10.244.0.0/16           │
│  6. Configure kubectl (copy admin.conf)                      │
│  7. Install CNI plugin (e.g., Calico/Flannel)               │
├─────────────────────────────────────────────────────────────┤
│                    WORKER NODES                               │
│  8. kubeadm join <control-plane>:6443 --token ... --hash ... │
└─────────────────────────────────────────────────────────────┘
```
