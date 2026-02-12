# CKA Control Plane Troubleshooting — Scenario-Based Questions & Solutions

> **Purpose:** Exam-style scenarios covering every control plane component with step-by-step diagnosis, remediation commands, YAML manifests, and validation  
> **Components Covered:** kube-apiserver · etcd · kube-scheduler · kube-controller-manager · kubelet · CoreDNS/CNI · kubeadm/Certificates

---

## Table of Contents

| #          | Component               | Scenario                                              |
| ---------- | ----------------------- | ----------------------------------------------------- |
| [1](#s1)   | kube-apiserver          | Wrong etcd endpoint port                              |
| [2](#s2)   | kube-apiserver          | Liveness probe port mismatch                          |
| [3](#s3)   | kube-apiserver          | Expired API server certificate                        |
| [4](#s4)   | etcd                    | Backup and restore                                    |
| [5](#s5)   | etcd                    | Data directory path mismatch                          |
| [6](#s6)   | etcd                    | Database space exceeded                               |
| [7](#s7)   | kube-scheduler          | Manifest moved / scheduler stopped                    |
| [8](#s8)   | kube-scheduler          | Wrong kubeconfig path in manifest                     |
| [9](#s9)   | kube-scheduler          | Excessive resource requests preventing scheduling     |
| [10](#s10) | kube-controller-manager | Wrong service-account-private-key-file path           |
| [11](#s11) | kube-controller-manager | Leader election failure (API server connectivity)     |
| [12](#s12) | kube-controller-manager | Wrong cluster-signing-cert/key path                   |
| [13](#s13) | kubelet                 | Wrong binary path in systemd unit                     |
| [14](#s14) | kubelet                 | Wrong CA certificate path in kubelet config           |
| [15](#s15) | kubelet                 | Node NotReady — swap enabled                          |
| [16](#s16) | CoreDNS                 | CrashLoopBackOff — DNS loop detection                 |
| [17](#s17) | CNI                     | Missing CNI plugin — pods stuck in ContainerCreating  |
| [18](#s18) | CNI (Flannel)           | Pod CIDR mismatch                                     |
| [19](#s19) | kubeadm                 | Cluster upgrade (control plane + worker)              |
| [20](#s20) | kubeadm                 | Certificate renewal                                   |
| [21](#s21) | kubeadm                 | Join token expired — adding worker node               |
| [22](#s22) | Application             | ImagePullBackOff / ErrImagePull                       |
| [23](#s23) | Application             | CrashLoopBackOff — probes & resource tuning           |
| [24](#s24) | Application             | OOMKilled — container terminated (exit code 137)      |
| [25](#s25) | Application / Scheduler | Pods stuck in Pending — scheduling constraints        |
| [26](#s26) | Networking              | Service selector mismatch — no endpoints              |
| [27](#s27) | Networking              | NetworkPolicy blocking inter-pod traffic              |
| [28](#s28) | Ingress                 | Ingress misconfiguration — 404 / 502 errors           |
| [29](#s29) | Kubeconfig              | Corrupted kubeconfig — connection refused             |
| [30](#s30) | Webhooks                | Admission webhook failure — API slowness / rejections |

---

## Diagnostic Methodology (Use for Every Scenario)

```text
1. kubectl get nodes                              # Node health
2. kubectl get pods -n kube-system                 # Control plane pod status
3. kubectl describe pod <name> -n kube-system      # Events + exit codes
4. kubectl logs <pod> -n kube-system [--previous]  # Container logs
5. journalctl -u kubelet -f                        # Kubelet logs (host-level)
6. crictl ps -a && crictl logs <id>                # CRI-level (works when API is down)
7. cat /var/log/pods/<namespace>_<pod>_<uid>/...   # Raw pod logs on disk
```

---

# kube-apiserver Scenarios

<a id="s1"></a>

## Scenario 1 — Wrong etcd Endpoint Port

### Question

After a cluster migration, all `kubectl` commands fail with:

```
The connection to the server <controlplane-ip>:6443 was refused
```

The `kube-apiserver` static pod is in `CrashLoopBackOff`. Investigate and fix the issue.

### Diagnosis

```bash
# SSH into the control plane node
ssh controlplane

# Check the kube-apiserver status via crictl (API is down, kubectl won't work)
crictl ps -a | grep kube-apiserver
# STATUS: Exited

# Check kube-apiserver logs
crictl logs <container-id>
# OR check on-disk logs:
cat /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/*.log | tail -30
```

**Error in logs:**

```
dial tcp 127.0.0.1:2380: connect: connection refused
# OR
context deadline exceeded (etcd connection)
```

**Root Cause:** The `--etcd-servers` flag in the API server manifest points to port `2380` (which is the etcd **peer** port) instead of port `2379` (the **client** port).

### Solution

```bash
vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Find the `--etcd-servers` flag and fix the port:

```diff
- - --etcd-servers=https://127.0.0.1:2380
+ - --etcd-servers=https://127.0.0.1:2379
```

Save the file. The kubelet will automatically restart the static pod.

### Validation

```bash
# Wait ~30 seconds, then verify
crictl ps | grep kube-apiserver
# Should show Running

kubectl get nodes
# Should return node list

kubectl get pods -n kube-system
# All pods should be Running
```

### 📖 Documentation

- [kube-apiserver reference](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/)
- [etcd ports & configuration](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/setup-ha-etcd-with-kubeadm/)

---

<a id="s2"></a>

## Scenario 2 — Liveness Probe Port Mismatch

### Question

The cluster is intermittently available — `kubectl` commands work sometimes but fail with `connection refused` other times. The `kube-controller-manager` is restarting continuously. Investigate and fix.

### Diagnosis

```bash
ssh controlplane

# Check kube-system pods
kubectl get pods -n kube-system
# kube-apiserver may show restarts, kube-controller-manager crash-looping

# Check events for the API server pod
kubectl get events -n kube-system \
  --field-selector involvedObject.name=kube-apiserver-controlplane \
  --sort-by='.lastTimestamp' | tail -10
```

**Key event:**

```
Warning  Unhealthy  Liveness probe failed: Get "https://10.0.0.5:6444/livez":
  dial tcp 10.0.0.5:6444: connect: connection refused
```

**Root Cause:** The liveness probe is configured to check port `6444`, but the API server listens on `6443`. The probe keeps failing, causing kubelet to kill and restart the API server.

### Solution

```bash
vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

Find the `livenessProbe` section:

```diff
    livenessProbe:
      httpGet:
        host: 10.0.0.5
        path: /livez
-       port: 6444
+       port: 6443
        scheme: HTTPS
```

Also check `startupProbe` and `readinessProbe` for the same issue.

### Validation

```bash
# Wait 30-60 seconds
sleep 60

# Verify stable operation (no restarts)
kubectl get pods -n kube-system
# RESTARTS should be 0 for API server

# Run kubectl multiple times to confirm no intermittent failures
for i in $(seq 1 5); do kubectl get nodes; sleep 3; done
```

### 📖 Documentation

- [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Static Pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)

---

<a id="s3"></a>

## Scenario 3 — Expired API Server Certificate

### Question

All `kubectl` commands fail with:

```
Unable to connect to the server: x509: certificate has expired or is not yet valid
```

No workloads can be managed. Fix the issue.

### Diagnosis

```bash
ssh controlplane

# Check certificate expiry
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 2 "Validity"
# Shows: Not After : <date in the past>

# Or use kubeadm
kubeadm certs check-expiration
# Will show which certificates are expired
```

### Solution

```bash
# Renew the API server certificate
kubeadm certs renew apiserver

# Verify the new expiry
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 2 "Validity"

# Restart the API server by moving its manifest out and back
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sleep 5
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

# If kubeconfig is also affected, regenerate it
kubeadm certs renew admin.conf
cp /etc/kubernetes/admin.conf ~/.kube/config
```

> **Tip:** To renew ALL certificates at once (during maintenance windows):
>
> ```bash
> kubeadm certs renew all
> ```

### Validation

```bash
# Verify all certs are valid
kubeadm certs check-expiration

# Test kubectl
kubectl get nodes
kubectl get pods -n kube-system
```

### 📖 Documentation

- [Certificate Management with kubeadm](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)
- [PKI certificates and requirements](https://kubernetes.io/docs/setup/best-practices/certificates/)

---

# etcd Scenarios

<a id="s4"></a>

## Scenario 4 — etcd Backup and Restore

### Question

Create a backup of the etcd database and save it to `/opt/etcd-backup.db`. Then restore it to a new data directory `/var/lib/etcd-restore`.

### Solution

#### Step 1 — Identify certificate paths

```bash
# Get cert paths from the etcd static pod manifest
cat /etc/kubernetes/manifests/etcd.yaml | grep -E "cert|key|trusted"
```

You will find:

- `--trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt`
- `--cert-file=/etc/kubernetes/pki/etcd/server.crt`
- `--key-file=/etc/kubernetes/pki/etcd/server.key`

#### Step 2 — Create the backup

```bash
ETCDCTL_API=3 etcdctl snapshot save /opt/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

#### Step 3 — Verify the snapshot

```bash
ETCDCTL_API=3 etcdctl snapshot status /opt/etcd-backup.db --write-out=table
```

#### Step 4 — Restore to a new directory

```bash
ETCDCTL_API=3 etcdctl snapshot restore /opt/etcd-backup.db \
  --data-dir=/var/lib/etcd-restore
```

> **Note:** In newer versions, use `etcdutl` instead of `etcdctl` for restore:
>
> ```bash
> etcdutl snapshot restore /opt/etcd-backup.db --data-dir=/var/lib/etcd-restore
> ```

#### Step 5 — Update etcd manifest to use the new directory

```bash
vi /etc/kubernetes/manifests/etcd.yaml
```

Update the `hostPath` volume:

```diff
  volumes:
    - hostPath:
-       path: /var/lib/etcd
+       path: /var/lib/etcd-restore
        type: DirectoryOrCreate
      name: etcd-data
```

Also update the `--data-dir` flag if explicitly set:

```diff
- - --data-dir=/var/lib/etcd
+ - --data-dir=/var/lib/etcd-restore
```

Save. Wait for the etcd pod to restart.

### Validation

```bash
# Wait for etcd to come back
sleep 30
kubectl get pods -n kube-system | grep etcd

# Verify etcd health
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify cluster data is intact
kubectl get all --all-namespaces
```

### 📖 Documentation

- [Operating etcd clusters](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)
- [Backing up an etcd cluster](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster)

---

<a id="s5"></a>

## Scenario 5 — etcd Data Directory Mismatch

### Question

After a maintenance operation, the `etcd` pod is in `CrashLoopBackOff`. The API server is also failing because it cannot connect to etcd. Investigate and fix.

### Diagnosis

```bash
ssh controlplane

# Check etcd pod
crictl ps -a | grep etcd
# Exited / CrashLoopBackOff

# Check etcd logs
crictl logs <etcd-container-id>
```

**Error in logs:**

```
member has already been bootstrapped
cannot access data directory: /var/lib/etcd-data: no such file or directory
```

**Root Cause:** The `--data-dir` flag points to `/var/lib/etcd-data`, but the actual data lives in `/var/lib/etcd`. Or the `hostPath` volume mount doesn't match the container's `--data-dir`.

### Solution

```bash
vi /etc/kubernetes/manifests/etcd.yaml
```

Check three things must be consistent:

1. **`--data-dir` flag** — the path etcd uses inside the container
2. **`volumeMounts.mountPath`** — where the host directory is mounted in the container
3. **`volumes.hostPath.path`** — the actual directory on the host

```yaml
spec:
  containers:
    - command:
        - etcd
        - --data-dir=/var/lib/etcd # 1. Must match mountPath
      volumeMounts:
        - mountPath: /var/lib/etcd # 2. Must match --data-dir
          name: etcd-data
  volumes:
    - hostPath:
        path: /var/lib/etcd # 3. Must exist on the host
        type: DirectoryOrCreate
      name: etcd-data
```

Verify the host directory exists:

```bash
ls -la /var/lib/etcd/
# Should contain: member/ directory
```

### Validation

```bash
sleep 30
kubectl get pods -n kube-system | grep etcd
# Running, 0 restarts

kubectl get nodes
# All nodes should be Ready
```

### 📖 Documentation

- [etcd configuration flags](https://etcd.io/docs/v3.5/op-guide/configuration/)
- [Static Pod manifests](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)

---

<a id="s6"></a>

## Scenario 6 — etcd Database Space Exceeded

### Question

The cluster is read-only — you can GET resources but cannot create or update anything. All write operations fail with:

```
rpc error: code = ResourceExhausted desc = etcdserver: mvcc: database space exceeded
```

Fix the issue without data loss.

### Diagnosis

```bash
# Check etcd database size
ETCDCTL_API=3 etcdctl endpoint status --write-out=table \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
# Check the "DB SIZE" column — if near 2GB (default quota), it's full

# Check active alarms
ETCDCTL_API=3 etcdctl alarm list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
# Output: alarm:NOSPACE
```

### Solution

```bash
# Step 1: Compact the revision history (get current revision first)
REVISION=$(ETCDCTL_API=3 etcdctl endpoint status --write-out=json \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["Status"]["header"]["revision"])')

ETCDCTL_API=3 etcdctl compact $REVISION \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Step 2: Defragment the database
ETCDCTL_API=3 etcdctl defrag \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Step 3: Disarm the alarm
ETCDCTL_API=3 etcdctl alarm disarm \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

> **Optional:** Increase the quota in the etcd manifest to prevent recurrence:
>
> ```yaml
> - --quota-backend-bytes=8589934592 # 8 GiB
> ```

### Validation

```bash
# Verify alarm is cleared
ETCDCTL_API=3 etcdctl alarm list ...
# Should return: empty

# Verify writes work
kubectl run test-write --image=nginx --restart=Never
kubectl delete pod test-write

# Check reduced DB size
ETCDCTL_API=3 etcdctl endpoint status --write-out=table ...
```

### 📖 Documentation

- [etcd space quota](https://etcd.io/docs/v3.5/op-guide/maintenance/#space-quota)
- [etcd defragmentation](https://etcd.io/docs/v3.5/op-guide/maintenance/#defragmentation)

---

# kube-scheduler Scenarios

<a id="s7"></a>

## Scenario 7 — Scheduler Manifest Moved / Missing

### Question

All new pods are stuck in `Pending` state. Existing pods continue to run normally. Identify and fix the issue.

### Diagnosis

```bash
ssh controlplane

# Check if the scheduler is running
kubectl get pods -n kube-system | grep scheduler
# No output — the scheduler pod is missing

# Check the manifest directory
ls /etc/kubernetes/manifests/
# kube-scheduler.yaml is NOT listed

# Check if it was moved
ls /tmp/ | grep scheduler
# kube-scheduler.yaml found in /tmp/
```

### Solution

```bash
# Move the manifest back
mv /tmp/kube-scheduler.yaml /etc/kubernetes/manifests/

# Wait for the scheduler to start
sleep 15
kubectl get pods -n kube-system | grep scheduler
```

### Validation

```bash
# Scheduler should be running
kubectl get pods -n kube-system | grep scheduler
# Running, RESTARTS: 0

# Pending pods should now get scheduled
kubectl get pods --all-namespaces | grep Pending
# Should be empty (pods are now Running)

# Create a test pod to confirm scheduling works
kubectl run scheduler-test --image=nginx --restart=Never
kubectl get pod scheduler-test -o wide
# Should show a NODE assignment
kubectl delete pod scheduler-test
```

### 📖 Documentation

- [kube-scheduler](https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/)
- [Static Pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)

---

<a id="s8"></a>

## Scenario 8 — Wrong Kubeconfig Path in Scheduler Manifest

### Question

The `kube-scheduler` pod is in `CrashLoopBackOff`. Investigate and fix.

### Diagnosis

```bash
ssh controlplane

kubectl get pods -n kube-system | grep scheduler
# CrashLoopBackOff

kubectl logs kube-scheduler-controlplane -n kube-system
```

**Error:**

```
unable to load client kubeconfig "/etc/kubernetes/schedulerr.conf":
  stat /etc/kubernetes/schedulerr.conf: no such file or directory
```

**Root Cause:** The `--kubeconfig` flag has a typo — `schedulerr.conf` instead of `scheduler.conf`.

### Solution

```bash
vi /etc/kubernetes/manifests/kube-scheduler.yaml
```

Fix the kubeconfig path:

```diff
  containers:
    - command:
        - kube-scheduler
-       - --kubeconfig=/etc/kubernetes/schedulerr.conf
+       - --kubeconfig=/etc/kubernetes/scheduler.conf
```

Verify the file exists:

```bash
ls -la /etc/kubernetes/scheduler.conf
```

### Validation

```bash
sleep 20
kubectl get pods -n kube-system | grep scheduler
# Running, 0 restarts

# Test scheduling
kubectl run test-scheduler --image=nginx --restart=Never
kubectl get pod test-scheduler -o wide
# Should be assigned to a node
kubectl delete pod test-scheduler
```

### 📖 Documentation

- [kube-scheduler reference](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-scheduler/)

---

<a id="s9"></a>

## Scenario 9 — Excessive Resource Requests Preventing Start

### Question

After a cluster migration, the `kube-scheduler` pod is stuck in `Pending`. The node has limited resources.

### Diagnosis

```bash
ssh controlplane

crictl ps -a | grep scheduler
# Not found — the container never started

kubectl describe pod kube-scheduler-controlplane -n kube-system
# Events: FailedScheduling — Insufficient cpu
# OR: check the manifest for unreasonable resource requests
```

Check the manifest:

```bash
cat /etc/kubernetes/manifests/kube-scheduler.yaml | grep -A 5 resources
```

**Root Cause:** The `resources.requests.cpu` is set to an unreasonably high value (e.g., `10000m`).

### Solution

```bash
vi /etc/kubernetes/manifests/kube-scheduler.yaml
```

```diff
        resources:
          requests:
-           cpu: "10000m"
+           cpu: "100m"
```

> **Exam Tip:** This is a known CKA pattern after "cluster migration" scenarios. Always check resource requests for ALL static pods (`kube-scheduler`, `kube-controller-manager`, `kube-apiserver`).

### Validation

```bash
sleep 20
kubectl get pods -n kube-system | grep scheduler
# Running
```

### 📖 Documentation

- [Resource Management for Pods](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

---

# kube-controller-manager Scenarios

<a id="s10"></a>

## Scenario 10 — Wrong Service Account Key Path

### Question

The `kube-controller-manager` is in `CrashLoopBackOff`. New deployments cannot create pods. Investigate and fix.

### Diagnosis

```bash
ssh controlplane

kubectl logs kube-controller-manager-controlplane -n kube-system
```

**Error:**

```
open /etc/kubernetes/pki/sa.key: no such file or directory
```

**Root Cause:** The `--service-account-private-key-file` flag points to the wrong path.

### Solution

```bash
# Verify the correct file location
ls /etc/kubernetes/pki/sa.*
# /etc/kubernetes/pki/sa.key
# /etc/kubernetes/pki/sa.pub

vi /etc/kubernetes/manifests/kube-controller-manager.yaml
```

Fix the path:

```diff
- - --service-account-private-key-file=/etc/kubernetes/pki/sa.key.bak
+ - --service-account-private-key-file=/etc/kubernetes/pki/sa.key
```

### Validation

```bash
sleep 20
kubectl get pods -n kube-system | grep controller-manager
# Running, 0 restarts

# Test: create a deployment and verify pods are created
kubectl create deploy test-kcm --image=nginx --replicas=2
kubectl get pods | grep test-kcm
# 2 pods should exist
kubectl delete deploy test-kcm
```

### 📖 Documentation

- [kube-controller-manager](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/)

---

<a id="s11"></a>

## Scenario 11 — Leader Election Failure (API Server Connectivity)

### Question

The `kube-controller-manager` keeps restarting with `leaderelection lost` errors. Investigate and fix.

### Diagnosis

```bash
ssh controlplane

kubectl logs kube-controller-manager-controlplane -n kube-system --previous
```

**Error pattern:**

```
leaderelection.go:330] error retrieving resource lock kube-system/kube-controller-manager:
  Get "https://10.0.0.5:6443/...": dial tcp 10.0.0.5:6443: connect: connection refused
```

**Root Cause:** The controller-manager cannot reach the API server. This is a cascading failure — the API server is the root cause (see Scenarios 1–3).

### Solution

1. **Fix the API server first** (check Scenarios 1, 2, or 3)
2. Once the API server is stable, the controller-manager will auto-recover

If the controller-manager has a separate kubeconfig issue:

```bash
vi /etc/kubernetes/manifests/kube-controller-manager.yaml
```

Verify:

```yaml
- --kubeconfig=/etc/kubernetes/controller-manager.conf
```

Ensure the file exists and contains the correct API server address:

```bash
cat /etc/kubernetes/controller-manager.conf | grep server
# Should point to https://<control-plane-ip>:6443
```

### Validation

```bash
kubectl get pods -n kube-system | grep controller
# Running, stable (no increasing restarts)

# Check leader election lease
kubectl get lease kube-controller-manager -n kube-system -o yaml
# Should show the current holder and recent renewTime
```

### 📖 Documentation

- [Leader Election](https://kubernetes.io/docs/concepts/architecture/leases/#leader-election)

---

<a id="s12"></a>

## Scenario 12 — Wrong Cluster Signing Certificate Path

### Question

New CSRs (Certificate Signing Requests) are stuck in `Pending` and not being auto-approved. The `kube-controller-manager` logs show certificate signing errors. Investigate and fix.

### Diagnosis

```bash
kubectl get csr
# Several CSRs in Pending state

kubectl logs kube-controller-manager-controlplane -n kube-system | grep -i sign
```

**Error:**

```
error retrieving signing cert/key: open /etc/kubernetes/pki/ca.cert:
  no such file or directory
```

**Root Cause:** The `--cluster-signing-cert-file` or `--cluster-signing-key-file` flags have wrong file extensions or paths.

### Solution

```bash
# Verify correct files exist
ls /etc/kubernetes/pki/ca.*
# /etc/kubernetes/pki/ca.crt  (not ca.cert)
# /etc/kubernetes/pki/ca.key

vi /etc/kubernetes/manifests/kube-controller-manager.yaml
```

```diff
- - --cluster-signing-cert-file=/etc/kubernetes/pki/ca.cert
+ - --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt
```

### Validation

```bash
sleep 20
kubectl get pods -n kube-system | grep controller-manager
# Running

# Pending CSRs should now be approved
kubectl get csr
# Approved, Issued
```

### 📖 Documentation

- [Signing Certificates](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#signer-api)

---

# kubelet Scenarios

<a id="s13"></a>

## Scenario 13 — Wrong kubelet Binary Path in systemd Unit

### Question

A worker node shows `NotReady`. SSH into the node and fix it.

### Diagnosis

```bash
ssh worker-node1

systemctl status kubelet
# ● kubelet.service - kubelet: The Kubernetes Node Agent
#    Active: failed (Result: exit-code)
```

```bash
journalctl -u kubelet --no-pager | tail -20
```

**Error:**

```
kubelet.service: Failed to execute /usr/local/bin/kubelet: No such file or directory
```

**Root Cause:** The systemd service file points to the wrong binary path.

### Solution

```bash
# Find the actual kubelet binary
which kubelet
# /usr/bin/kubelet

# Check the systemd drop-in configs
cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
# OR
systemctl cat kubelet | grep ExecStart
```

Edit the offending file:

```bash
vi /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
# OR
vi /usr/lib/systemd/system/kubelet.service
```

```diff
- ExecStart=/usr/local/bin/kubelet
+ ExecStart=/usr/bin/kubelet
```

```bash
systemctl daemon-reload
systemctl restart kubelet
```

### Validation

```bash
systemctl status kubelet
# Active: active (running)

# From the control plane:
kubectl get nodes
# worker-node1 should be Ready
```

### 📖 Documentation

- [kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/)
- [Troubleshooting kubeadm — kubelet](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/#kubelet-is-not-running)

---

<a id="s14"></a>

## Scenario 14 — Wrong CA Certificate Path in kubelet Config

### Question

A worker node is `NotReady`. The kubelet is running but repeatedly failing with TLS errors.

### Diagnosis

```bash
ssh worker-node1

systemctl status kubelet
# Active but showing errors

journalctl -u kubelet -f
```

**Error:**

```
x509: certificate signed by unknown authority
# OR
unable to load client CA file /etc/kubernetes/pki/CA.crt:
  open /etc/kubernetes/pki/CA.crt: no such file or directory
```

**Root Cause:** The kubelet config references a wrong CA certificate path (case-sensitive filename or wrong directory).

### Solution

```bash
# Find the kubelet config file
cat /var/lib/kubelet/config.yaml | grep -i ca
# Look for: tlsCACertFile or authentication.x509.clientCAFile

# Verify the actual CA cert location
ls /etc/kubernetes/pki/ca.*
# /etc/kubernetes/pki/ca.crt

# Fix the kubelet config
vi /var/lib/kubelet/config.yaml
```

```diff
authentication:
  x509:
-   clientCAFile: /etc/kubernetes/pki/CA.crt
+   clientCAFile: /etc/kubernetes/pki/ca.crt
```

```bash
systemctl restart kubelet
```

### Validation

```bash
journalctl -u kubelet --no-pager | tail -10
# No x509 errors

# From control plane:
kubectl get nodes
# worker-node1: Ready
```

### 📖 Documentation

- [kubelet TLS Configuration](https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/)
- [Kubelet Config reference](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/)

---

<a id="s15"></a>

## Scenario 15 — Node NotReady Due to Swap Enabled

### Question

A newly provisioned worker node shows `NotReady` and pods won't schedule. The kubelet keeps crashing.

### Diagnosis

```bash
ssh worker-node1

journalctl -u kubelet | tail -20
```

**Error:**

```
"command failed" err="failed to run Kubelet: running with swap on is not supported,
  please disable swap"
```

### Solution

```bash
# Disable swap immediately
sudo swapoff -a

# Disable swap permanently (survives reboot)
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Restart kubelet
sudo systemctl restart kubelet
```

> **Alternative (Kubernetes 1.28+):** You can enable swap support by setting `failSwapOn: false` in `/var/lib/kubelet/config.yaml`, but this is **not** recommended for the CKA exam.

### Validation

```bash
# Verify swap is off
free -m
# Swap total should be 0

systemctl status kubelet
# Active: running

# From control plane:
kubectl get nodes
# worker-node1: Ready
```

### 📖 Documentation

- [kubeadm prerequisites — disable swap](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#before-you-begin)

---

# CoreDNS & CNI Scenarios

<a id="s16"></a>

## Scenario 16 — CoreDNS CrashLoopBackOff (DNS Loop Detection)

### Question

CoreDNS pods are in `CrashLoopBackOff`. Pods cannot resolve service names. Investigate and fix.

### Diagnosis

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
# CrashLoopBackOff

kubectl logs -n kube-system <coredns-pod>
```

**Error:**

```
[FATAL] plugin/loop: Loop (127.0.0.1:53 -> :53) detected for zone ".",
  See https://coredns.io/plugins/loop#troubleshooting
```

**Root Cause:** The host's `/etc/resolv.conf` points to `127.0.0.1` (local DNS stub resolver like `systemd-resolved`). CoreDNS inherits this and creates a forwarding loop.

### Solution

**Option A — Edit the CoreDNS ConfigMap:**

```bash
kubectl edit cm coredns -n kube-system
```

Replace the `forward` directive to use an external DNS instead of `/etc/resolv.conf`:

```diff
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
        }
-       forward . /etc/resolv.conf
+       forward . 8.8.8.8 8.8.4.4
        cache 30
        loop
        reload
    }
```

**Option B — Fix host resolv.conf:**

```bash
# On the node running CoreDNS
sudo vi /etc/resolv.conf
# Change: nameserver 127.0.0.1
# To:     nameserver 8.8.8.8
```

After editing the ConfigMap, restart CoreDNS:

```bash
kubectl rollout restart deployment coredns -n kube-system
```

### Validation

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
# Running

# Test DNS resolution from a pod
kubectl run dns-test --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default
# Should resolve successfully
```

### 📖 Documentation

- [CoreDNS troubleshooting](https://coredns.io/plugins/loop/#troubleshooting)
- [Debugging DNS Resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)

---

<a id="s17"></a>

## Scenario 17 — Missing CNI Plugin — Pods Stuck in ContainerCreating

### Question

All new pods are stuck in `ContainerCreating`. Nodes show `Ready` but have `NetworkNotReady` condition. Install/fix the CNI plugin.

### Diagnosis

```bash
kubectl get nodes
# NotReady (or conditions show NetworkNotReady)

kubectl describe node controlplane | grep -A 5 "Conditions"
# NetworkReady=False  reason: NetworkPluginNotReady cni plugin not initialized

kubectl describe pod <stuck-pod>
# Events: Warning FailedCreatePodSandbox
# "failed to setup network for sandbox: ... cni plugin not initialized"
```

Check on the node:

```bash
ssh controlplane
ls /etc/cni/net.d/
# Empty — no CNI configuration files

ls /opt/cni/bin/
# May or may not have binaries
```

### Solution — Install Calico (or Flannel)

**Option A: Install Calico**

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
```

**Option B: Install Flannel**

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

> **Exam Tip:** The exam will specify which CNI to install and may provide the URL. Read the question carefully.

### Validation

```bash
# Wait for CNI pods to become ready
kubectl get pods -n kube-system -w | grep -E "calico|flannel"

# Check nodes
kubectl get nodes
# All should show Ready

# Stuck pods should now be Running
kubectl get pods --all-namespaces | grep ContainerCreating
# Should be empty

# Verify CNI config was created
ls /etc/cni/net.d/
# Should now have config files
```

### 📖 Documentation

- [Install a Pod network add-on](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network)
- [Network Plugins](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)

---

<a id="s18"></a>

## Scenario 18 — Flannel Pod CIDR Mismatch

### Question

Flannel is installed but pods on different nodes cannot communicate. Flannel pods are `CrashLoopBackOff` or showing errors.

### Diagnosis

```bash
kubectl logs -n kube-flannel <flannel-pod>
```

**Error:**

```
Error registering network: failed to acquire lease:
  node "worker1" pod cidr not assigned
# OR
Backend type: vxlan ... Subnet: 10.244.0.0/24
# But kubeadm was initialized with --pod-network-cidr=192.168.0.0/16
```

```bash
# Check what pod CIDR kubeadm used
kubectl cluster-info dump | grep -m 1 cluster-cidr
# --cluster-cidr=192.168.0.0/16

# Check what Flannel expects
kubectl get cm kube-flannel-cfg -n kube-flannel -o jsonpath='{.data.net-conf\.json}'
# {"Network": "10.244.0.0/16", ...}  <-- MISMATCH
```

### Solution

```bash
kubectl edit cm kube-flannel-cfg -n kube-flannel
```

```diff
  net-conf.json: |
    {
-     "Network": "10.244.0.0/16",
+     "Network": "192.168.0.0/16",
      "Backend": {
        "Type": "vxlan"
      }
    }
```

Restart Flannel:

```bash
kubectl rollout restart daemonset kube-flannel-ds -n kube-flannel
```

### Validation

```bash
# All Flannel pods should be Running
kubectl get pods -n kube-flannel

# Test cross-node pod communication
kubectl run test-a --image=nginx --restart=Never
kubectl run test-b --image=busybox --rm -it --restart=Never \
  -- wget -qO- $(kubectl get pod test-a -o jsonpath='{.status.podIP}')
# Should return nginx welcome page

kubectl delete pod test-a
```

### 📖 Documentation

- [Flannel Configuration](https://github.com/flannel-io/flannel/blob/master/Documentation/configuration.md)
- [kubeadm init — pod-network-cidr](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#options)

---

# kubeadm & Certificate Scenarios

<a id="s19"></a>

## Scenario 19 — Cluster Upgrade (Control Plane + Worker)

### Question

Upgrade the cluster from Kubernetes v1.30.0 to v1.31.0. The control plane node and one worker node must be upgraded.

### Solution — Control Plane Upgrade

```bash
ssh controlplane

# Step 1: Upgrade kubeadm
sudo apt-get update
sudo apt-get install -y --allow-change-held-packages kubeadm=1.31.0-1.1
kubeadm version   # Verify: v1.31.0

# Step 2: Drain the control plane
kubectl drain controlplane --ignore-daemonsets --delete-emptydir-data

# Step 3: Plan and apply the upgrade
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.31.0

# Step 4: Upgrade kubelet and kubectl
sudo apt-get install -y --allow-change-held-packages \
  kubelet=1.31.0-1.1 kubectl=1.31.0-1.1

# Step 5: Restart kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Step 6: Uncordon the node
kubectl uncordon controlplane

# Verify
kubectl get nodes
# controlplane: Ready, v1.31.0
```

### Solution — Worker Node Upgrade

```bash
# From control plane: drain the worker
kubectl drain worker-node1 --ignore-daemonsets --delete-emptydir-data

# SSH into the worker
ssh worker-node1

# Step 1: Upgrade kubeadm
sudo apt-get update
sudo apt-get install -y --allow-change-held-packages kubeadm=1.31.0-1.1

# Step 2: Upgrade node config
sudo kubeadm upgrade node

# Step 3: Upgrade kubelet and kubectl
sudo apt-get install -y --allow-change-held-packages \
  kubelet=1.31.0-1.1 kubectl=1.31.0-1.1

# Step 4: Restart kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Step 5: From control plane — uncordon
exit
kubectl uncordon worker-node1
```

### Validation

```bash
kubectl get nodes
# All nodes: Ready, v1.31.0

kubectl get pods -n kube-system
# All control plane pods Running
```

> **Key Differences:**
>
> - Control plane: `kubeadm upgrade apply v1.31.0`
> - Worker nodes: `kubeadm upgrade node`

### 📖 Documentation

- [Upgrading kubeadm clusters](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)

---

<a id="s20"></a>

## Scenario 20 — Certificate Renewal

### Question

Check certificate expiry dates for the cluster. Identify any expired or soon-to-expire certificates and renew them.

### Solution

#### Step 1 — Check current certificate status

```bash
ssh controlplane

kubeadm certs check-expiration
```

Output shows each certificate, its expiry date, and whether it's CA-managed.

#### Step 2 — Check individual certificate details with OpenSSL

```bash
# API Server certificate
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 2 "Validity"

# Check Issuer (who signed it)
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep "Issuer"

# Check SANs (Subject Alternative Names)
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 1 "Subject Alternative Name"

# Kubelet client certificate
openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -text -noout | grep -A 2 "Validity"

# Kubelet server certificate
openssl x509 -in /var/lib/kubelet/pki/kubelet.crt -text -noout | grep -A 2 "Validity"
```

#### Step 3 — Renew certificates

```bash
# Renew a specific certificate
kubeadm certs renew apiserver

# OR renew ALL certificates
kubeadm certs renew all
```

#### Step 4 — Restart control plane components

```bash
# Move manifests out and back to force restart
cd /etc/kubernetes/manifests/
mv kube-apiserver.yaml /tmp/ && sleep 5 && mv /tmp/kube-apiserver.yaml .
mv kube-controller-manager.yaml /tmp/ && sleep 5 && mv /tmp/kube-controller-manager.yaml .
mv kube-scheduler.yaml /tmp/ && sleep 5 && mv /tmp/kube-scheduler.yaml .

# Also update admin kubeconfig
kubeadm certs renew admin.conf
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

### Validation

```bash
kubeadm certs check-expiration
# All certificates should show future expiry dates

kubectl get nodes
kubectl get pods -n kube-system
```

### 📖 Documentation

- [Certificate Management with kubeadm](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)
- [PKI certificates](https://kubernetes.io/docs/setup/best-practices/certificates/)

---

<a id="s21"></a>

## Scenario 21 — Join Token Expired — Adding a Worker Node

### Question

You need to add a new worker node to the cluster. The original `kubeadm join` command fails because the token has expired.

### Diagnosis

On the new node:

```bash
kubeadm join <control-plane-ip>:6443 --token <old-token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

**Error:**

```
error execution phase preflight: couldn't validate the identity of the API Server:
  could not find a JWS signature in the cluster-info ConfigMap...
  token may have expired
```

### Solution

#### Step 1 — Generate a new join command from the control plane

```bash
ssh controlplane

# Create a new token with the full join command
kubeadm token create --print-join-command
```

This outputs something like:

```
kubeadm join 192.168.1.10:6443 --token abcdef.0123456789abcdef \
  --discovery-token-ca-cert-hash sha256:abc123...
```

#### Step 2 — (If node was previously joined) Reset the node first

```bash
ssh new-worker

# Clear any previous state
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo iptables -F && sudo iptables -t nat -F

# Run the join command from Step 1
sudo kubeadm join 192.168.1.10:6443 --token abcdef.0123456789abcdef \
  --discovery-token-ca-cert-hash sha256:abc123...
```

#### Step 3 — Manually compute the CA hash (if needed)

```bash
# On the control plane
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
  openssl rsa -pubin -outform der 2>/dev/null | \
  openssl dgst -sha256 -hex | sed 's/^.* //'
```

### Validation

```bash
# From control plane
kubectl get nodes
# new-worker: Ready

# Check the node's kubelet
ssh new-worker
systemctl status kubelet
# Active: running
```

### 📖 Documentation

- [kubeadm join](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-join/)
- [kubeadm token](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-token/)

---

# Application Failure Scenarios

_(Sourced from CKA Study Companion — Chapter 21)_

<a id="s22"></a>

## Scenario 22 — ImagePullBackOff / ErrImagePull

### Question

A pod is stuck in `ImagePullBackOff` (or `ErrImagePull`). The application is not starting. Investigate and fix.

### Diagnosis

```bash
# Check pod status
kubectl get pod <pod-name> -n <namespace>
# STATUS: ImagePullBackOff or ErrImagePull

# Get detailed events
kubectl describe pod <pod-name> -n <namespace>
```

**Events you will see:**

```
Warning  Failed   Failed to pull image "nginx:latestt":
  rpc error: code = Unknown desc = Error response from daemon:
  manifest for nginx:latestt not found: manifest unknown
```

**Common Causes:**

- Typo in image name or tag
- Image does not exist in the registry
- Private registry without `imagePullSecrets`
- Network connectivity issue to registry

### Solution

**Cause 1 — Typo in image name/tag:**

```bash
kubectl edit pod <pod-name> -n <namespace>
# OR edit the deployment/manifest
```

```diff
spec:
  containers:
  - name: nginx
-   image: nginx:latestt   # Typo
+   image: nginx:latest    # Corrected
```

> **Note:** You cannot edit the image of a running pod directly. Delete and recreate, or edit the Deployment.

**Cause 2 — Private registry without imagePullSecrets:**

```bash
# Create the docker registry secret
kubectl create secret docker-registry regcred \
  --docker-server=private-registry.io \
  --docker-username=<user> \
  --docker-password=<password> \
  -n <namespace>
```

Then add to the pod spec:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-app
spec:
  containers:
    - name: app
      image: private-registry.io/app:v1
  imagePullSecrets:
    - name: regcred
```

### Validation

```bash
kubectl get pod <pod-name> -n <namespace>
# STATUS: Running

kubectl describe pod <pod-name> -n <namespace> | grep -A 3 "Events"
# Successfully pulled image
```

### 📖 Documentation

- [Images](https://kubernetes.io/docs/concepts/containers/images/)
- [Pull an Image from a Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)

---

<a id="s23"></a>

## Scenario 23 — CrashLoopBackOff — Probes & Resource Tuning

### Question

A pod is in `CrashLoopBackOff`. It starts, runs for a few seconds, then crashes repeatedly. The RESTARTS counter is incrementing rapidly. Investigate and fix.

### Diagnosis

```bash
# Check pod status and restart count
kubectl get pod <pod-name> -n <namespace>
# STATUS: CrashLoopBackOff, RESTARTS: 12

# Check current container logs
kubectl logs <pod-name> -n <namespace>

# Check PREVIOUS container's logs (the crashed instance)
kubectl logs <pod-name> -n <namespace> --previous

# Check events and exit codes
kubectl describe pod <pod-name> -n <namespace>
```

Look for the **Last State** section:

```
Last State:  Terminated
  Reason:    Error
  Exit Code: 1     # Application error
  # OR
  Exit Code: 137   # OOMKilled (see Scenario 24)
  # OR
  Exit Code: 143   # SIGTERM (graceful shutdown)
```

**Common Causes:**

- Application crashes on startup (config error, missing dependency)
- Liveness probe failing too early before the app is ready
- Insufficient resources (CPU/memory)
- Missing ConfigMap/Secret referenced by the pod

### Solution

**Cause 1 — Liveness probe too aggressive (app takes time to start):**

Add a `startupProbe` or increase `initialDelaySeconds`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
    - name: app
      image: app:v1
      # Startup probe — gives the app time to initialize
      startupProbe:
        httpGet:
          path: /healthz
          port: 8080
        failureThreshold: 30
        periodSeconds: 10
      # Liveness probe — only runs after startup probe passes
      livenessProbe:
        httpGet:
          path: /healthz
          port: 8080
        initialDelaySeconds: 5
        periodSeconds: 10
      # Readiness probe — controls traffic routing
      readinessProbe:
        httpGet:
          path: /ready
          port: 8080
        initialDelaySeconds: 5
        periodSeconds: 10
```

**Cause 2 — Missing resource limits causing throttling:**

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "128Mi"
    cpu: "500m"
```

**Cause 3 — Missing ConfigMap or Secret:**

```bash
# Check events for the missing reference
kubectl describe pod <pod-name> | grep -i "configmap\|secret"

# Create the missing resource
kubectl create configmap <name> --from-literal=key=value -n <namespace>
# OR
kubectl create secret generic <name> --from-literal=key=value -n <namespace>
```

### Validation

```bash
kubectl get pod <pod-name> -n <namespace>
# STATUS: Running, RESTARTS should stop increasing

kubectl logs <pod-name> -n <namespace>
# No error messages
```

### 📖 Documentation

- [Configure Liveness, Readiness, and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Debugging Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/)

---

<a id="s24"></a>

## Scenario 24 — OOMKilled — Container Terminated (Exit Code 137)

### Question

A pod keeps getting killed with exit code `137` and reason `OOMKilled`. The application runs for a while, then gets terminated. Investigate and fix.

### Diagnosis

```bash
# Check pod status
kubectl get pod <pod-name> -n <namespace>
# STATUS: CrashLoopBackOff or OOMKilled

# Check the termination reason
kubectl describe pod <pod-name> -n <namespace>
```

**Key output:**

```
Last State:  Terminated
  Reason:    OOMKilled
  Exit Code: 137
```

```bash
# Check current memory usage vs limits
kubectl top pod <pod-name> -n <namespace>

# Check events
kubectl get events --field-selector involvedObject.name=<pod-name> -n <namespace>
# Event: Container was killed due to OOM. Memory cgroup usage exceeded memory limit.

# On the node — check kernel OOM messages
ssh <node>
dmesg -T | grep -i oom
```

### Solution

**Step 1 — Increase memory limits based on actual usage:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-demo
spec:
  containers:
    - name: app
      image: app:v1
      resources:
        requests:
          memory: "256Mi" # Based on observed usage from kubectl top
        limits:
          memory: "512Mi" # Set ~2x requests for headroom
```

**Step 2 — For Java applications, also set JVM heap limits:**

```yaml
spec:
  containers:
    - name: java-app
      image: java-app:v1
      env:
        - name: JAVA_OPTS
          value: "-Xms256m -Xmx384m" # Max heap < container memory limit
      resources:
        requests:
          memory: "512Mi" # Always > JVM max heap
        limits:
          memory: "768Mi" # Headroom for non-heap + overhead
```

> **Exam Tip:** Always check `kubectl top pod` first to understand actual usage before adjusting limits. Set limits with at least 20-30% headroom above observed usage.

### Validation

```bash
kubectl get pod <pod-name> -n <namespace>
# STATUS: Running (no OOMKilled)

kubectl top pod <pod-name> -n <namespace>
# Memory usage should be well below the limit

# Monitor for a few minutes to confirm stability
watch kubectl get pod <pod-name> -n <namespace>
```

### 📖 Documentation

- [Assign Memory Resources to Containers](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/)
- [Resource Management for Pods](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

---

<a id="s25"></a>

## Scenario 25 — Pods Stuck in Pending — Scheduling Constraints

### Question

A pod is stuck in `Pending` state and never gets scheduled to any node. There are no logs to check. Investigate and fix.

### Diagnosis

```bash
# Check pod status
kubectl get pod <pod-name> -n <namespace>
# STATUS: Pending

# IMPORTANT: Logs will NOT be available since the pod was never scheduled
# Check events instead
kubectl describe pod <pod-name> -n <namespace>
```

**Common event messages:**

```
# Insufficient resources
Warning  FailedScheduling  0/3 nodes are available:
  1 Insufficient cpu, 2 Insufficient memory

# Node selector doesn't match any node
Warning  FailedScheduling  0/3 nodes are available:
  3 node(s) didn't match Pod's node affinity/selector

# Taint not tolerated
Warning  FailedScheduling  0/3 nodes are available:
  3 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }

# PVC not bound
Warning  FailedScheduling  0/3 nodes are available:
  persistentvolumeclaim "data-pvc" not found
```

```bash
# Check cluster resource availability
kubectl describe nodes | grep -A 5 "Allocated resources"

# Check node labels (for nodeSelector issues)
kubectl get nodes --show-labels

# Check node taints
kubectl describe nodes | grep -A 2 "Taints"

# Check PVC status (if applicable)
kubectl get pvc -n <namespace>
```

### Solution

**Cause 1 — Insufficient resources:**

Reduce the pod's resource requests:

```diff
    resources:
      requests:
-       memory: "8Gi"     # Too high for available nodes
+       memory: "1Gi"     # Reduced to fit
-       cpu: "4"
+       cpu: "500m"
```

**Cause 2 — nodeSelector doesn't match:**

```bash
# Check what label the pod requires
kubectl get pod <pod-name> -o jsonpath='{.spec.nodeSelector}'
# {"disktype":"ssd"}

# Add the label to a node
kubectl label node worker-node1 disktype=ssd
```

**Cause 3 — Taint not tolerated:**

```bash
# Option A: Remove the taint from the node
kubectl taint nodes worker-node1 key=value:NoSchedule-

# Option B: Add a toleration to the pod spec
```

```yaml
spec:
  tolerations:
    - key: "key"
      operator: "Equal"
      value: "value"
      effect: "NoSchedule"
```

**Cause 4 — PVC not bound:**

```bash
# Check PVC status
kubectl get pvc data-pvc -n <namespace>
# Pending — no matching PV

# Create a matching PV or fix the StorageClass
kubectl get sc  # Check available storage classes
```

### Validation

```bash
kubectl get pod <pod-name> -n <namespace>
# STATUS: Running (or ContainerCreating → Running)

kubectl get pod <pod-name> -o wide
# Should show a NODE assignment
```

### 📖 Documentation

- [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

---

# Networking & Service Scenarios

_(Sourced from CKA Study Companion — Chapters 16 & 21)_

<a id="s26"></a>

## Scenario 26 — Service Selector Mismatch — No Endpoints

### Question

A service exists but no traffic reaches the backend pods. The service returns no response or times out. Investigate and fix.

### Diagnosis

```bash
# Check the service
kubectl get svc <service-name> -n <namespace>
# ClusterIP exists, ports look correct

# Check endpoints — THIS IS THE KEY STEP
kubectl get endpoints <service-name> -n <namespace>
# ENDPOINTS: <none>   ← No pods matched!

# Compare service selectors with pod labels
kubectl get svc <service-name> -n <namespace> -o jsonpath='{.spec.selector}'
# {"app":"myapp","tier":"frontend"}

kubectl get pods -n <namespace> --show-labels
# Labels on pods: app=myapp   ← Missing "tier=frontend" label!
```

**Root Cause:** The service selector includes labels that don't exist on the target pods. ALL selector labels must match.

### Solution

**Option A — Fix the pod labels to match the service:**

```bash
kubectl label pod <pod-name> tier=frontend -n <namespace>
```

**Option B — Fix the service selector to match the pods:**

```bash
kubectl edit svc <service-name> -n <namespace>
```

```diff
spec:
  selector:
    app: myapp
-   tier: frontend    # Remove extra selector
```

**Option C — Fix both to be consistent (recommended):**

```yaml
# Service
apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  selector:
    app: myapp # Must match pod labels
  ports:
    - port: 80
      targetPort: 8080
---
# Deployment / Pod
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  labels:
    app: myapp # Must match service selector
spec:
  containers:
    - name: app
      image: app:v1
      ports:
        - containerPort: 8080
```

> **Exam Tip:** Also check `targetPort` in the service matches the actual `containerPort` the application listens on.

### Validation

```bash
# Endpoints should now have pod IPs
kubectl get endpoints <service-name> -n <namespace>
# ENDPOINTS: 10.244.1.5:8080,10.244.2.3:8080

# Test connectivity
kubectl run curl-test --image=busybox --rm -it --restart=Never \
  -- wget -qO- <service-name>.<namespace>.svc.cluster.local
# Should return app response
```

### 📖 Documentation

- [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Debugging Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)

---

<a id="s27"></a>

## Scenario 27 — NetworkPolicy Blocking Inter-Pod Traffic

### Question

Pods can ping external addresses but cannot communicate with other pods or services within the cluster. A `connection refused` or `timeout` error occurs when curling between pods. Investigate and fix.

### Diagnosis

```bash
# Test connectivity from a pod
kubectl exec -it <source-pod> -n <namespace> -- curl <service-name>
# curl: (7) Failed to connect: Connection refused

# Check if NetworkPolicies exist in the namespace
kubectl get networkpolicy -n <namespace>

# Inspect the NetworkPolicy
kubectl describe networkpolicy <policy-name> -n <namespace>
```

**Root Cause:** A `NetworkPolicy` exists that restricts ingress to the target pods. Only pods matching the specified `podSelector` / `namespaceSelector` labels are allowed.

### Solution

**Step 1 — Understand the blocking policy:**

```bash
kubectl get networkpolicy <policy-name> -n <namespace> -o yaml
```

**Step 2 — Add a rule to allow traffic from the source pods:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-traffic
  namespace: <namespace>
spec:
  podSelector:
    matchLabels:
      app: backend # Target pods this policy applies to
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: frontend # Allow traffic from frontend pods
      ports:
        - protocol: TCP
          port: 80
```

**Step 3 — If you need to allow traffic from a different namespace:**

```yaml
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            name: production # Allow from the 'production' namespace
        podSelector:
          matchLabels:
            role: frontend
```

> **Exam Tip:** Remember that once ANY `NetworkPolicy` selects a pod, all traffic not explicitly allowed is **denied** by default. If you're troubleshooting, check ALL policies in the namespace.

### Validation

```bash
# Test connectivity again
kubectl exec -it <source-pod> -n <namespace> -- curl <service-name>
# Should succeed now

# Ensure the source pod has the correct labels
kubectl get pod <source-pod> -n <namespace> --show-labels
```

### 📖 Documentation

- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Declare Network Policy](https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/)

---

<a id="s28"></a>

## Scenario 28 — Ingress Misconfiguration — 404 / 502 Errors

### Question

An Ingress resource is configured, but accessing the application through the Ingress URL returns `404 Not Found` or `502 Bad Gateway`. Investigate and fix.

### Diagnosis

```bash
# Check the Ingress resource
kubectl get ingress -n <namespace>
kubectl describe ingress <ingress-name> -n <namespace>

# Check if the Ingress controller is running
kubectl get pods -n ingress-nginx
# All pods should be Running

# Check Ingress controller logs
kubectl logs -n ingress-nginx <ingress-controller-pod>

# Check the backend service and endpoints
kubectl get svc <backend-service> -n <namespace>
kubectl get endpoints <backend-service> -n <namespace>
```

**Common Causes:**

- Backend service does not exist or has wrong name
- Service port in Ingress doesn't match the actual service port
- No Ingress controller installed in the cluster
- Backend pods are not running (0 endpoints)
- `ingressClassName` missing or incorrect

### Solution

**Cause 1 — Service name or port mismatch:**

```bash
kubectl edit ingress <ingress-name> -n <namespace>
```

```diff
spec:
  ingressClassName: nginx       # Must match installed controller
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
-           name: wrong-svc-name    # Typo
+           name: app-service       # Correct service name
            port:
-             number: 8080          # Wrong port
+             number: 80            # Must match service port (not containerPort)
```

**Cause 2 — No Ingress controller installed:**

```bash
# Check if any Ingress controller exists
kubectl get pods -A | grep ingress
# Empty — no controller

# Install nginx Ingress controller
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# OR use kubectl
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml
```

**Cause 3 — Missing `ingressClassName`:**

```bash
# Check available IngressClasses
kubectl get ingressclass

# Add the correct class to the Ingress
kubectl edit ingress <ingress-name> -n <namespace>
```

```diff
spec:
+ ingressClassName: nginx
  rules:
```

### Validation

```bash
# Check Ingress has an address assigned
kubectl get ingress -n <namespace>
# ADDRESS column should have an IP or hostname

# Test from a pod within the cluster
kubectl run curl-test --image=busybox --rm -it --restart=Never \
  -- wget -qO- --header="Host: example.com" http://<ingress-ip>

# Check Ingress controller logs for successful routing
kubectl logs -n ingress-nginx <ingress-controller-pod> | tail -10
```

### 📖 Documentation

- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)

---

# Kubeconfig & Webhook Scenarios

_(Sourced from CKA Study Companion — Chapters 17 & 22)_

<a id="s29"></a>

## Scenario 29 — Corrupted Kubeconfig — Connection Refused

### Question

All `kubectl` commands fail with a connection error. The API server is confirmed running via `crictl`. The issue is with the kubeconfig file. Fix it.

### Diagnosis

```bash
ssh controlplane

# Verify the API server is actually running
crictl ps | grep kube-apiserver
# Running ← API server is fine

# But kubectl still fails
kubectl get nodes
# The connection to the server localhost:8080 was refused
# OR
# Unable to connect to the server: x509: certificate signed by unknown authority

# Inspect the kubeconfig
cat ~/.kube/config
# File may be empty, corrupted, or pointing to wrong server/certs
```

**Common Causes:**

- `~/.kube/config` was accidentally overwritten or deleted
- `KUBECONFIG` environment variable points to wrong file
- Server URL in kubeconfig is incorrect
- Certificate data in kubeconfig is corrupted

### Solution

**Step 1 — Try the default admin kubeconfig:**

```bash
# Test with the original admin.conf
kubectl get nodes --kubeconfig /etc/kubernetes/admin.conf
# If this works, the issue is with ~/.kube/config
```

**Step 2 — Replace the corrupted kubeconfig:**

```bash
# Copy the default kubeconfig
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

**Step 3 — If `KUBECONFIG` env var is the issue:**

```bash
# Check if KUBECONFIG is set to something wrong
echo $KUBECONFIG

# Unset or fix it
unset KUBECONFIG
# OR
export KUBECONFIG=/etc/kubernetes/admin.conf
```

### Validation

```bash
kubectl get nodes
# Should return node list

kubectl cluster-info
# Shows: Kubernetes control plane is running at https://<ip>:6443
```

### 📖 Documentation

- [Configure Access to Multiple Clusters](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)
- [Organizing Cluster Access Using kubeconfig](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)

---

<a id="s30"></a>

## Scenario 30 — Admission Webhook Failure — API Slowness / Rejections

### Question

Creating new resources (pods, deployments) fails with webhook-related errors, or `kubectl` operations are extremely slow. Investigate and fix.

### Diagnosis

```bash
# Try creating a pod
kubectl run test --image=nginx
# Error from server (InternalError): Internal error occurred:
#   failed calling webhook "validate.example.com":
#   Post "https://example-service.example-ns.svc:443/validate":
#   no endpoints available for service "example-service"

# List all webhook configurations
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations

# Inspect the failing webhook
kubectl describe validatingwebhookconfigurations <webhook-name>
```

**Common Causes:**

- Webhook service has no running pods (endpoints)
- Webhook service does not exist
- Webhook pod is CrashLoopBackOff
- Firewall blocking traffic from API server to webhook pods
- `failurePolicy: Fail` causes hard failures when webhook is unreachable

### Solution

**Cause 1 — Webhook pods not running:**

```bash
# Check the webhook service and its backing pods
kubectl get svc example-service -n example-namespace
kubectl get endpoints example-service -n example-namespace
# ENDPOINTS: <none>

# Check the deployment behind the service
kubectl get deploy -n example-namespace
kubectl get pods -n example-namespace
# Fix the deployment (e.g., fix image, resource issues)
```

**Cause 2 — Webhook is no longer needed — delete it:**

```bash
# If the webhook was left behind after uninstalling a tool
kubectl delete validatingwebhookconfigurations <webhook-name>
# OR
kubectl delete mutatingwebhookconfigurations <webhook-name>
```

**Cause 3 — Change failure policy to `Ignore` (temporary fix):**

```bash
kubectl edit validatingwebhookconfigurations <webhook-name>
```

```diff
webhooks:
- name: "validate.example.com"
- failurePolicy: Fail
+ failurePolicy: Ignore     # Temporary — allows requests when webhook is down
```

> **Warning:** Setting `failurePolicy: Ignore` should only be a temporary measure. Fix the underlying webhook issue or remove the webhook entirely.

### Validation

```bash
# Test creating resources
kubectl run test-webhook --image=nginx --restart=Never
kubectl get pod test-webhook
# Should be created successfully

# Verify API server response time is normal
time kubectl get nodes
# Should complete in < 1 second

# Clean up
kubectl delete pod test-webhook
```

### 📖 Documentation

- [Dynamic Admission Control](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)
- [Admission Controllers Reference](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)

---

## Quick Reference — Key Diagnostic Commands

### kubectl

| Action                         | Command                                                         |
| ------------------------------ | --------------------------------------------------------------- |
| List all kube-system pods      | `kubectl get pods -n kube-system`                               |
| Describe a pod (events/status) | `kubectl describe pod <name> -n kube-system`                    |
| View current logs              | `kubectl logs <pod> -n kube-system`                             |
| View previous container logs   | `kubectl logs <pod> -n kube-system --previous`                  |
| Follow logs in real-time       | `kubectl logs -f <pod> -n kube-system`                          |
| Get events sorted by time      | `kubectl get events -n kube-system --sort-by='.lastTimestamp'`  |
| Events for specific object     | `kubectl get events --field-selector involvedObject.name=<pod>` |
| Check node conditions          | `kubectl describe node <name> \| grep -A 10 Conditions`         |
| Get all resources              | `kubectl get all --all-namespaces`                              |
| CSR status                     | `kubectl get csr`                                               |
| Leader election leases         | `kubectl get lease -n kube-system`                              |

### systemctl / journalctl (host-level)

| Action                           | Command                                   |
| -------------------------------- | ----------------------------------------- |
| Check kubelet status             | `systemctl status kubelet`                |
| Restart kubelet                  | `systemctl restart kubelet`               |
| Reload systemd after config edit | `systemctl daemon-reload`                 |
| View kubelet logs                | `journalctl -u kubelet -f`                |
| Filter kubelet errors            | `journalctl -u kubelet -p err --no-pager` |
| Check containerd status          | `systemctl status containerd`             |
| Kernel OOM messages              | `dmesg -T \| grep -i oom`                 |

### crictl (when API server is down)

| Action              | Command                         |
| ------------------- | ------------------------------- |
| List all containers | `crictl ps -a`                  |
| List pods           | `crictl pods`                   |
| Container logs      | `crictl logs <container-id>`    |
| Inspect container   | `crictl inspect <container-id>` |
| List images         | `crictl images`                 |

### etcdctl

| Action           | Command                                                                                              |
| ---------------- | ---------------------------------------------------------------------------------------------------- |
| Health check     | `etcdctl endpoint health --endpoints=https://127.0.0.1:2379 --cacert=<ca> --cert=<cert> --key=<key>` |
| Member list      | `etcdctl member list --endpoints=... --cacert=<ca> --cert=<cert> --key=<key>`                        |
| Database status  | `etcdctl endpoint status --write-out=table --endpoints=... --cacert=<ca> --cert=<cert> --key=<key>`  |
| Snapshot save    | `etcdctl snapshot save /path/backup.db --endpoints=... --cacert=<ca> --cert=<cert> --key=<key>`      |
| Snapshot restore | `etcdctl snapshot restore /path/backup.db --data-dir=/new/dir`                                       |
| Alarm list       | `etcdctl alarm list --endpoints=... --cacert=<ca> --cert=<cert> --key=<key>`                         |
| Defrag           | `etcdctl defrag --endpoints=... --cacert=<ca> --cert=<cert> --key=<key>`                             |

### kubeadm

| Action                   | Command                                     |
| ------------------------ | ------------------------------------------- |
| Check certificate expiry | `kubeadm certs check-expiration`            |
| Renew all certificates   | `kubeadm certs renew all`                   |
| Renew API server cert    | `kubeadm certs renew apiserver`             |
| Generate join command    | `kubeadm token create --print-join-command` |
| List tokens              | `kubeadm token list`                        |
| Upgrade plan             | `kubeadm upgrade plan`                      |
| Upgrade apply            | `kubeadm upgrade apply v<version>`          |
| Upgrade worker node      | `kubeadm upgrade node`                      |
| Reset node               | `kubeadm reset -f`                          |

### openssl (Certificate Inspection)

| Action                | Command                                                                                                       |
| --------------------- | ------------------------------------------------------------------------------------------------------------- |
| View cert details     | `openssl x509 -in <cert.crt> -text -noout`                                                                    |
| Check validity period | `openssl x509 -in <cert.crt> -text -noout \| grep -A 2 Validity`                                              |
| Check SANs            | `openssl x509 -in <cert.crt> -text -noout \| grep -A 1 "Subject Alternative"`                                 |
| Check issuer          | `openssl x509 -in <cert.crt> -text -noout \| grep Issuer`                                                     |
| Compute CA hash       | `openssl x509 -pubkey -in ca.crt \| openssl rsa -pubin -outform der 2>/dev/null \| openssl dgst -sha256 -hex` |

---

## Key File Locations Reference

| File / Directory                         | Purpose                                      |
| ---------------------------------------- | -------------------------------------------- |
| `/etc/kubernetes/manifests/`             | Static pod manifests (apiserver, etcd, etc.) |
| `/etc/kubernetes/pki/`                   | Cluster certificates and keys                |
| `/etc/kubernetes/pki/etcd/`              | etcd-specific certificates                   |
| `/etc/kubernetes/*.conf`                 | Kubeconfig files for components              |
| `/var/lib/kubelet/config.yaml`           | Kubelet configuration                        |
| `/var/lib/etcd/`                         | etcd data directory                          |
| `/etc/cni/net.d/`                        | CNI plugin configuration                     |
| `/opt/cni/bin/`                          | CNI plugin binaries                          |
| `/etc/systemd/system/kubelet.service.d/` | Kubelet systemd drop-in configs              |
| `/var/log/pods/`                         | Pod logs on disk                             |
| `~/.kube/config`                         | kubectl kubeconfig                           |

---

## Common Error → Root Cause Quick Reference

| Error Message / Symptom              | Root Cause                         | Fix                                            |
| ------------------------------------ | ---------------------------------- | ---------------------------------------------- |
| `connection refused :6443`           | API server down                    | Check static pod manifest                      |
| `x509: certificate has expired`      | Expired certs                      | `kubeadm certs renew all`                      |
| `x509: signed by unknown authority`  | Wrong CA / kubeconfig              | Verify CA cert path                            |
| `dial tcp :2379 connection refused`  | etcd down or wrong port            | Check etcd manifest                            |
| `mvcc: database space exceeded`      | etcd full                          | Compact + defrag + disarm alarm                |
| `OOMKilled` (Exit code 137)          | Memory limit too low               | Increase `resources.limits.memory`             |
| `CrashLoopBackOff`                   | App or config error                | `kubectl logs --previous`                      |
| `Pending` (no node assigned)         | Scheduler issue or constraints     | Check scheduler, taints, resources             |
| `ContainerCreating` (stuck)          | CNI not installed / configured     | Install CNI plugin                             |
| `NetworkPluginNotReady`              | Missing CNI                        | Install Calico/Flannel                         |
| `PLEG is not healthy`                | Container runtime unresponsive     | Restart containerd, check I/O                  |
| `failed to run Kubelet: swap on`     | Swap enabled                       | `swapoff -a`                                   |
| `leader election lost`               | API server connectivity or latency | Fix API server first                           |
| `no such file or directory (binary)` | Wrong path in systemd unit         | Fix ExecStart path, daemon-reload              |
| `ImagePullBackOff` / `ErrImagePull`  | Wrong image name/tag or no secrets | Fix image, add `imagePullSecrets`              |
| Service has `<none>` endpoints       | Selector mismatch                  | Align service selectors & pod labels           |
| Ingress returns `502 Bad Gateway`    | Backend svc/pod down or wrong port | Check svc, endpoints, ingressClass             |
| `failed calling webhook`             | Webhook svc/pod unavailable        | Fix webhook pod or delete webhook              |
| `localhost:8080 was refused`         | Missing/corrupted kubeconfig       | `cp /etc/kubernetes/admin.conf ~/.kube/config` |

---
