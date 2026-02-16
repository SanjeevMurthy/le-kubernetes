# CKA Mock Exam 3 — Refined Solutions

> **Source:** Udemy CKA Mock Test 3  
> **Total Questions:** 16 (Q1–Q4 and Q7–Q10 not captured in draft)  
> **Sections:** Workloads & Scheduling · Troubleshooting · Storage · Services & Networking

---

## Table of Contents

| #           | Section                | Topic                                         |
| ----------- | ---------------------- | --------------------------------------------- |
| [Q5](#q5)   | Workloads & Scheduling | HPA with Scaling Behavior Policies            |
| [Q6](#q6)   | Troubleshooting        | OOMKilled — Memory Limit Fix                  |
| [Q11](#q11) | Storage                | PVC + Deployment with Sidecar Container       |
| [Q12](#q12) | Workloads & Scheduling | Manual Scheduling (Stop/Start kube-scheduler) |
| [Q13](#q13) | Troubleshooting        | API Server Liveness Probe Port Fix            |
| [Q14](#q14) | Troubleshooting        | External Service with EndpointSlice           |
| [Q15](#q15) | Workloads & Scheduling | ConfigMap from File                           |
| [Q16](#q16) | Troubleshooting        | Network Policy Troubleshooting                |

---

<a id="q5"></a>

## Q5 — HPA with Scaling Behavior Policies

**Section:** Workloads & Scheduling  
**Cluster:** `ssh cluster1-controlplane`

### Question

Create an HPA named `web-ui-hpa` for the deployment `web-ui-deployment` in namespace `ck1967`:

- Average CPU utilization: **65%**
- Min replicas: **2**, Max replicas: **12**
- Scale-up: increase pods by **20%** every **45 seconds**
- Scale-down: decrease pods by **10%** every **60 seconds**

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Create the HPA manifest

```bash
cat <<EOF > /tmp/web-ui-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-ui-hpa
  namespace: ck1967
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-ui-deployment
  minReplicas: 2
  maxReplicas: 12
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 65
  behavior:
    scaleUp:
      policies:
        - type: Percent
          value: 20
          periodSeconds: 45
    scaleDown:
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
EOF
```

> **Key Concepts:**
>
> - `behavior.scaleUp.policies` — controls how aggressively pods are added
> - `behavior.scaleDown.policies` — controls how conservatively pods are removed
> - `type: Percent` with `value: 20` means scale up by 20% of current replicas each period
> - `periodSeconds` defines the cooldown window between scaling events

#### Step 3 — Apply the manifest

```bash
kubectl apply -f /tmp/web-ui-hpa.yaml
```

### Validation

```bash
# Verify HPA creation
kubectl get hpa web-ui-hpa -n ck1967

# Describe to check all behavior policies
kubectl describe hpa web-ui-hpa -n ck1967
# Look for:
#   Behavior:
#     Scale Up:   20% of current replicas per 45s
#     Scale Down: 10% of current replicas per 60s

# Verify it targets the correct deployment
kubectl get hpa web-ui-hpa -n ck1967 -o jsonpath='{.spec.scaleTargetRef}'
```

### 📖 Official Documentation

- [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [HPA Scaling Policies (Behavior)](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior)
- [autoscaling/v2 API](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v2/)

---

<a id="q6"></a>

## Q6 — OOMKilled — Increase Memory Limit

**Section:** Troubleshooting  
**Cluster:** `ssh cluster1-controlplane`

### Question

The `green-deployment-cka15-trb` deployment has a pod that is crashing and restarting continuously. Investigate and fix it so the pod is **running and stable** (no restarts).

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Check the pod status

```bash
kubectl get pods | grep green-deployment
```

The pod will show `CrashLoopBackOff` or high restart count.

#### Step 3 — Check the pod logs

```bash
kubectl logs <green-deployment-pod-name>
```

You will see logs ending with `Killed` — indicating the process was terminated by the OS.

#### Step 4 — Confirm OOMKilled

```bash
kubectl describe pod <green-deployment-pod-name>
```

Under `Last State`, look for:

```
Reason: OOMKilled
```

This confirms the container exceeded its memory limit.

#### Step 5 — Check current memory limits

```bash
kubectl get deploy green-deployment-cka15-trb -o jsonpath='{.spec.template.spec.containers[0].resources}' | python3 -m json.tool
```

#### Step 6 — Increase the memory limit

```bash
kubectl edit deploy green-deployment-cka15-trb
```

Under `resources` → `limits`, increase the memory:

```diff
  resources:
    limits:
-     memory: 256Mi
+     memory: 512Mi
```

Save and exit. The deployment will create a new pod automatically.

> **Tip:** If OOMKilled persists after increasing to 512Mi, continue increasing in increments:  
> `256Mi → 512Mi → 768Mi → 1Gi`

### Validation

```bash
# Watch the pod — it should be Running with 0 restarts
kubectl get pods -w | grep green-deployment

# Wait ~60 seconds to confirm stability (no restarts)
sleep 60 && kubectl get pods | grep green-deployment
# RESTARTS should remain 0

# Verify the memory limit was updated
kubectl get deploy green-deployment-cka15-trb \
  -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}'
# Expected: 512Mi
```

### 📖 Official Documentation

- [Managing Resources for Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Troubleshooting OOMKilled](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#container-killed)
- [Resource Limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-limits)

---

<a id="q11"></a>

## Q11 — PVC + Deployment with Sidecar Container

**Section:** Storage  
**Cluster:** `ssh cluster1-controlplane`

### Question

Deploy a Python app using `/root/olive-app-cka10-str.yaml` with the following modifications:

1. Add a PVC `olive-pvc-cka10-str` claiming **100Mi** from `olive-pv-cka10-str`
2. Add a sidecar container `busybox` sharing the `python-data` volume at `/usr/src` with **read-only** access
3. Ensure the pod is in Running state
4. _(Optional)_ Expose via NodePort service `olive-svc-cka10-str` on port 5000 (nodePort 32006)

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Check the existing PV

```bash
kubectl get pv olive-pv-cka10-str
```

Note the storage class and access modes.

#### Step 3 — Create/update the YAML file

```bash
cat <<'EOF' > /root/olive-app-cka10-str.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: olive-pvc-cka10-str
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: olive-stc-cka10-str
  volumeName: olive-pv-cka10-str
  resources:
    requests:
      storage: 100Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: olive-app-cka10-str
spec:
  replicas: 1
  selector:
    matchLabels:
      app: olive-app-cka10-str
  template:
    metadata:
      labels:
        app: olive-app-cka10-str
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: kubernetes.io/hostname
                    operator: In
                    values:
                      - cluster1-node01
      containers:
        - name: python
          image: poroko/flask-demo-app
          ports:
            - containerPort: 5000
          volumeMounts:
            - name: python-data
              mountPath: /usr/share/
        - name: busybox
          image: busybox
          command: ["/bin/sh", "-c", "sleep 10000"]
          volumeMounts:
            - name: python-data
              mountPath: /usr/src
              readOnly: true
      volumes:
        - name: python-data
          persistentVolumeClaim:
            claimName: olive-pvc-cka10-str
---
apiVersion: v1
kind: Service
metadata:
  name: olive-svc-cka10-str
spec:
  type: NodePort
  ports:
    - port: 5000
      nodePort: 32006
  selector:
    app: olive-app-cka10-str
EOF
```

> **Key Points:**
>
> - The `busybox` sidecar uses `readOnly: true` on the volume mount — it can read but not write
> - The `sleep 10000` command keeps the busybox container alive
> - Both containers share the same `python-data` volume backed by the PVC

#### Step 4 — Deploy

```bash
kubectl apply -f /root/olive-app-cka10-str.yaml
```

### Validation

```bash
# Verify PVC is Bound
kubectl get pvc olive-pvc-cka10-str
# STATUS: Bound

# Verify pod is Running with 2/2 containers
kubectl get pods | grep olive-app
# READY: 2/2, STATUS: Running

# Verify busybox has read-only mount
kubectl exec <olive-pod-name> -c busybox -- touch /usr/src/testfile
# Expected: touch: /usr/src/testfile: Read-only file system

# Verify python container can write
kubectl exec <olive-pod-name> -c python -- touch /usr/share/testfile
# Should succeed

# (Optional) Test the service
curl http://<node-ip>:32006
```

### 📖 Official Documentation

- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [PersistentVolumeClaims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)
- [Sidecar Containers](https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers)
- [Volumes — readOnly](https://kubernetes.io/docs/concepts/storage/volumes/)

---

<a id="q12"></a>

## Q12 — Manual Scheduling (Stop/Start kube-scheduler)

**Section:** Workloads & Scheduling  
**Cluster:** `ssh cluster2-controlplane`

### Question

1. Temporarily stop the `kube-scheduler`
2. Create a pod `onyx-pod` (image: `redis`) scheduled on `cluster2-controlplane` using `nodeName`
3. Restart the `kube-scheduler`
4. Create a pod `ember-pod` (image: `redis`) and verify it runs on `cluster2-node01`

> **Constraint:** Do not use tolerations or remove taints on the control plane.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster2-controlplane
```

#### Step 2 — Stop the kube-scheduler

```bash
mv /etc/kubernetes/manifests/kube-scheduler.yaml /tmp/
```

Wait and confirm it's stopped:

```bash
kubectl get pods -n kube-system | grep kube-scheduler
# Should return nothing (pod should be gone)
```

> **Why this works:** Moving the static pod manifest out of `/etc/kubernetes/manifests/` causes the kubelet to automatically stop the pod.

#### Step 3 — Create `onyx-pod` with `nodeName`

```bash
cat <<EOF > /tmp/onyx-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: onyx-pod
  labels:
    run: onyx-pod
spec:
  nodeName: cluster2-controlplane
  containers:
    - name: onyx-pod
      image: redis
EOF
```

```bash
kubectl apply -f /tmp/onyx-pod.yaml
```

> **Key Insight:** `nodeName` bypasses the scheduler entirely — the pod goes directly to the specified node. This is why we can schedule on the control plane even with taints and without tolerations.

#### Step 4 — Verify onyx-pod is running on the control plane

```bash
kubectl get pods -o wide | grep onyx-pod
# NODE should show: cluster2-controlplane
```

#### Step 5 — Restart the kube-scheduler

```bash
mv /tmp/kube-scheduler.yaml /etc/kubernetes/manifests/
```

Wait for it to come back:

```bash
kubectl get pods -n kube-system | grep kube-scheduler
# Should show Running
```

#### Step 6 — Create `ember-pod`

```bash
kubectl run ember-pod --image=redis --restart=Never
```

### Validation

```bash
# Verify onyx-pod is on the control plane
kubectl get pod onyx-pod -o wide
# NODE: cluster2-controlplane

# Verify ember-pod is on the worker node
kubectl get pod ember-pod -o wide
# NODE: cluster2-node01 (scheduler assigned it to the worker since control plane has taints)

# Both pods should be Running
kubectl get pods -o wide | grep -E "onyx|ember"
```

### 📖 Official Documentation

- [Assigning Pods to Nodes (nodeName)](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodename)
- [Static Pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
- [kube-scheduler](https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)

---

<a id="q13"></a>

## Q13 — API Server Liveness Probe Port Fix

**Section:** Troubleshooting  
**Cluster:** `ssh cluster4-controlplane`

### Question

On cluster4, `kubectl` commands intermittently fail with `connection refused`. The `kube-controller-manager` is restarting continuously. Troubleshoot and fix the issue.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster4-controlplane
```

#### Step 2 — Check kube-system pods

```bash
kubectl get pods -n kube-system
```

You will see `kube-controller-manager` and/or `kube-apiserver` restarting.

#### Step 3 — Check controller-manager logs

```bash
kubectl logs kube-controller-manager-cluster4-controlplane -n kube-system
```

Error:

```
dial tcp 10.10.129.21:6443: connect: connection refused
```

This means the API server is intermittently unavailable.

#### Step 4 — Check API server events

```bash
kubectl get events -n kube-system \
  --field-selector involvedObject.name=kube-apiserver-cluster4-controlplane
```

Look for:

```
Liveness probe failed: Get "https://10.10.132.25:6444/livez": dial tcp 10.10.132.25:6444: connect: connection refused
```

**Root cause:** The liveness probe is configured to check port `6444`, but the API server listens on port `6443`. The probe keeps failing, causing kubelet to restart the API server repeatedly.

#### Step 5 — Fix the API server manifest

```bash
vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Find the `livenessProbe` section and fix the port:

```diff
    livenessProbe:
      httpGet:
        host: <ip>
        path: /livez
-       port: 6444
+       port: 6443
        scheme: HTTPS
```

Save the file. The kubelet will automatically restart the API server with the correct probe.

#### Step 6 — Wait for stabilization

```bash
# Wait 30-60 seconds for the pods to stabilize
sleep 60

# Verify all control plane pods are running and not restarting
kubectl get pods -n kube-system
```

### Validation

```bash
# All control plane pods should be Running with 0 or low restarts
kubectl get pods -n kube-system

# kubectl commands should work consistently now
kubectl get nodes
kubectl get pods --all-namespaces

# Run kubectl multiple times to confirm no intermittent failures
for i in {1..5}; do kubectl get nodes; sleep 5; done
```

### 📖 Official Documentation

- [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [kube-apiserver](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/)
- [Static Pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
- [Troubleshooting Clusters](https://kubernetes.io/docs/tasks/debug/debug-cluster/)

---

<a id="q14"></a>

## Q14 — External Service with EndpointSlice

**Section:** Troubleshooting  
**Cluster:** `ssh cluster3-controlplane`

### Question

An external webserver runs on `student-node:9999`. A service `external-webserver-cka03-svcn` exists in the `kube-public` namespace but has no endpoints. Fix it so pods in cluster3 can access the webserver via this service.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster3-controlplane
```

#### Step 2 — Confirm the external webserver is reachable

```bash
curl student-node:9999
# Should return nginx welcome page
```

#### Step 3 — Check the service

```bash
kubectl describe svc external-webserver-cka03-svcn -n kube-public
```

You will see `Endpoints: <none>` — the service has no backend targets.

#### Step 4 — Get the external node IP

```bash
# Resolve the student-node hostname to an IP
ping -c 1 student-node
# Note the IP address (e.g., 192.168.222.128)
```

Or use:

```bash
STUDENT_IP=$(getent hosts student-node | awk '{print $1}')
echo $STUDENT_IP
```

#### Step 5 — Create an EndpointSlice to map the service to the external IP

```bash
kubectl apply -f - <<EOF
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: external-webserver-cka03-svcn
  namespace: kube-public
  labels:
    kubernetes.io/service-name: external-webserver-cka03-svcn
addressType: IPv4
ports:
  - protocol: TCP
    port: 9999
endpoints:
  - addresses:
      - "192.168.222.128"   # Replace with actual student-node IP
EOF
```

> **Key Concepts:**
>
> - `EndpointSlice` replaces the older `Endpoints` API and is the preferred method
> - The label `kubernetes.io/service-name` links the EndpointSlice to the service
> - The `addresses` field points to the external server IP
> - The `port` must match the port the external service listens on

### Validation

```bash
# Verify the EndpointSlice was created
kubectl get endpointslice -n kube-public | grep external-webserver

# Verify the service now has endpoints
kubectl describe svc external-webserver-cka03-svcn -n kube-public
# Endpoints should now show the student-node IP

# Test from within the cluster
kubectl run -n kube-public --rm -i test-curl \
  --image=curlimages/curl --restart=Never \
  -- curl -m 2 external-webserver-cka03-svcn
# Should return: "Welcome to nginx!"
```

### 📖 Official Documentation

- [EndpointSlices](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/)
- [Services without Selectors](https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors)
- [Connecting Applications with Services](https://kubernetes.io/docs/tutorials/services/connect-applications-service/)

---

<a id="q15"></a>

## Q15 — ConfigMap from File

**Section:** Workloads & Scheduling  
**Cluster:** `ssh cluster1-controlplane`

### Question

Create a ConfigMap called `db-user-pass-cka17-arch` in the default namespace using the contents of the file `/opt/db-user-pass` on `cluster1-controlplane`.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — (Optional) Inspect the source file

```bash
cat /opt/db-user-pass
```

#### Step 3 — Create the ConfigMap

```bash
kubectl create configmap db-user-pass-cka17-arch --from-file=/opt/db-user-pass
```

> **Tip:** `--from-file` creates a ConfigMap where the filename becomes the key and the file contents become the value. If you need a custom key name, use `--from-file=<key>=<filepath>`.

### Validation

```bash
# Verify ConfigMap was created
kubectl get cm db-user-pass-cka17-arch

# View the ConfigMap data
kubectl describe cm db-user-pass-cka17-arch

# Verify the data key matches the filename
kubectl get cm db-user-pass-cka17-arch -o yaml
# data:
#   db-user-pass: |
#     <file contents>
```

### 📖 Official Documentation

- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Create ConfigMap from File](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#create-configmaps-from-files)

---

<a id="q16"></a>

## Q16 — Network Policy Troubleshooting

**Section:** Troubleshooting  
**Cluster:** `ssh cluster1-controlplane`

### Question

An nginx pod `cyan-pod-cka28-trb` is running in namespace `cyan-ns-cka28-trb` with a service `cyan-svc-cka28-trb` and a network policy `cyan-np-cka28-trb`.

Two pods in the `default` namespace:

- `cyan-white-cka28-trb` — **should** have access
- `cyan-black-cka28-trb` — should **not** have access

**Problem:** The app is not accessible from anywhere. Fix the network policy.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Test current connectivity

```bash
# From cyan-white (should work but currently fails)
kubectl exec cyan-white-cka28-trb -- curl -s --max-time 3 \
  cyan-svc-cka28-trb.cyan-ns-cka28-trb.svc.cluster.local

# From cyan-black (should not work)
kubectl exec cyan-black-cka28-trb -- curl -s --max-time 3 \
  cyan-svc-cka28-trb.cyan-ns-cka28-trb.svc.cluster.local
```

Both will fail/timeout.

#### Step 3 — Inspect the current network policy

```bash
kubectl get networkpolicy cyan-np-cka28-trb -n cyan-ns-cka28-trb -o yaml
```

Look for these issues:

1. **Wrong port:** Policy uses `8080` but nginx runs on port `80`
2. **Missing egress CIDR:** No `to` block in egress, so egress is blocked
3. **Missing ingress pod selector:** No selector to allow `cyan-white-cka28-trb`

#### Step 4 — Edit the network policy

```bash
kubectl edit networkpolicy cyan-np-cka28-trb -n cyan-ns-cka28-trb
```

Apply these three fixes:

**Fix 1 — Change port from 8080 to 80 (in both ingress and egress):**

```diff
- - port: 8080
+ - port: 80
```

**Fix 2 — Add egress destination CIDR (allow all outbound):**

```yaml
egress:
  - ports:
      - port: 80
        protocol: TCP
    to:
      - ipBlock:
          cidr: 0.0.0.0/0
```

**Fix 3 — Add ingress `from` selector to allow only `cyan-white-cka28-trb`:**

```yaml
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: default
        podSelector:
          matchLabels:
            app: cyan-white-cka28-trb
    ports:
      - port: 80
        protocol: TCP
```

> **Important:** The `namespaceSelector` and `podSelector` are under the **same** `from` entry (AND logic). This means: allow traffic from pods labeled `app: cyan-white-cka28-trb` **AND** that are in the `default` namespace.

The complete corrected policy should look like:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cyan-np-cka28-trb
  namespace: cyan-ns-cka28-trb
spec:
  podSelector:
    matchLabels:
      app: cyan-pod-cka28-trb
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: default
          podSelector:
            matchLabels:
              app: cyan-white-cka28-trb
      ports:
        - port: 80
          protocol: TCP
  egress:
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
      ports:
        - port: 80
          protocol: TCP
```

### Validation

```bash
# Test from cyan-white — should work ✅
kubectl exec cyan-white-cka28-trb -- curl -s --max-time 3 \
  cyan-svc-cka28-trb.cyan-ns-cka28-trb.svc.cluster.local
# Expected: nginx welcome page

# Test from cyan-black — should NOT work ❌
kubectl exec cyan-black-cka28-trb -- curl -s --max-time 3 \
  cyan-svc-cka28-trb.cyan-ns-cka28-trb.svc.cluster.local
# Expected: timeout / no response

# Verify the network policy
kubectl describe networkpolicy cyan-np-cka28-trb -n cyan-ns-cka28-trb
```

### 📖 Official Documentation

- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Declare Network Policy](https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/)
- [NetworkPolicy API Reference](https://kubernetes.io/docs/reference/kubernetes-api/policy-resources/network-policy-v1/)

---

## Quick Reference — Key `kubectl` Commands

| Action                      | Command                                                                 |
| --------------------------- | ----------------------------------------------------------------------- |
| Create HPA (imperative)     | `kubectl autoscale deploy <name> --cpu-percent=<n> --min=<n> --max=<n>` |
| Get HPA details             | `kubectl describe hpa <name> -n <ns>`                                   |
| Edit deployment             | `kubectl edit deploy <name> -n <ns>`                                    |
| Check pod logs              | `kubectl logs <pod-name>`                                               |
| Describe pod (see events)   | `kubectl describe pod <name>`                                           |
| Create ConfigMap from file  | `kubectl create cm <name> --from-file=<path>`                           |
| Get network policy          | `kubectl get netpol -n <ns>`                                            |
| Edit network policy         | `kubectl edit netpol <name> -n <ns>`                                    |
| Exec into pod               | `kubectl exec -it <pod> -- <cmd>`                                       |
| Run temp pod for testing    | `kubectl run tmp --image=busybox --rm -it --restart=Never -- <cmd>`     |
| Get pods with node info     | `kubectl get pods -o wide`                                              |
| Get events for specific pod | `kubectl get events --field-selector involvedObject.name=<pod>`         |
| Force-replace a pod         | `kubectl replace -f <file> --force`                                     |
| Get EndpointSlices          | `kubectl get endpointslice -n <ns>`                                     |
| View resource YAML          | `kubectl get <resource> <name> -o yaml`                                 |

## Quick Reference — Key `kubeadm` & System Commands

| Action                            | Command                                                  |
| --------------------------------- | -------------------------------------------------------- |
| Check kubeadm version             | `kubeadm version`                                        |
| Stop kube-scheduler (static pod)  | `mv /etc/kubernetes/manifests/kube-scheduler.yaml /tmp/` |
| Start kube-scheduler (static pod) | `mv /tmp/kube-scheduler.yaml /etc/kubernetes/manifests/` |
| Edit API server manifest          | `vi /etc/kubernetes/manifests/kube-apiserver.yaml`       |
| Check kubelet status              | `systemctl status kubelet`                               |
| Restart kubelet                   | `sudo systemctl restart kubelet`                         |
| View kubelet logs                 | `journalctl -u kubelet -f`                               |
| Check containers (CRI)            | `crictl ps -a`                                           |
| Static pod manifest directory     | `/etc/kubernetes/manifests/`                             |
| Kubelet config                    | `/var/lib/kubelet/config.yaml`                           |
| Generate join command             | `kubeadm token create --print-join-command`              |
| Upgrade plan                      | `kubeadm upgrade plan`                                   |
| Upgrade apply                     | `kubeadm upgrade apply v<version>`                       |
