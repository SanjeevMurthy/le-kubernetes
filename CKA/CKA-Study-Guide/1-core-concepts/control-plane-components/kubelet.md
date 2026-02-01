# Kubelet Component Guide

The **kubelet** is the primary "node agent" that runs on each node. It can register the node with the apiserver using one of: the hostname; a flag to override the hostname; or specific logic for a cloud provider.

The kubelet works in terms of a **PodSpec**. A PodSpec is a YAML or JSON object that describes a pod. The kubelet takes a set of PodSpecs that are provided through various mechanisms (primarily through the apiserver) and ensures that the containers described in those PodSpecs are running and healthy.

## Service Definition

Unlike other control plane components that often run as static pods, the kubelet typically runs as a systemd service (binary) on the node.

```bash
# Check status
systemctl status kubelet
```

## Configuration Files

The kubelet relies on two main configuration files.

### 1. Kubelet Configuration (`/var/lib/kubelet/config.yaml`)

This file controls the internal parameters and behavior of the kubelet process itself.

**Key Attributes & Troubleshooting:**

- **`staticPodPath`**:

  - **Role**: Directory where static pod manifests are stored.
  - **Default**: `/etc/kubernetes/manifests`
  - **Issue**: If static pods (like api-server or etcd) aren't starting, verify this path points to the correct directory.

- **`authentication`**:

  - **Role**: Configures how the kubelet authenticates requests (e.g., from the API server).
  - **Common Config**: `anonymous: enabled: false`, `x509: clientCAFile: /etc/kubernetes/pki/ca.crt`.

- **`cgroupDriver`**:

  - **Role**: Determines how the kubelet manipulates cgroups for resources.
  - **Critical Config**: This **MUST** match the container runtime's driver.
  - **Start Error**: `failed to run Kubelet: misconfiguration: kubelet cgroup driver: "systemd" is different from docker cgroup driver: "cgroupfs"`

- **`clusterDNS`**:
  - **Role**: List of IP addresses for the cluster DNS server.
  - **Issue**: If pods cannot resolve service names, check if this IP matches the kube-dns service IP.

### 2. Kubeconfig Access (`/etc/kubernetes/kubelet.conf`)

This file defines the **identity** the kubelet uses to authenticate with the Kubernetes API server.

- **Role**: Contains the certificate and key for the `system:node:<node-name>` user.
- **Location**: Usually `/etc/kubernetes/kubelet.conf`.
- **Note on `admin.conf`**: The `admin.conf` (often in `/etc/kubernetes/admin.conf`) identifies the cluster **administrator**, not the node. While you can use `admin.conf` to debug via kubectl, the kubelet process specifically needs `kubelet.conf`.

**Tip**: If you see `401 Unauthorized` in kubelet logs when talking to the API server, the certificate in `kubelet.conf` may be expired or invalid.

## Troubleshooting Checklist

1.  **Check Service Status**:
    Is the binary running?

    ```bash
    systemctl status kubelet
    ```

2.  **Inspect Logs**:
    The most important step. Systemd logs contain the startup errors.

    ```bash
    journalctl -u kubelet -f
    ```

    _Look for: "executable not found", "failed to parse config", "address already in use"._

3.  **Validate Dependencies**:

    - Is the **Container Runtime** (containerd/docker) running? `systemctl status containerd`
    - Is **Swap** disabled? (Kubelet fails if swap is on, unless configured otherwise).

4.  **Fixing Config Issues**:
    - Edit the config: `vi /var/lib/kubelet/config.yaml`
    - **Restart is mandatory**:
      ```bash
      systemctl daemon-reload # If unit file changed
      systemctl restart kubelet
      ```

## Verification

To ensure the kubelet is healthy and functioning correctly without errors:

1.  **Node Status**:
    From the control plane (or using admin.conf):

    ```bash
    kubectl get nodes
    ```

    Status should be `Ready`. If `NotReady`, check CNI plugin or Kubelet logs.

2.  **Pod Startup**:
    Schedule a test pod to the node.
    ```bash
    kubectl run test-pod --image=nginx
    ```
    If it stays in `Pending` or `ContainerCreating` for too long, check `kubectl describe pod test-pod` and Kubelet logs.
