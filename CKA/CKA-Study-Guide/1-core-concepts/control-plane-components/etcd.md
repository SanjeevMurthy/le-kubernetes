# etcd Component Guide

**etcd** is a consistent and highly-available key value store used as Kubernetes' backing store for all cluster data.

## Typical Manifest (`/etc/kubernetes/manifests/etcd.yaml`)

In a `kubeadm` cluster, etcd runs as a static pod on the control plane.

```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/etcd.advertise-client-urls: https://192.168.1.10:2379
  creationTimestamp: null
  labels:
    component: etcd
    tier: control-plane
  name: etcd
  namespace: kube-system
spec:
  containers:
    - command:
        - etcd
        - --advertise-client-urls=https://192.168.1.10:2379
        - --cert-file=/etc/kubernetes/pki/etcd/server.crt
        - --client-cert-auth=true
        - --data-dir=/var/lib/etcd
        - --initial-advertise-peer-urls=https://192.168.1.10:2380
        - --initial-cluster=control-plane=https://192.168.1.10:2380
        - --key-file=/etc/kubernetes/pki/etcd/server.key
        - --listen-client-urls=https://127.0.0.1:2379,https://192.168.1.10:2379
        - --listen-metrics-urls=http://127.0.0.1:2381
        - --listen-peer-urls=https://192.168.1.10:2380
        - --name=control-plane
        - --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
        - --peer-client-cert-auth=true
        - --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
        - --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
        - --snapshot-count=10000
        - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
      image: registry.k8s.io/etcd:3.5.7-0
      imagePullPolicy: IfNotPresent
      livenessProbe:
        failureThreshold: 8
        httpGet:
          host: 127.0.0.1
          path: /health?exclude=Nocommit
          port: 2381
          scheme: HTTP
        initialDelaySeconds: 10
        periodSeconds: 10
        timeoutSeconds: 15
      name: etcd
      resources:
        requests:
          cpu: 100m
          memory: 100Mi
      startupProbe:
        failureThreshold: 24
        httpGet:
          host: 127.0.0.1
          path: /health?serializable=true
          port: 2381
          scheme: HTTP
        initialDelaySeconds: 10
        periodSeconds: 10
        timeoutSeconds: 15
      volumeMounts:
        - mountPath: /var/lib/etcd
          name: etcd-data
        - mountPath: /etc/kubernetes/pki/etcd
          name: etcd-certs
  hostNetwork: true
  priorityClassName: system-node-critical
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  volumes:
    - hostPath:
        path: /etc/kubernetes/pki/etcd
        type: DirectoryOrCreate
      name: etcd-certs
    - hostPath:
        path: /var/lib/etcd
        type: DirectoryOrCreate
      name: etcd-data
status: {}
```

## Key Configuration Flags

- **`--data-dir`**:

  - **Role**: Specifies the location on the node filesystem where etcd data is persisted.
  - **Typical Value**: `/var/lib/etcd`
  - **Importance**: If this directory is lost or corrupted, the cluster data is lost. This is what you backup.

- **`--listen-client-urls`** & **`--advertise-client-urls`**:

  - **Role**: Defines the URLs where etcd listens for client traffic (like requests from kube-apiserver) and what connection info it advertises.
  - **Importance**: If configured incorrectly, the API server wont be able to contact etcd, causing the whole cluster to fail. Typical port is **2379**.

- **`--listen-peer-urls`** & **`--initial-advertise-peer-urls`**:

  - **Role**: Used for communication between etcd members in a multi-node cluster.
  - **Importance**: Typical port is **2380**. Crucial for HA setups.

- **TLS Flags (`--cert-file`, `--key-file`, `--trusted-ca-file`)**:
  - **Role**: Etcd requires strictly authenticated communication.
  - **Importance**: Often the source of errors. If certificates expire or paths are wrong, etcd will fail to start or reject connections.

## Troubleshooting

1.  **Check Pod Status**:
    Since it's a static pod, use `crictl` on the node if `kubectl` is down.

    ```bash
    crictl ps | grep etcd
    ```

2.  **Inspect Logs**:

    ```bash
    kubectl logs -n kube-system etcd-control-plane
    # OR on the node:
    cd /var/log/pods/kube-system_etcd...
    ```

3.  **What to Check**:

    - **"connection refused"**: Check the `listen-client-urls`.
    - **Certificate errors**: Verify the files at `/etc/kubernetes/pki/etcd/` exist and are valid.
    - **Volume mount errors**: Ensure `/var/lib/etcd` is writable.

4.  **Snapshot & Restore**:
    If data is corrupted, you need to restore from a backup using `etcdctl`.
    ```bash
    ETCDCTL_API=3 etcdctl snapshot restore <backup-file> --data-dir /var/lib/etcd-new
    ```
