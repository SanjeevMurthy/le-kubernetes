# kube-controller-manager Component Guide

The **kube-controller-manager** is a daemon that runs the core control loops (controllers) that regulate the state of the cluster, such as the `Node Controller`, `ReplicationController`, `Deployment Controller`, etc. "Logically, each controller is a separate process, but to reduce complexity, they are all compiled into a single binary and run in a single process."

## Typical Manifest (`/etc/kubernetes/manifests/kube-controller-manager.yaml`)

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    component: kube-controller-manager
    tier: control-plane
  name: kube-controller-manager
  namespace: kube-system
spec:
  containers:
    - command:
        - kube-controller-manager
        - --allocate-node-cidrs=true
        - --authentication-kubeconfig=/etc/kubernetes/controller-manager.conf
        - --authorization-kubeconfig=/etc/kubernetes/controller-manager.conf
        - --bind-address=127.0.0.1
        - --client-ca-file=/etc/kubernetes/pki/ca.crt
        - --cluster-cidr=10.244.0.0/16
        - --cluster-name=kubernetes
        - --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt
        - --cluster-signing-key-file=/etc/kubernetes/pki/ca.key
        - --controllers=*,bootstrapsigner,tokencleaner
        - --kubeconfig=/etc/kubernetes/controller-manager.conf
        - --leader-elect=true
        - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
        - --root-ca-file=/etc/kubernetes/pki/ca.crt
        - --service-account-private-key-file=/etc/kubernetes/pki/sa.key
        - --use-service-account-credentials=true
      image: registry.k8s.io/kube-controller-manager:v1.27.0
      imagePullPolicy: IfNotPresent
      livenessProbe:
        failureThreshold: 8
        httpGet:
          host: 127.0.0.1
          path: /healthz
          port: 10257
          scheme: HTTPS
        initialDelaySeconds: 10
        periodSeconds: 10
        timeoutSeconds: 15
      name: kube-controller-manager
      resources:
        requests:
          cpu: 200m
      startupProbe:
        failureThreshold: 24
        httpGet:
          host: 127.0.0.1
          path: /healthz
          port: 10257
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
        - mountPath: /usr/libexec/kubernetes/kubelet-plugins/volume/exec
          name: flexvolume-dir
        - mountPath: /etc/kubernetes/pki
          name: k8s-certs
          readOnly: true
        - mountPath: /etc/kubernetes/controller-manager.conf
          name: kubeconfig
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
        path: /usr/libexec/kubernetes/kubelet-plugins/volume/exec
        type: DirectoryOrCreate
      name: flexvolume-dir
    - hostPath:
        path: /etc/kubernetes/pki
        type: DirectoryOrCreate
      name: k8s-certs
    - hostPath:
        path: /etc/kubernetes/controller-manager.conf
        type: FileOrCreate
      name: kubeconfig
status: {}
```

## Key Configuration Flags

- **`--cluster-cidr`**:

  - **Role**: Specifies the CIDR range for Pods in the cluster.
  - **Importance**: If using a CNI that relies on the controller manager to allocate CIDRs (via `--allocate-node-cidrs=true`), this must serve as the pool. If misconfigured, nodes might not get pod ranges, leading to networking failures for new pods.

- **`--allocate-node-cidrs`**:

  - **Role**: Tells the controller manager to be responsible for assigning Subnet CIDRs to nodes.
  - **Importance**: Must be `true` for many CNI configurations (like basic Flannel/Calico setups managed by kubeadm defaults).

- **`--controllers`**:

  - **Role**: A list of controllers to enable. `*` means "all default controllers". You can disable specific ones using `-` (e.g., `*, -deployment`).
  - **Importance**: Useful for debugging or if you want to run a custom implementation of a specific controller.

- **`--cluster-signing-cert/key-file`**:
  - **Role**: Used by the CSR (Certificate Signing Request) controller to sign certificates for new nodes or users.
  - **Importance**: If these are invalid, you cannot approve new certificates (e.g., `kubectl certificate approve`).

## Troubleshooting

1.  **Check Status**:
    Since it uses leader election, in a multi-master setup, only one instance is "active" doing the work.

    ```bash
    kubectl get events -n kube-system | grep controller-manager
    # Look for "became leader"
    ```

2.  **Inspect Logs**:
    Focus on specific controllers if you have an issue. For example, if Deployments aren't creating ReplicaSets, grep for "deployment-controller".

    ```bash
    crictl logs <container-id> | grep "deployment-controller"
    ```

3.  **What to Check**:
    - **CrashLoopBackOff**: Often due to invalid flags or missing `--kubeconfig` file.
    - **"Node NotReady"**: If nodes aren't getting CIDRs, check `--cluster-cidr` and `--allocate-node-cidrs`.
    - **CSRs not approved**: Check the `--cluster-signing-*` flags.
