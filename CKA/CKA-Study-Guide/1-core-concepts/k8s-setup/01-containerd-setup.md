# Containerd Installation & Setup

> **Reference**: This guide follows the official Kubernetes documentation for setting up containerd as a container runtime before deploying a Kubernetes cluster.

## 📚 Official Documentation Links

- [Container Runtimes](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
- [Getting Started with containerd](https://github.com/containerd/containerd/blob/main/docs/getting-started.md)
- [CRI (Container Runtime Interface)](https://kubernetes.io/docs/concepts/architecture/cri/)
- [Cgroup v2](https://kubernetes.io/docs/concepts/architecture/cgroups/)

---

## 1. Prerequisites

### 1.1 Enable IPv4 Packet Forwarding

The Linux kernel does not allow IPv4 packet forwarding by default. Kubernetes networking requires this to be enabled.

```bash
# Load required kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
```

```bash
# Set required sysctl params (persist across reboots)
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
```

### 1.2 Verify Settings

```bash
# Verify that net.ipv4.ip_forward is set to 1
sysctl net.ipv4.ip_forward

# Verify kernel modules are loaded
lsmod | grep br_netfilter
lsmod | grep overlay
```

---

## 2. Install containerd

### 2.1 Option A — Install from Official Binaries (Recommended)

Follow the [containerd getting-started guide](https://github.com/containerd/containerd/blob/main/docs/getting-started.md) to download and install containerd, runc, and CNI plugins.

### 2.2 Option B — Install from Package Manager (Debian/Ubuntu)

```bash
# Update package index
sudo apt-get update

# Install containerd
sudo apt-get install -y containerd
```

### 2.3 Option C — Install from Package Manager (RHEL/CentOS)

```bash
# Install containerd
sudo yum install -y containerd
```

---

## 3. Configure containerd

### 3.1 Generate Default Config

```bash
# Create config directory
sudo mkdir -p /etc/containerd

# Generate default configuration
containerd config default | sudo tee /etc/containerd/config.toml
```

### 3.2 Configure systemd Cgroup Driver

> **Important**: If your Linux distribution uses **systemd** as the init system (most modern distros do), you **must** configure containerd to use the `systemd` cgroup driver. Both the kubelet and the container runtime must use the **same** cgroup driver.

Edit `/etc/containerd/config.toml`:

**For containerd 1.x:**

```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  ...
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
```

**For containerd 2.x:**

```toml
[plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc]
  ...
  [plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc.options]
    SystemdCgroup = true
```

### 3.3 Ensure CRI Plugin Is NOT Disabled

If containerd was installed from a package (RPM or `.deb`), the CRI integration plugin may be disabled by default. Make sure `cri` is **not** in the `disabled_plugins` list in `/etc/containerd/config.toml`:

```toml
# Ensure this line does NOT contain "cri"
disabled_plugins = []
```

### 3.4 Overriding the Sandbox (Pause) Image (Optional)

```toml
[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "registry.k8s.io/pause:3.10"
```

---

## 4. Start and Enable containerd

```bash
# Restart containerd to apply config changes
sudo systemctl restart containerd

# Enable containerd to start on boot
sudo systemctl enable containerd

# Verify containerd is running
sudo systemctl status containerd
```

---

## 5. Verify Installation

```bash
# Check containerd version
containerd --version

# Check that containerd CRI socket is available
ls -la /run/containerd/containerd.sock

# Test with crictl (if installed)
sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock info
```

---

## 6. Key Paths & Defaults

| Item                 | Path                                         |
| -------------------- | -------------------------------------------- |
| containerd config    | `/etc/containerd/config.toml`                |
| CRI socket (Linux)   | `/run/containerd/containerd.sock`            |
| CRI socket (Windows) | `npipe://./pipe/containerd-containerd`       |
| Data directory       | `/var/lib/containerd`                        |
| Systemd unit         | `/usr/lib/systemd/system/containerd.service` |

---

## 7. Understanding Cgroup Drivers

| Driver     | When to Use                                                                         |
| ---------- | ----------------------------------------------------------------------------------- |
| `systemd`  | **Recommended** — when systemd is the init system (most modern Linux distributions) |
| `cgroupfs` | Only when systemd is **not** the init system                                        |

> **⚠️ Warning**: It is critical that both the kubelet and the container runtime use the **same** cgroup driver. Mismatched cgroup drivers will cause the kubelet to fail.

### Setting cgroup driver in KubeletConfiguration

```yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
...
cgroupDriver: systemd
```

---

## 8. Troubleshooting

| Issue                                       | Solution                                                                                                                                                         |
| ------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Container crash loops after cluster install | Reset containerd config: `containerd config default > /etc/containerd/config.toml`, reconfigure `SystemdCgroup = true`, then `sudo systemctl restart containerd` |
| CRI plugin disabled error                   | Remove `cri` from `disabled_plugins` in config.toml                                                                                                              |
| containerd not starting                     | Check logs: `journalctl -u containerd -f`                                                                                                                        |
| IPv4 forwarding not enabled                 | Run `sysctl net.ipv4.ip_forward` — must return `1`                                                                                                               |
