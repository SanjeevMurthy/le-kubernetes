# CoreDNS Component Guide

**CoreDNS** is a flexible, extensible DNS server that can serve as the Kubernetes cluster DNS. It is the default DNS server for Kubernetes clusters.

Unlike the control plane components (like kube-apiserver, etcd), CoreDNS is **not** typically run as a static pod. Instead, it is deployed as a standard Kubernetes Deployment within the cluster.

## Architecture & Setup

Successfully setting up CoreDNS in a cluster involves several Kubernetes objects creating a complete working system:

1.  **Deployment (`coredns`)**:
    - Manages the CoreDNS Pods.
    - Ensures reliability and scaling (default usually has 2 replicas).
    - Located in the `kube-system` namespace.

2.  **Service (`kube-dns`)**:
    - Exposes the CoreDNS pods to the rest of the cluster.
    - The ClusterIP of this service (default is often the 10th IP in the service CIDR, e.g., `10.96.0.10`) is injected into every Pod's `/etc/resolv.conf` as the `nameserver`.

3.  **ConfigMap (`coredns`)**:
    - Contains the `Corefile`, which is the main configuration file for CoreDNS.
    - Mounted into the CoreDNS pods as a volume.

4.  **RBAC (ServiceAccount, ClusterRole, ClusterRoleBinding)**:
    - CoreDNS needs permissions to talk to the Kubernetes API to watch for new Services and Pods to update its DNS records.

## Typical Configuration (`Corefile`)

The CoreDNS configuration is stored in the `coredns` ConfigMap in the `kube-system` namespace.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
```

### Key Plugins Explained

- **`errors`**: Errors are logged to stdout.
- **`health`**: Health check endpoint (for liveness probes).
- **`ready`**: Readiness check endpoint.
- **`kubernetes`**: The core plugin that enables Kubernetes DNS resolution.
  - `cluster.local`: The domain suffix for the cluster.
  - `pods insecure`: Handling of pod records (pod-ip-address.my-namespace.pod.cluster.local).
  - `fallthrough`: If a query matches the zone but cannot be resolved, pass it to the next plugin.
- **`prometheus`**: Exposes metrics on port 9153.
- **`forward`**: Forwards queries that clearly aren't for the cluster (e.g., `google.com`) to an upstream nameserver defined in `/etc/resolv.conf` (of the node usually).
- **`cache`**: Caches DNS records for 30 seconds.
- **`loop`**: Detects simple forwarding loops and halts the server if one is found.
- **`reload`**: Automatically reloads the Corefile if the ConfigMap changes.
- **`loadbalance`**: Round-robin DNS load balancing for services with multiple endpoints.

## Troubleshooting CoreDNS

1.  **Check Pod Status**:
    Ensure CoreDNS pods are running.

    ```bash
    kubectl get pods -n kube-system -l k8s-app=kube-dns
    ```

2.  **Check Logs**:
    Look for errors in the logs, especially related to the `kubernetes` plugin or connectivity to the API server.

    ```bash
    kubectl logs -n kube-system -l k8s-app=kube-dns
    ```

3.  **Verify Service**:
    Ensure the `kube-dns` service exists and has endpoints (the IPs of the CoreDNS pods).

    ```bash
    kubectl get svc -n kube-system kube-dns
    kubectl get ep -n kube-system kube-dns
    ```

4.  **Test Resolution**:
    Launch a busybox pod and test resolution.

    ```bash
    kubectl run -it --rm --restart=Never busybox --image=busybox:1.28 -- nslookup update-service.default.svc.cluster.local
    ```

5.  **ConfigMap Errors**:
    If CoreDNS is in `CrashLoopBackOff`, it might be a syntax error in the Corefile. Validate the ConfigMap content.
