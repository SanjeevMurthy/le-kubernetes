# CKA Simulator 2 - Complete Study Guide

> [!NOTE]
> This is a comprehensive study guide for the CKA (Certified Kubernetes Administrator) exam based on the Killer.sh Simulator Session 2. Each question includes detailed context, step-by-step solutions, validation steps, and official documentation links.

---

## Table of Contents

1. [Question 1: DNS / FQDN / Headless Service](#question-1-dns--fqdn--headless-service)
2. [Question 2: Create a Static Pod and Service](#question-2-create-a-static-pod-and-service)
3. [Question 3: Kubelet Client/Server Cert Info](#question-3-kubelet-clientserver-cert-info)
4. [Question 4: Pod Ready if Service is Reachable](#question-4-pod-ready-if-service-is-reachable)
5. [Question 5: Kubectl Sorting](#question-5-kubectl-sorting)
6. [Question 6: Fix Kubelet](#question-6-fix-kubelet)
7. [Question 7: Etcd Operations](#question-7-etcd-operations)
8. [Question 8: Get Controlplane Information](#question-8-get-controlplane-information)
9. [Question 9: Kill Scheduler, Manual Scheduling](#question-9-kill-scheduler-manual-scheduling)
10. [Question 10: PV PVC Dynamic Provisioning](#question-10-pv-pvc-dynamic-provisioning)
11. [Question 11: Create Secret and Mount into Pod](#question-11-create-secret-and-mount-into-pod)
12. [Question 12: Schedule Pod on Controlplane Nodes](#question-12-schedule-pod-on-controlplane-nodes)
13. [Question 13: Multi Containers and Pod Shared Volume](#question-13-multi-containers-and-pod-shared-volume)
14. [Question 14: Find out Cluster Information](#question-14-find-out-cluster-information)
15. [Question 15: Cluster Event Logging](#question-15-cluster-event-logging)
16. [Question 16: Namespaces and Api Resources](#question-16-namespaces-and-api-resources)
17. [Question 17: Operator, CRDs, RBAC, Kustomize](#question-17-operator-crds-rbac-kustomize)

---

## Question 1: DNS / FQDN / Headless Service

### Context

**What is being tested:** Understanding of Kubernetes internal DNS resolution including Services, Headless Services, Pod DNS entries, and IP-based Pod DNS records.

**Why this matters:** DNS is the backbone of service discovery in Kubernetes. Understanding how different resource types resolve via DNS is critical for debugging networking issues and configuring inter-service communication.

**Key DNS Patterns:**

| Resource Type                        | FQDN Pattern                                   |
| ------------------------------------ | ---------------------------------------------- |
| Service                              | `SERVICE.NAMESPACE.svc.cluster.local`          |
| Headless Service                     | Same pattern, but resolves to Pod IPs directly |
| Pod via Service (hostname+subdomain) | `HOSTNAME.SERVICE.NAMESPACE.svc.cluster.local` |
| Pod via IP                           | `A-B-C-D.NAMESPACE.pod.cluster.local`          |

**Task Summary:** Update a ConfigMap used by a Deployment with correct FQDN values for various DNS scenarios.

> [!IMPORTANT]
> **Solve this question on:** `ssh cka6016`

### Solution

#### Step 1: Identify the Deployment and exec into a Pod for testing

```bash
ssh cka6016

# Check existing pods
k -n lima-control get pod

# Exec into a Pod to test DNS resolution
k -n lima-control exec -it <pod-name> -- sh
```

#### Step 2: Resolve DNS_1 — Service `kubernetes` in Namespace `default`

```bash
# Inside the pod
nslookup kubernetes.default.svc.cluster.local
# Resolves to: 10.96.0.1
```

**Answer:** `kubernetes.default.svc.cluster.local`

#### Step 3: Resolve DNS_2 — Headless Service `department` in Namespace `lima-workload`

```bash
nslookup department.lima-workload.svc.cluster.local
# Returns multiple Pod IP addresses (headless = no ClusterIP, resolves to Pod IPs)
```

**Answer:** `department.lima-workload.svc.cluster.local`

> [!TIP]
> A **headless service** has `clusterIP: None`. It doesn't get its own IP but resolves to the IPs of its Pods. Verify with:
>
> ```bash
> k -n lima-workload get svc department
> # CLUSTER-IP should show "None"
> ```

#### Step 4: Resolve DNS_3 — Pod `section100` in Namespace `lima-workload` (stable even if Pod IP changes)

```bash
nslookup section100.section.lima-workload.svc.cluster.local
# Resolves to the Pod's IP
```

**Answer:** `section100.section.lima-workload.svc.cluster.local`

> [!NOTE]
> This works because the Pod has `hostname: section100` and `subdomain: section` set in its spec, matching the Service name `section`. This creates a stable DNS entry:
>
> ```yaml
> spec:
>   hostname: section100
>   subdomain: section # must match the Service name
> ```

#### Step 5: Resolve DNS_4 — Pod with IP `1.2.3.4` in Namespace `kube-system`

```bash
nslookup 1-2-3-4.kube-system.pod.cluster.local
# Resolves to 1.2.3.4
```

**Answer:** `1-2-3-4.kube-system.pod.cluster.local`

> [!NOTE]
> For IP-based Pod DNS, dots in the IP are replaced with dashes. This works even without an actual Pod at that IP.

#### Step 6: Update the ConfigMap and restart the Deployment

```bash
# Exit the pod
exit

# Edit the ConfigMap
k -n lima-control edit cm control-config
```

```yaml
apiVersion: v1
data:
  DNS_1: kubernetes.default.svc.cluster.local
  DNS_2: department.lima-workload.svc.cluster.local
  DNS_3: section100.section.lima-workload.svc.cluster.local
  DNS_4: 1-2-3-4.kube-system.pod.cluster.local
kind: ConfigMap
metadata:
  name: control-config
  namespace: lima-control
```

```bash
# Restart the Deployment to pick up ConfigMap changes
kubectl -n lima-control rollout restart deploy controller
```

### Validation

```bash
# Check logs to verify DNS resolution works
k -n lima-control logs -f <new-pod-name>
# All nslookup commands should resolve successfully
```

### References

- [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Headless Services](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services)
- [Pod's hostname and subdomain fields](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pods-hostname-and-subdomain-fields)

---

## Question 2: Create a Static Pod and Service

### Context

**What is being tested:** Creating static Pods via kubelet manifests directory and exposing them with a NodePort Service.

**Why this matters:** Static Pods are managed directly by the kubelet on a specific node (not by the API server). They are used for critical cluster components like `etcd`, `kube-apiserver`, etc. Understanding how to create and expose them is key for CKA.

**Task Summary:**

1. Create a Static Pod `my-static-pod` with `nginx:1-alpine` and resource requests (10m CPU, 20Mi memory)
2. Create a NodePort Service `static-pod-service` exposing port 80

> [!IMPORTANT]
> **Solve this question on:** `ssh cka2560`

### Solution

#### Step 1: Create the Static Pod manifest

```bash
ssh cka2560
sudo -i

# Navigate to static pod manifests directory
cd /etc/kubernetes/manifests/

# Generate the Pod YAML
k run my-static-pod --image=nginx:1-alpine -o yaml --dry-run=client > my-static-pod.yaml
```

#### Step 2: Edit the manifest to add resource requests

```yaml
# /etc/kubernetes/manifests/my-static-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: my-static-pod
  name: my-static-pod
spec:
  containers:
    - image: nginx:1-alpine
      name: my-static-pod
      resources:
        requests:
          cpu: 10m
          memory: 20Mi
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

#### Step 3: Verify the Static Pod is running

```bash
k get pod -A | grep my-static
# Should show: default  my-static-pod-cka2560  1/1  Running
```

#### Step 4: Create the NodePort Service

```bash
# Expose the static pod (use the full name with node suffix)
k expose pod my-static-pod-cka2560 \
  --name static-pod-service \
  --type=NodePort \
  --port 80
```

### Validation

```bash
# Check Service and Endpoints
k get svc,endpointslice -l run=my-static-pod

# Verify access via NodePort
k get node -owide  # get internal IP
curl <INTERNAL-IP>:<NODE-PORT>
# Should return nginx welcome page
```

> [!TIP]
> Static Pod names automatically get the node hostname appended as a suffix (e.g., `my-static-pod-cka2560`). When creating the Service, use this full name.

### References

- [Static Pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
- [Create a Service](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Managing Resources for Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

---

## Question 3: Kubelet Client/Server Cert Info

### Context

**What is being tested:** Understanding TLS certificate infrastructure in Kubernetes, specifically kubelet client and server certificates used for secure communication.

**Why this matters:** Kubernetes uses mutual TLS for component communication. The kubelet has separate certificates for:

- **Client cert**: Used when kubelet connects _to_ the API server (outgoing)
- **Server cert**: Used when API server connects _to_ the kubelet (incoming)

**Task Summary:** Find the Issuer and Extended Key Usage for both kubelet client and server certificates on a worker node.

> [!IMPORTANT]
> **Solve this question on:** `ssh cka5248`

### Solution

#### Step 1: Connect to the worker node and find certificates

```bash
ssh cka5248
ssh cka5248-node1
sudo -i

# List kubelet PKI files
find /var/lib/kubelet/pki
# kubelet-client-current.pem  (client cert)
# kubelet.crt                 (server cert)
# kubelet.key                 (server key)
```

#### Step 2: Inspect the Client Certificate

```bash
openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet-client-current.pem | grep Issuer
# Issuer: CN = kubernetes

openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet-client-current.pem | grep "Extended Key Usage" -A1
# X509v3 Extended Key Usage:
#     TLS Web Client Authentication
```

#### Step 3: Inspect the Server Certificate

```bash
openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet.crt | grep Issuer
# Issuer: CN = cka5248-node1-ca@<timestamp>

openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet.crt | grep "Extended Key Usage" -A1
# X509v3 Extended Key Usage:
#     TLS Web Server Authentication
```

#### Step 4: Write the solution file

```bash
cat > /opt/course/3/certificate-info.txt << 'EOF'
Issuer: CN = kubernetes
X509v3 Extended Key Usage: TLS Web Client Authentication

Issuer: CN = cka5248-node1-ca@1730211854
X509v3 Extended Key Usage: TLS Web Server Authentication
EOF
```

### Validation

```bash
cat /opt/course/3/certificate-info.txt
```

> [!TIP]
> **Key Insight:** The client certificate is issued by `kubernetes` (the cluster CA) because it's used to authenticate the kubelet to the API server. The server certificate is self-signed by the node itself (used for the kubelet's HTTPS server).

### References

- [PKI Certificates and Requirements](https://kubernetes.io/docs/setup/best-practices/certificates/)
- [TLS Bootstrapping](https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/)
- [Certificate Management with kubeadm](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)

---

## Question 4: Pod Ready if Service is Reachable

### Context

**What is being tested:** Configuring Liveness and Readiness probes, understanding Pod-to-Service communication and how probe status affects Pod readiness.

**Why this matters:** Readiness probes determine if a Pod should receive traffic. Using exec-based probes to check external service availability is an advanced pattern that demonstrates deep understanding of probe mechanics.

**Task Summary:**

1. Create Pod `ready-if-service-ready` with a LivenessProbe (`true` command) and a ReadinessProbe (checks `http://service-am-i-ready:80`)
2. Confirm it's not ready initially
3. Create Pod `am-i-ready` with label `id: cross-server-ready` so the existing Service gets an endpoint
4. Confirm first Pod becomes ready

> [!IMPORTANT]
> **Solve this question on:** `ssh cka3200`

### Solution

#### Step 1: Generate Pod YAML and add probes

```bash
ssh cka3200

k run ready-if-service-ready --image=nginx:1-alpine --dry-run=client -o yaml > 4_pod1.yaml
```

Edit the file:

```yaml
# 4_pod1.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: ready-if-service-ready
  name: ready-if-service-ready
spec:
  containers:
    - image: nginx:1-alpine
      name: ready-if-service-ready
      resources: {}
      livenessProbe:
        exec:
          command:
            - "true"
      readinessProbe:
        exec:
          command:
            - sh
            - -c
            - "wget -T2 -O- http://service-am-i-ready:80"
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

#### Step 2: Create the Pod and verify it's NOT ready

```bash
k -f 4_pod1.yaml create

k get pod ready-if-service-ready
# READY: 0/1 (not ready because service-am-i-ready has no endpoints)

k describe pod ready-if-service-ready
# Events show: Readiness probe failed
```

#### Step 3: Create the second Pod to become the Service endpoint

```bash
k run am-i-ready --image=nginx:1-alpine --labels="id=cross-server-ready"
```

#### Step 4: Verify the Service now has an endpoint

```bash
k describe svc service-am-i-ready
# Endpoints should now show the am-i-ready Pod IP
```

### Validation

```bash
# Wait ~30 seconds for the readiness probe to succeed
k get pod ready-if-service-ready
# READY: 1/1 — the Pod is now ready!
```

> [!TIP]
> The `readinessProbe.httpGet` doesn't support absolute URLs to remote services. The workaround is using `exec` with `wget` or `curl`. This is an anti-pattern but demonstrates how probes work.

### References

- [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)

---

## Question 5: Kubectl Sorting

### Context

**What is being tested:** Using `kubectl` with `--sort-by` flag to sort resource output by specific fields.

**Why this matters:** Being able to quickly sort and filter Kubernetes resources is essential for troubleshooting and monitoring. The `--sort-by` flag uses JSONPath expressions.

**Task Summary:**

1. Create script to list all Pods sorted by AGE (`metadata.creationTimestamp`)
2. Create script to list all Pods sorted by `metadata.uid`

> [!IMPORTANT]
> **Solve this question on:** `ssh cka8448`

### Solution

#### Step 1: Create the sort-by-age script

```bash
ssh cka8448

cat > /opt/course/5/find_pods.sh << 'EOF'
kubectl get pod -A --sort-by=.metadata.creationTimestamp
EOF
```

#### Step 2: Create the sort-by-uid script

```bash
cat > /opt/course/5/find_pods_uid.sh << 'EOF'
kubectl get pod -A --sort-by=.metadata.uid
EOF
```

### Validation

```bash
# Test both scripts
sh /opt/course/5/find_pods.sh
# Pods should be sorted oldest to newest

sh /opt/course/5/find_pods_uid.sh
# Pods should be sorted by UID
```

> [!TIP]
> **Useful sorting fields:**
>
> ```bash
> --sort-by=.metadata.creationTimestamp  # by age
> --sort-by=.metadata.name              # by name
> --sort-by=.metadata.uid               # by UID
> --sort-by=.status.phase               # by status
> ```

### References

- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Sorting Output](https://kubernetes.io/docs/reference/kubectl/jsonpath/)

---

## Question 6: Fix Kubelet

### Context

**What is being tested:** Troubleshooting kubelet issues — checking service status, reading logs, finding the correct binary path, and restarting the service.

**Why this matters:** The kubelet is the primary node agent. If it's not running, the node can't communicate with the API server and no Pods can be scheduled. Troubleshooting kubelet issues is a critical CKA skill.

**Task Summary:**

1. Fix the broken kubelet on controlplane node `cka1024`
2. Verify the node is in Ready state
3. Create a Pod called `success`

> [!IMPORTANT]
> **Solve this question on:** `ssh cka1024`

### Solution

#### Step 1: Investigate the issue

```bash
ssh cka1024
sudo -i

# Check node status — will fail (API server unreachable)
k get node

# Check if kubelet is running
ps aux | grep kubelet
# Only the grep process itself — kubelet is NOT running

# Check kubelet service status
service kubelet status
# Active: inactive (dead)
```

#### Step 2: Try to start kubelet and check errors

```bash
service kubelet start
service kubelet status
# Active: activating (auto-restart) — keeps crashing!

# Check the ExecStart line in status output:
# Process: ExecStart=/usr/local/bin/kubelet ...
# Exit code: 203/EXEC — binary not found!
```

#### Step 3: Find the correct kubelet binary path

```bash
# Try to run the configured binary
/usr/local/bin/kubelet
# -bash: /usr/local/bin/kubelet: No such file or directory

# Find the actual kubelet binary
whereis kubelet
# kubelet: /usr/bin/kubelet
```

#### Step 4: Fix the kubelet service configuration

```bash
vim /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
```

Change the last `ExecStart` line:

```ini
# Change FROM:
ExecStart=/usr/local/bin/kubelet $KUBELET_KUBECONFIG_ARGS ...
# Change TO:
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS
```

#### Step 5: Reload and restart

```bash
systemctl daemon-reload
service kubelet restart
service kubelet status
# Active: active (running) ✓
```

### Validation

```bash
# Wait for containers to come up
watch crictl ps

# Verify node is Ready
k get node
# STATUS: Ready

# Create the requested Pod
k run success --image nginx:1-alpine
k get pod success -o wide
# Should be Running
```

> [!TIP]
> **Troubleshooting checklist for kubelet issues:**
>
> 1. `ps aux | grep kubelet` — is it running?
> 2. `service kubelet status` — check service state and ExecStart path
> 3. `journalctl -u kubelet` — check detailed logs
> 4. Try running the binary manually to test the path
> 5. `whereis kubelet` — find the correct binary location

### References

- [Troubleshooting kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/)
- [Debugging Kubernetes Nodes](https://kubernetes.io/docs/tasks/debug/debug-cluster/)

---

## Question 7: Etcd Operations

### Context

**What is being tested:** Working with etcd — getting version info, creating snapshots, and optionally restoring from backups.

**Why this matters:** etcd is the key-value store for all cluster data. Knowing how to back up and restore etcd is critical for disaster recovery. This is a heavily tested topic on the CKA.

**Task Summary:**

1. Run `etcd --version` and store output
2. Create an etcd snapshot

> [!IMPORTANT]
> **Solve this question on:** `ssh cka2560`

### Solution

#### Step 1: Get etcd version

```bash
ssh cka2560
sudo -i

# etcd runs as a Pod, not installed directly
k -n kube-system exec etcd-cka2560 -- etcd --version

# Save output to file
k -n kube-system exec etcd-cka2560 -- etcd --version > /opt/course/7/etcd-version
```

#### Step 2: Create etcd snapshot

```bash
# First attempt without auth will hang — we need certificates
# Check the etcd manifest for certificate paths
vim /etc/kubernetes/manifests/etcd.yaml
# Look for: --cert-file, --key-file, --trusted-ca-file, --listen-client-urls

# Also check kube-apiserver manifest for etcd connection info
cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep etcd
```

#### Step 3: Run snapshot with authentication

```bash
ETCDCTL_API=3 etcdctl snapshot save /opt/course/7/etcd-snapshot.db \
  --cacert /etc/kubernetes/pki/etcd/ca.crt \
  --cert /etc/kubernetes/pki/etcd/server.crt \
  --key /etc/kubernetes/pki/etcd/server.key
```

### Validation

```bash
# Verify the snapshot file exists
ls -la /opt/course/7/etcd-snapshot.db
# Should show a file of ~2-3 MB
```

> [!WARNING]
> Do NOT use `etcdctl snapshot status` to verify — it can alter the snapshot file and render it invalid in certain etcd versions.

> [!TIP]
> **Optional: Etcd Restore Process (high-risk, can break cluster):**
>
> 1. Stop all controlplane components: `mv /etc/kubernetes/manifests/*.yaml /etc/kubernetes/`
> 2. Wait for all containers to stop: `watch crictl ps`
> 3. Restore: `ETCDCTL_API=3 etcdctl snapshot restore <snapshot> --data-dir /var/lib/etcd-snapshot --cacert ... --cert ... --key ...`
> 4. Update `etcd.yaml` hostPath to point to new data dir `/var/lib/etcd-snapshot`
> 5. Move manifests back: `mv /etc/kubernetes/*.yaml /etc/kubernetes/manifests/`
> 6. Wait for cluster to come back up

### References

- [Operating etcd Clusters](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)
- [Backing Up an etcd Cluster](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster)

---

## Question 8: Get Controlplane Information

### Context

**What is being tested:** Understanding how Kubernetes controlplane components are deployed — as processes, static Pods, or regular Pods.

**Why this matters:** Different installation methods (kubeadm, manual, managed) deploy components differently. Understanding this helps with troubleshooting and component lifecycle management.

**Task Summary:** Identify how each controlplane component is started and write findings to a file.

> [!IMPORTANT]
> **Solve this question on:** `ssh cka8448`

### Solution

#### Step 1: Check kubelet — running as a process via systemd

```bash
ssh cka8448
sudo -i

ps aux | grep kubelet
# Shows kubelet process running

service kubelet status
# Active: active (running)

find /usr/lib/systemd | grep kube
# Shows kubelet.service — confirms it's a systemd service
```

#### Step 2: Check for static Pods

```bash
find /etc/kubernetes/manifests/
# kube-controller-manager.yaml
# etcd.yaml
# kube-apiserver.yaml
# kube-scheduler.yaml
# These are ALL static pods
```

#### Step 3: Check DNS (CoreDNS)

```bash
k -n kube-system get pod -o wide
# coredns pods are visible

k -n kube-system get deploy
# coredns is managed by a Deployment — so it's a regular Pod

k -n kube-system get ds
# kube-proxy and weave-net are DaemonSets
```

#### Step 4: Write the answer

```bash
cat > /opt/course/8/controlplane-components.txt << 'EOF'
kubelet: process
kube-apiserver: static-pod
kube-scheduler: static-pod
kube-controller-manager: static-pod
etcd: static-pod
dns: pod coredns
EOF
```

### Validation

```bash
cat /opt/course/8/controlplane-components.txt
```

### References

- [Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/)
- [Static Pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
- [kubeadm Architecture](https://kubernetes.io/docs/reference/setup-tools/kubeadm/)

---

## Question 9: Kill Scheduler, Manual Scheduling

### Context

**What is being tested:** Temporarily stopping the scheduler, manually scheduling Pods by setting `spec.nodeName`, and restarting the scheduler.

**Why this matters:** Understanding the scheduler's role and how to bypass it (manual scheduling) demonstrates deep knowledge of Pod lifecycle and scheduling mechanics.

**Task Summary:**

1. Temporarily stop the kube-scheduler
2. Create Pod `manual-schedule` — verify it's Pending
3. Manually schedule it on the controlplane node
4. Restart the scheduler
5. Create Pod `manual-schedule2` and verify it's auto-scheduled

> [!IMPORTANT]
> **Solve this question on:** `ssh cka5248`

### Solution

#### Step 1: Stop the scheduler (move manifest out)

```bash
ssh cka5248
sudo -i

# Verify scheduler is running
kubectl -n kube-system get pod | grep schedule

# Move the scheduler manifest out (temporarily stops it)
cd /etc/kubernetes/manifests/
mv kube-scheduler.yaml ..

# Wait for scheduler container to be removed
watch crictl ps
# Verify it's gone
kubectl -n kube-system get pod | grep schedule
# No output — scheduler is stopped
```

#### Step 2: Create Pod and verify it's Pending

```bash
k run manual-schedule --image=httpd:2-alpine

k get pod manual-schedule -o wide
# STATUS: Pending, NODE: <none> — no scheduler to assign it!
```

#### Step 3: Manually schedule the Pod

```bash
# Export the Pod YAML
k get pod manual-schedule -o yaml > 9.yaml

# Edit to add nodeName
vim 9.yaml
```

Add `nodeName: cka5248` under `spec`:

```yaml
spec:
  nodeName: cka5248    # ADD this line
  containers:
  - image: httpd:2-alpine
    name: manual-schedule
    ...
```

```bash
# Replace the Pod (can't edit nodeName on existing Pod)
k -f 9.yaml replace --force

k get pod manual-schedule -o wide
# STATUS: Running, NODE: cka5248 ✓
```

#### Step 4: Restart the scheduler

```bash
cd /etc/kubernetes/manifests/
mv ../kube-scheduler.yaml .

# Verify it's running again
kubectl -n kube-system get pod | grep schedule
# kube-scheduler-cka5248  1/1  Running
```

#### Step 5: Create a second Pod and verify auto-scheduling

```bash
k run manual-schedule2 --image=httpd:2-alpine

k get pod -o wide | grep schedule
# manual-schedule   Running  cka5248        (manually scheduled)
# manual-schedule2  Running  cka5248-node1  (auto-scheduled by scheduler)
```

### Validation

Both Pods should be Running. `manual-schedule` on the controlplane, `manual-schedule2` on the worker node.

> [!TIP]
> **Key Insight:** Manual scheduling bypasses taints/tolerations. Even if the controlplane has a `NoSchedule` taint, you can still manually place Pods there using `nodeName`.

### References

- [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Kubernetes Scheduler](https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/)

---

## Question 10: PV PVC Dynamic Provisioning

### Context

**What is being tested:** Creating StorageClasses, PersistentVolumeClaims with dynamic provisioning, and using them in Jobs.

**Why this matters:** Dynamic provisioning automates storage management. Understanding StorageClass parameters like `reclaimPolicy` and `volumeBindingMode` is essential for data safety.

**Key Concepts:**

- **reclaimPolicy: Retain** — PV is NOT deleted when PVC is deleted (protects data)
- **reclaimPolicy: Delete** — PV is deleted with PVC (data loss risk)
- **volumeBindingMode: WaitForFirstConsumer** — PV is created only when a Pod uses the PVC

**Task Summary:**

1. Create StorageClass `local-backup` with `Retain` policy
2. Modify a Job to use a PVC backed by the new StorageClass
3. Deploy and verify

> [!IMPORTANT]
> **Solve this question on:** `ssh cka6016`

### Solution

#### Step 1: Create the StorageClass

```bash
ssh cka6016

cat > sc.yaml << 'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-backup
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
EOF

k apply -f sc.yaml

# Verify
k get sc
```

#### Step 2: Modify the Job to use a PVC

```bash
cd /opt/course/10
cp backup.yaml backup.yaml_ori  # always backup first!
vim backup.yaml
```

```yaml
# /opt/course/10/backup.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-pvc
  namespace: project-bern
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Mi
  storageClassName: local-backup
---
apiVersion: batch/v1
kind: Job
metadata:
  name: backup
  namespace: project-bern
spec:
  backoffLimit: 0
  template:
    spec:
      volumes:
        - name: backup
          persistentVolumeClaim:
            claimName: backup-pvc
      containers:
        - name: bash
          image: bash:5
          command:
            - bash
            - -c
            - |
              set -x
              touch /backup/backup-$(date +%Y-%m-%d-%H-%M-%S).tar.gz
              sleep 15
          volumeMounts:
            - name: backup
              mountPath: /backup
      restartPolicy: Never
```

#### Step 3: Deploy and verify

```bash
# Delete existing Job if it was created before
k delete -f backup.yaml --ignore-not-found

# Apply
k apply -f backup.yaml

# Verify Job, Pod, PVC, and PV
k -n project-bern get job,pod,pvc,pv
```

### Validation

```bash
# Job should be Complete
k -n project-bern get job
# STATUS: Complete, COMPLETIONS: 1/1

# PVC should be Bound
k -n project-bern get pvc
# STATUS: Bound

# PV should exist with Retain policy
k get pv
# RECLAIM POLICY: Retain
```

> [!TIP]
> With `reclaimPolicy: Retain`, if you delete the PVC, the PV goes to `Released` state but the data is preserved. You can manually rescue the data and then delete the PV.

### References

- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Dynamic Volume Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)

---

## Question 11: Create Secret and Mount into Pod

### Context

**What is being tested:** Creating Secrets, mounting them as volumes (read-only), and exposing Secret values as environment variables.

**Why this matters:** Secrets store sensitive data (passwords, tokens, keys). Knowing multiple ways to consume them (volume mounts vs env vars) is essential.

**Task Summary:**

1. Create Namespace `secret`
2. Create Pod `secret-pod` (busybox:1, running `sleep 1d`)
3. Mount existing Secret `secret1` read-only at `/tmp/secret1`
4. Create Secret `secret2` with `user=user1` and `pass=1234`, expose as env vars `APP_USER` and `APP_PASS`

> [!IMPORTANT]
> **Solve this question on:** `ssh cka2560`

### Solution

#### Step 1: Create Namespace and Secrets

```bash
ssh cka2560

# Create namespace
k create ns secret

# Create secret1 from provided file (update namespace first)
cp /opt/course/11/secret1.yaml 11_secret1.yaml
# Edit to set namespace: secret
vim 11_secret1.yaml
k -f 11_secret1.yaml create

# Create secret2 from literals
k -n secret create secret generic secret2 \
  --from-literal=user=user1 \
  --from-literal=pass=1234
```

#### Step 2: Create the Pod with volume mount and env vars

```bash
k -n secret run secret-pod --image=busybox:1 --dry-run=client -o yaml -- sh -c "sleep 1d" > 11.yaml
```

Edit `11.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: secret-pod
  name: secret-pod
  namespace: secret
spec:
  containers:
    - args:
        - sh
        - -c
        - sleep 1d
      image: busybox:1
      name: secret-pod
      resources: {}
      env:
        - name: APP_USER
          valueFrom:
            secretKeyRef:
              name: secret2
              key: user
        - name: APP_PASS
          valueFrom:
            secretKeyRef:
              name: secret2
              key: pass
      volumeMounts:
        - name: secret1
          mountPath: /tmp/secret1
          readOnly: true
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  volumes:
    - name: secret1
      secret:
        secretName: secret1
```

```bash
k -f 11.yaml create
```

### Validation

```bash
# Check environment variables
k -n secret exec secret-pod -- env | grep APP
# APP_PASS=1234
# APP_USER=user1

# Check volume mount
k -n secret exec secret-pod -- find /tmp/secret1
# Shows the mounted secret files

k -n secret exec secret-pod -- cat /tmp/secret1/halt
# Shows the secret content
```

### References

- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Distribute Credentials Securely Using Secrets](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/)
- [Using Secrets as Environment Variables](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables)

---

## Question 12: Schedule Pod on Controlplane Nodes

### Context

**What is being tested:** Using tolerations and nodeSelector (or nodeAffinity) to schedule Pods exclusively on controlplane nodes.

**Why this matters:** Controlplane nodes typically have a `NoSchedule` taint. To schedule workloads there, you need both a toleration (to bypass the taint) AND a nodeSelector/affinity (to ensure it ONLY runs on controlplane nodes).

**Task Summary:** Create Pod `pod1` (httpd:2-alpine, container name `pod1-container`) that runs ONLY on controlplane nodes. Do not add new labels.

> [!IMPORTANT]
> **Solve this question on:** `ssh cka5248`

### Solution

#### Step 1: Find controlplane node info

```bash
ssh cka5248

# Get nodes
k get node

# Check taints on controlplane
k describe node cka5248 | grep Taint -A1
# Taints: node-role.kubernetes.io/control-plane:NoSchedule

# Check existing labels
k get node cka5248 --show-labels
# Has label: node-role.kubernetes.io/control-plane=
```

#### Step 2: Create Pod with toleration and nodeSelector

```bash
k run pod1 --image=httpd:2-alpine --dry-run=client -o yaml > 12.yaml
```

Edit `12.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: pod1
  name: pod1
spec:
  containers:
    - image: httpd:2-alpine
      name: pod1-container # change from default
      resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  tolerations:
    - effect: NoSchedule
      key: node-role.kubernetes.io/control-plane
  nodeSelector:
    node-role.kubernetes.io/control-plane: ""
```

```bash
k -f 12.yaml create
```

> [!NOTE]
> **Alternative using nodeAffinity** (more complex but equivalent):
>
> ```yaml
> tolerations:
>   - effect: NoSchedule
>     key: node-role.kubernetes.io/control-plane
> affinity:
>   nodeAffinity:
>     requiredDuringSchedulingIgnoredDuringExecution:
>       nodeSelectorTerms:
>         - matchExpressions:
>             - key: node-role.kubernetes.io/control-plane
>               operator: Exists
> ```

### Validation

```bash
k get pod pod1 -o wide
# NODE: cka5248 (controlplane node) ✓
```

> [!WARNING]
> Using ONLY a toleration is NOT enough — it just allows scheduling on controlplane nodes but doesn't prevent scheduling on worker nodes. You MUST add nodeSelector or nodeAffinity to restrict placement.

### References

- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Node Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity)

---

## Question 13: Multi Containers and Pod Shared Volume

### Context

**What is being tested:** Creating multi-container Pods with shared volumes, using the Downward API for environment variables, and container-to-container communication via shared filesystem.

**Why this matters:** Multi-container patterns (sidecar, adapter, ambassador) are common in production. Sharing data between containers via volumes is a fundamental Pod design pattern.

**Task Summary:**

- Container `c1`: nginx:1-alpine, env var `MY_NODE_NAME` from Downward API
- Container `c2`: busybox:1, writes `date` to shared volume every second
- Container `c3`: busybox:1, tails the date log from shared volume
- Non-persistent, non-shared volume (emptyDir)

> [!IMPORTANT]
> **Solve this question on:** `ssh cka3200`

### Solution

```bash
ssh cka3200
k run multi-container-playground --image=nginx:1-alpine --dry-run=client -o yaml > 13.yaml
```

Edit `13.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: multi-container-playground
  name: multi-container-playground
spec:
  containers:
    - image: nginx:1-alpine
      name: c1
      resources: {}
      env:
        - name: MY_NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
      volumeMounts:
        - name: vol
          mountPath: /vol
    - image: busybox:1
      name: c2
      command:
        ["sh", "-c", "while true; do date >> /vol/date.log; sleep 1; done"]
      volumeMounts:
        - name: vol
          mountPath: /vol
    - image: busybox:1
      name: c3
      command: ["sh", "-c", "tail -f /vol/date.log"]
      volumeMounts:
        - name: vol
          mountPath: /vol
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  volumes:
    - name: vol
      emptyDir: {}
```

```bash
k -f 13.yaml create
```

### Validation

```bash
# All 3 containers should be running
k get pod multi-container-playground
# READY: 3/3

# Check node name env var in c1
k exec multi-container-playground -c c1 -- env | grep MY
# MY_NODE_NAME=cka3200

# Check c3 logs (should show date output from c2)
k logs multi-container-playground -c c3
# Shows continuous date output
```

### References

- [Init Containers and Sidecar Patterns](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [Downward API — Expose Pod Information](https://kubernetes.io/docs/concepts/workloads/pods/downward-api/)
- [Communicate Between Containers in the Same Pod Using a Shared Volume](https://kubernetes.io/docs/tasks/access-application-cluster/communicate-containers-same-pod-shared-volume/)
- [Volumes — emptyDir](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)

---

## Question 14: Find out Cluster Information

### Context

**What is being tested:** Ability to investigate and gather cluster configuration details including node counts, networking CIDR, CNI plugin, and static pod naming conventions.

**Why this matters:** As a cluster administrator, you need to quickly determine cluster configuration for troubleshooting, capacity planning, and documentation.

**Task Summary:** Find: controlplane count, worker count, Service CIDR, CNI plugin info, static pod suffix.

> [!IMPORTANT]
> **Solve this question on:** `ssh cka8448`

### Solution

```bash
ssh cka8448
sudo -i
```

#### 1. How many controlplane nodes?

```bash
k get node
# cka8448  Ready  control-plane
# Answer: 1
```

#### 2. How many worker nodes?

```bash
# No workers visible
# Answer: 0
```

#### 3. What is the Service CIDR?

```bash
cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep range
# --service-cluster-ip-range=10.96.0.0/12
# Answer: 10.96.0.0/12
```

#### 4. Which CNI Plugin and config file?

```bash
find /etc/cni/net.d/
# /etc/cni/net.d/10-weave.conflist

cat /etc/cni/net.d/10-weave.conflist
# "name": "weave"
# Answer: Weave, /etc/cni/net.d/10-weave.conflist
```

#### 5. Static pod suffix for cka8448?

```bash
# Static pods get the node hostname appended with a leading hyphen
# Answer: -cka8448
```

#### Write the answer file

```bash
cat > /opt/course/14/cluster-info << 'EOF'
# How many controlplane nodes are available?
1: 1
# How many worker nodes (non controlplane nodes) are available?
2: 0
# What is the Service CIDR?
3: 10.96.0.0/12
# Which Networking (or CNI Plugin) is configured and where is its config file?
4: Weave, /etc/cni/net.d/10-weave.conflist
# Which suffix will static pods have that run on cka8448?
5: -cka8448
EOF
```

### References

- [Cluster Networking](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
- [Network Plugins](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)
- [Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/)

---

## Question 15: Cluster Event Logging

### Context

**What is being tested:** Working with Kubernetes events — listing, sorting, and understanding the difference between Pod deletion and container killing events.

**Why this matters:** Events are a primary debugging tool. Understanding what events are generated by different actions (Pod delete vs container kill) aids in root cause analysis.

**Task Summary:**

1. Write a kubectl command to show latest cluster events sorted by time
2. Delete a kube-proxy Pod and log the events
3. Manually kill the kube-proxy container and log the events

> [!IMPORTANT]
> **Solve this question on:** `ssh cka6016`

### Solution

#### Step 1: Create the events script

```bash
ssh cka6016

cat > /opt/course/15/cluster_events.sh << 'EOF'
kubectl get events -A --sort-by=.metadata.creationTimestamp
EOF
```

```bash
# Test it
sh /opt/course/15/cluster_events.sh
```

#### Step 2: Delete kube-proxy Pod and log events

```bash
# Find the kube-proxy pod
k -n kube-system get pod -l k8s-app=kube-proxy

# Delete it
k -n kube-system delete pod kube-proxy-<id>

# Run events command and save relevant events
sh /opt/course/15/cluster_events.sh
```

Write the relevant events to the log file:

```bash
cat > /opt/course/15/pod_kill.log << 'EOF'
kube-system   Normal    Killing             pod/kube-proxy-lf2fs          Stopping container kube-proxy
kube-system   Normal    SuccessfulCreate    daemonset/kube-proxy          Created pod: kube-proxy-wb4tb
kube-system   Normal    Scheduled           pod/kube-proxy-wb4tb          Successfully assigned kube-system/kube-proxy-wb4tb to cka6016
kube-system   Normal    Pulled              pod/kube-proxy-wb4tb          Container image already present on machine
kube-system   Normal    Created             pod/kube-proxy-wb4tb          Created container kube-proxy
kube-system   Normal    Started             pod/kube-proxy-wb4tb          Started container kube-proxy
EOF
```

#### Step 3: Kill the container and log events

```bash
sudo -i

# Find the kube-proxy container
crictl ps | grep kube-proxy

# Force remove the container
crictl rm --force <CONTAINER-ID>

# Check that a new container was created automatically
crictl ps | grep kube-proxy

# Exit root and check events
exit
sh /opt/course/15/cluster_events.sh
```

Write the events to the log file:

```bash
cat > /opt/course/15/container_kill.log << 'EOF'
kube-system   Normal    Created             pod/kube-proxy-wb4tb          Created container kube-proxy
kube-system   Normal    Started             pod/kube-proxy-wb4tb          Started container kube-proxy
EOF
```

### Validation

```bash
cat /opt/course/15/pod_kill.log
cat /opt/course/15/container_kill.log
```

> [!TIP]
> **Key Insight:** Deleting a Pod triggers more events (DaemonSet recreation, scheduling, pulling, creating, starting). Killing just a container triggers fewer events (container restart only) because the Pod still exists — Kubernetes just restarts the container.

### References

- [Viewing and Filtering Events](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_events/)
- [Debug Running Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/)

---

## Question 16: Namespaces and Api Resources

### Context

**What is being tested:** Understanding namespaced vs cluster-scoped resources and using `kubectl api-resources` to list them. Also counting RBAC Roles across namespaces.

**Why this matters:** Knowing which resources are namespaced helps with multi-tenant cluster design and RBAC configuration.

**Task Summary:**

1. Write all namespaced resource names to a file
2. Find the `project-*` namespace with the most Roles and write the result

> [!IMPORTANT]
> **Solve this question on:** `ssh cka3200`

### Solution

#### Step 1: List all namespaced resources

```bash
ssh cka3200

k api-resources --namespaced -o name > /opt/course/16/resources.txt
```

#### Step 2: Find the namespace with most Roles

```bash
# Check each project-* namespace
k -n project-jinan get role --no-headers | wc -l      # 0
k -n project-miami get role --no-headers | wc -l      # 300
k -n project-melbourne get role --no-headers | wc -l  # 2
k -n project-seoul get role --no-headers | wc -l      # 10
k -n project-toronto get role --no-headers | wc -l    # 0
```

```bash
cat > /opt/course/16/crowded-namespace.txt << 'EOF'
project-miami with 300 roles
EOF
```

### Validation

```bash
cat /opt/course/16/resources.txt
cat /opt/course/16/crowded-namespace.txt
```

> [!TIP]
> **Useful `api-resources` flags:**
>
> ```bash
> k api-resources --namespaced       # only namespaced resources
> k api-resources --namespaced=false  # only cluster-scoped resources
> k api-resources -o name            # just resource names
> k api-resources -o wide            # includes verbs
> ```

### References

- [API Resources](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_api-resources/)
- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)

---

## Question 17: Operator, CRDs, RBAC, Kustomize

### Context

**What is being tested:** Working with Kubernetes Operators, Custom Resource Definitions, RBAC Roles, and Kustomize overlays.

**Why this matters:** Operators are a common pattern for managing complex applications. Understanding how to debug RBAC issues, modify Kustomize configs, and work with CRDs is essential for cluster administration.

**Task Summary:**

1. Fix RBAC permissions for the operator (it needs to list `students` and `classes` CRDs)
2. Add a new Student resource (`student4`)
3. Deploy changes via Kustomize to prod

> [!IMPORTANT]
> **Solve this question on:** `ssh cka6016`

### Solution

#### Step 1: Investigate the issue (check operator logs)

```bash
ssh cka6016
cd /opt/course/17/operator

# Check operator logs
k -n operator-prod get pod
k -n operator-prod logs <operator-pod-name>
# Error: students.education.killer.sh is forbidden: cannot list resource "students"
# Error: classes.education.killer.sh is forbidden: cannot list resource "classes"
```

#### Step 2: Fix the RBAC Role in Kustomize base

```bash
# Generate the correct Role YAML for reference
k -n operator-prod create role operator-role \
  --verb list --resource student --resource class \
  -oyaml --dry-run=client
```

Edit the Kustomize base RBAC file:

```bash
vim base/rbac.yaml
```

```yaml
# base/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: operator-role
  namespace: default
rules:
  - apiGroups:
      - education.killer.sh
    resources:
      - students
      - classes
    verbs:
      - list
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: operator-rolebinding
  namespace: default
subjects:
  - kind: ServiceAccount
    name: operator
    namespace: default
roleRef:
  kind: Role
  name: operator-role
  apiGroup: rbac.authorization.k8s.io
```

#### Step 3: Add new Student resource

```bash
vim base/students.yaml
```

Append at the end:

```yaml
---
apiVersion: education.killer.sh/v1
kind: Student
metadata:
  name: student4
spec:
  name: Some Name
  description: Some Description
```

#### Step 4: Deploy to prod

```bash
kubectl kustomize /opt/course/17/operator/prod | kubectl apply -f -
```

### Validation

```bash
# Check Role was updated
# role.rbac.authorization.k8s.io/operator-role configured

# Check student4 was created
k -n operator-prod get student
# student1, student2, student3, student4

# Check operator logs — no more RBAC errors
k -n operator-prod logs <operator-pod-name>
# Should show successful kubectl get students and kubectl get classes
```

### References

- [Custom Resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)
- [Operator Pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)

---

---

## Quick Reference: Kubectl Commands

### Pod Operations

```bash
# Create a pod
kubectl run <name> --image=<image>
kubectl run <name> --image=<image> --dry-run=client -o yaml > pod.yaml
kubectl run <name> --image=<image> --labels="key=value"
kubectl run <name> --image=<image> -- sh -c "sleep 1d"

# Get pods
kubectl get pod
kubectl get pod -A                            # all namespaces
kubectl get pod -o wide                       # show node, IP
kubectl get pod --show-labels
kubectl get pod -l key=value                  # filter by label
kubectl get pod --sort-by=.metadata.creationTimestamp
kubectl get pod --sort-by=.metadata.uid
kubectl get pod -o jsonpath="{.items[*].metadata.name}"

# Describe / Logs / Exec
kubectl describe pod <name>
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container>        # multi-container
kubectl logs <pod-name> -f                    # follow
kubectl exec <pod-name> -- <command>
kubectl exec -it <pod-name> -- sh

# Delete
kubectl delete pod <name>
kubectl delete pod <name> --grace-period 0 --force   # fast delete
```

### Deployment Operations

```bash
kubectl create deployment <name> --image=<image>
kubectl create deployment <name> --image=<image> --replicas=3
kubectl scale deployment <name> --replicas=<n>
kubectl rollout restart deploy <name>
kubectl rollout status deploy <name>
kubectl rollout undo deploy <name>
kubectl set image deploy/<name> <container>=<new-image>
```

### Service Operations

```bash
kubectl expose pod <name> --port=80 --type=ClusterIP
kubectl expose pod <name> --name=<svc-name> --port=80 --type=NodePort
kubectl expose deploy <name> --port=80 --target-port=8080
kubectl get svc
kubectl get endpointslice
```

### Namespace Operations

```bash
kubectl create ns <name>
kubectl get ns
kubectl -n <namespace> get all
```

### ConfigMap and Secret

```bash
# ConfigMap
kubectl create configmap <name> --from-literal=key=value
kubectl create configmap <name> --from-file=<file>
kubectl get cm
kubectl edit cm <name>

# Secret
kubectl create secret generic <name> --from-literal=key=value
kubectl create secret generic <name> --from-file=<file>
kubectl get secret
kubectl get secret <name> -o jsonpath="{.data.key}" | base64 -d
```

### Node Operations

```bash
kubectl get node
kubectl get node -o wide
kubectl get node --show-labels
kubectl describe node <name>
kubectl top node
kubectl top pod
kubectl cordon <node>                    # mark unschedulable
kubectl uncordon <node>                  # mark schedulable
kubectl drain <node> --ignore-daemonsets --force
```

### RBAC

```bash
kubectl create role <name> --verb=<verbs> --resource=<resources>
kubectl create rolebinding <name> --role=<role> --serviceaccount=<ns>:<sa>
kubectl create clusterrole <name> --verb=<verbs> --resource=<resources>
kubectl create clusterrolebinding <name> --clusterrole=<role> --serviceaccount=<ns>:<sa>
kubectl auth can-i <verb> <resource> --as system:serviceaccount:<ns>:<sa>
```

### Resource Information

```bash
kubectl api-resources                        # all resources
kubectl api-resources --namespaced           # only namespaced
kubectl api-resources --namespaced=false      # only cluster-scoped
kubectl api-resources -o name               # just names
kubectl explain <resource>                   # describe resource fields
kubectl explain pod.spec.containers
```

### Events & Debugging

```bash
kubectl get events -A --sort-by=.metadata.creationTimestamp
kubectl describe <resource> <name>           # events in describe output
kubectl logs <pod> --previous                # logs from crashed container
```

### Sorting and Filtering

```bash
kubectl get pods --sort-by=.metadata.creationTimestamp
kubectl get pods --sort-by=.metadata.uid
kubectl get pods --sort-by=.status.phase
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name} {.status.qosClass}{"\n"}{end}'
```

### Kustomize

```bash
kubectl kustomize <dir>                      # build/preview
kubectl kustomize <dir> | kubectl apply -f - # apply
kubectl kustomize <dir> | kubectl diff -f -  # diff before apply
```

---

## Quick Reference: Kubeadm Commands

### Cluster Initialization

```bash
# Initialize a new cluster
kubeadm init
kubeadm init --pod-network-cidr=10.244.0.0/16
kubeadm init --apiserver-advertise-address=<IP>

# Generate join command for worker nodes
kubeadm token create --print-join-command

# Join a worker node to the cluster
kubeadm join <api-server-ip>:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

### Cluster Upgrade

```bash
# Check available versions
apt show kubeadm -a | grep <version>

# Upgrade kubeadm
apt install kubeadm=<version> -y

# Plan the upgrade
kubeadm upgrade plan

# Apply the upgrade (on controlplane)
kubeadm upgrade apply v<version>

# Upgrade kubelet and kubectl
apt install kubelet=<version> kubectl=<version> -y
systemctl daemon-reload
systemctl restart kubelet

# On worker nodes after upgrading kubeadm
kubeadm upgrade node
```

### Certificate Management

```bash
# Check certificate expiry
kubeadm certs check-expiration

# Renew all certificates
kubeadm certs renew all

# View certificate info
openssl x509 -noout -text -in /etc/kubernetes/pki/apiserver.crt
openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet-client-current.pem | grep Issuer
openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet.crt | grep "Extended Key Usage" -A1
```

### Token Management

```bash
# List tokens
kubeadm token list

# Create a new token
kubeadm token create

# Create token with join command
kubeadm token create --print-join-command

# Delete a token
kubeadm token delete <token>
```

### Etcd Operations

```bash
# Snapshot
ETCDCTL_API=3 etcdctl snapshot save <file> \
  --cacert /etc/kubernetes/pki/etcd/ca.crt \
  --cert /etc/kubernetes/pki/etcd/server.crt \
  --key /etc/kubernetes/pki/etcd/server.key

# Restore (use etcdutl in newer versions)
ETCDCTL_API=3 etcdctl snapshot restore <file> \
  --data-dir /var/lib/etcd-snapshot \
  --cacert /etc/kubernetes/pki/etcd/ca.crt \
  --cert /etc/kubernetes/pki/etcd/server.crt \
  --key /etc/kubernetes/pki/etcd/server.key
```

### Kubelet Troubleshooting

```bash
# Check kubelet status
service kubelet status
systemctl status kubelet

# Start/restart kubelet
service kubelet start
service kubelet restart
systemctl restart kubelet

# After config changes
systemctl daemon-reload
systemctl restart kubelet

# Check kubelet logs
journalctl -u kubelet
journalctl -u kubelet --no-pager | tail -50
cat /var/log/syslog | grep kubelet

# Find kubelet binary
whereis kubelet

# Check kubelet config
cat /var/lib/kubelet/config.yaml
cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
```

### Control Plane Component Locations

```bash
# Static Pod manifests
/etc/kubernetes/manifests/
  ├── etcd.yaml
  ├── kube-apiserver.yaml
  ├── kube-controller-manager.yaml
  └── kube-scheduler.yaml

# PKI certificates
/etc/kubernetes/pki/
  ├── apiserver.crt
  ├── apiserver.key
  ├── ca.crt
  ├── ca.key
  └── etcd/
      ├── ca.crt
      ├── server.crt
      └── server.key

# Kubelet PKI
/var/lib/kubelet/pki/
  ├── kubelet-client-current.pem  # client cert
  ├── kubelet.crt                 # server cert
  └── kubelet.key                 # server key

# CNI configuration
/etc/cni/net.d/

# Kubelet configuration
/var/lib/kubelet/config.yaml
/usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
```

---

> [!TIP]
> **Exam Tips:**
>
> - Use `k` alias (pre-configured) and bash autocompletion
> - Use `--dry-run=client -o yaml` to generate YAML templates quickly
> - Always verify your work with `kubectl get` and `kubectl describe`
> - Use `kubectl explain <resource.field>` to check field syntax
> - Flag difficult questions and return to them later
> - Use `Ctrl+r` for reverse history search in bash
> - Delete pods fast: `k delete pod x --grace-period 0 --force`
