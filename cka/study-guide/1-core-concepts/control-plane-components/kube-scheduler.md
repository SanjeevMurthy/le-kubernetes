# kube-scheduler Component Guide

The **kube-scheduler** watches for newly created Pods that have no Node assigned, and selects a node for them to run on.

## Typical Manifest (`/etc/kubernetes/manifests/kube-scheduler.yaml`)

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    component: kube-scheduler
    tier: control-plane
  name: kube-scheduler
  namespace: kube-system
spec:
  containers:
    - command:
        - kube-scheduler
        - --authentication-kubeconfig=/etc/kubernetes/scheduler.conf
        - --authorization-kubeconfig=/etc/kubernetes/scheduler.conf
        - --bind-address=127.0.0.1
        - --kubeconfig=/etc/kubernetes/scheduler.conf
        - --leader-elect=true
      image: registry.k8s.io/kube-scheduler:v1.27.0
      imagePullPolicy: IfNotPresent
      livenessProbe:
        failureThreshold: 8
        httpGet:
          host: 127.0.0.1
          path: /healthz
          port: 10259
          scheme: HTTPS
        initialDelaySeconds: 10
        periodSeconds: 10
        timeoutSeconds: 15
      name: kube-scheduler
      resources:
        requests:
          cpu: 100m
      startupProbe:
        failureThreshold: 24
        httpGet:
          host: 127.0.0.1
          path: /healthz
          port: 10259
          scheme: HTTPS
        initialDelaySeconds: 10
        periodSeconds: 10
        timeoutSeconds: 15
      volumeMounts:
        - mountPath: /etc/kubernetes/scheduler.conf
          name: kubeconfig
          readOnly: true
  hostNetwork: true
  priorityClassName: system-node-critical
  volumes:
    - hostPath:
        path: /etc/kubernetes/scheduler.conf
        type: FileOrCreate
      name: kubeconfig
status: {}
```

## Key Configuration Flags

- **`--config`** (Not shown in default, but key):

  - **Role**: Path to a KubeSchedulerConfiguration file. This is the modern way to configure the scheduler (profiles, plugins, weights).
  - **Importance**: If you need to customize scheduling algorithms (like for the CKA exam question on custom schedulers), you use this flag.

- **`--bind-address`**:

  - **Role**: The IP address on which to listen for the `--secure-port`.
  - **Importance**: Usually `127.0.0.1` for security, meaning only local processes (and the kubelet for probes) can access its API.

- **`--leader-elect`**:
  - **Role**: Start a leader election client and attempt to assume leadership before performing main loop duties.
  - **Importance**: Crucial for high-availability control planes. Only the leader schedules pods.

## Troubleshooting

1.  **Symptom: Pods Stuck in `Pending`**:
    This is the #1 sign of scheduler failure. If `kubectl get pods` shows `Pending` and describing the pod shows **no events** (no "Successfully assigned..." event), the scheduler is likely broken or down.

2.  **Inspect Logs**:

    ```bash
    crictl ps | grep scheduler
    crictl logs <container-id>
    ```

3.  **What to Check**:

    - **Connection to API Server**: Is the `--kubeconfig` file valid? Can it talk to `kube-apiserver`?
    - **Configuration Errors**: Did you provide an invalid flag? (e.g. `--config=/file/that/does/not/exist`).
    - **Leader Election**: Check if it's "waiting for lock". If all schedulers think they aren't the leader, no one schedules.

4.  **Custom Scheduler Debugging**:
    If you are running multiple schedulers (e.g., `my-custom-scheduler` alongside default), ensure your Pod spec specifically names it: `schedulerName: my-custom-scheduler`.
