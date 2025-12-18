# kube-apiserver Component Guide

The **kube-apiserver** is the frontend for the Kubernetes control plane. It exposes the Kubernetes API and is the only component that communicates directly with etcd.

## Typical Manifest (`/etc/kubernetes/manifests/kube-apiserver.yaml`)

```yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 192.168.1.10
  creationTimestamp: null
  labels:
    component: kube-apiserver
    tier: control-plane
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
    - command:
        - kube-apiserver
        - --advertise-address=192.168.1.10
        - --allow-privileged=true
        - --authorization-mode=Node,RBAC
        - --client-ca-file=/etc/kubernetes/pki/ca.crt
        - --enable-admission-plugins=NodeRestriction
        - --enable-bootstrap-token-auth=true
        - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
        - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
        - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
        - --etcd-servers=https://127.0.0.1:2379
        - --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
        - --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt
        - --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key
        - --requestheader-allowed-names=front-proxy-client
        - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
        - --requestheader-extra-headers-prefix=X-Remote-Extra-
        - --requestheader-group-headers=X-Remote-Group
        - --requestheader-username-headers=X-Remote-User
        - --secure-port=6443
        - --service-account-issuer=https://kubernetes.default.svc.cluster.local
        - --service-account-key-file=/etc/kubernetes/pki/sa.pub
        - --service-account-signing-key-file=/etc/kubernetes/pki/sa.key
        - --service-cluster-ip-range=10.96.0.0/12
        - --tls-cert-file=/etc/kubernetes/pki/apiserver.crt
        - --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
      image: registry.k8s.io/kube-apiserver:v1.27.0
      imagePullPolicy: IfNotPresent
      livenessProbe:
        failureThreshold: 8
        httpGet:
          host: 192.168.1.10
          path: /livez
          port: 6443
          scheme: HTTPS
        initialDelaySeconds: 10
        periodSeconds: 10
        timeoutSeconds: 15
      name: kube-apiserver
      readinessProbe:
        failureThreshold: 3
        httpGet:
          host: 192.168.1.10
          path: /readyz
          port: 6443
          scheme: HTTPS
        periodSeconds: 1
        timeoutSeconds: 15
      resources:
        requests:
          cpu: 250m
      startupProbe:
        failureThreshold: 24
        httpGet:
          host: 192.168.1.10
          path: /livez
          port: 6443
          scheme: HTTPS
        initialDelaySeconds: 10
        periodSeconds: 10
        timeoutSeconds: 15
      volumeMounts:
        - mountPath: /etc/ssl/certs
          name: ca-certs
          readOnly: true
        - mountPath: /etc/pki
          name: etc-pki
          readOnly: true
        - mountPath: /etc/kubernetes/pki
          name: k8s-certs
          readOnly: true
  hostNetwork: true
  priorityClassName: system-node-critical
  volumes:
    - hostPath:
        path: /etc/ssl/certs
        type: DirectoryOrCreate
      name: ca-certs
    - hostPath:
        path: /etc/pki
        type: DirectoryOrCreate
      name: etc-pki
    - hostPath:
        path: /etc/kubernetes/pki
        type: DirectoryOrCreate
      name: k8s-certs
status: {}
```

## Key Configuration Flags

- **`--etcd-servers`**:

  - **Role**: Tells the API server where to find etcd.
  - **Importance**: If this is wrong, the API server will crash because it can't read/write state.

- **`--service-cluster-ip-range`**:

  - **Role**: The CIDR range from which ClusterIPs for Services are allocated (e.g., `10.96.0.0/12`).
  - **Importance**: Cannot overlap with the Pod CIDR or node network. If configured wrong, Services won't get IPs.

- **`--authorization-mode`**:

  - **Role**: Determines how requests are authorized (e.g., `Node`, `RBAC`).
  - **Importance**: Removing `RBAC` effectively breaks standard security. `Node` is required for Kubelets to report status.

- **`--enable-admission-plugins`**:

  - **Role**: List of plugins that intercept requests before persistence (e.g., `NodeRestriction`, `AlwaysPullImages`).
  - **Importance**: A typo here prevents startup.

- **`--client-ca-file`**:
  - **Role**: The CA certificate used to verify client certificates (like `kubectl` or `kubelet` certs).
  - **Importance**: If this file is missing or wrong, no one can authenticate.

## Troubleshooting

1.  **Check Liveness/Readiness**:
    The manifest defines probes on `/livez` and `/readyz`. If these fail, the kubelet restarts the container.
2.  **Inspect Logs**:
    Since `kubectl` depends on the API server, if it's down, you **must** use the node's tools.

    ```bash
    # SSH into control plane
    cd /var/log/pods/kube-system_kube-apiserver...
    # OR
    grep kube-apiserver /var/log/syslog
    ```

3.  **What to Check**:
    - **Typos**: The most common reason for failure in the CKA exam is a typo in the manifest (e.g., `--etcd-serer` vs `--etcd-server`).
    - **Certificates**: Ensure all referenced `.crt` and `.key` files exist in `/etc/kubernetes/pki`.
    - **Port Conflicts**: Ensure nothing else is bound to 6443.
