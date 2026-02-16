# CKA Mock Exam 2 — Refined Solutions

> **Source:** Udemy CKA Mock Test 2  
> **Total Questions:** 16 (Q1–Q4 and Q6–Q9 not captured in draft)  
> **Sections:** Workloads & Scheduling · Troubleshooting · Services & Networking · Storage

---

## Table of Contents

| #           | Section                | Topic                                      |
| ----------- | ---------------------- | ------------------------------------------ |
| [Q5](#q5)   | Workloads & Scheduling | ResourceQuota — Deployment Troubleshooting |
| [Q10](#q10) | Workloads & Scheduling | Secrets & 2-Tier Web App                   |
| [Q11](#q11) | Troubleshooting        | ConfigMap Volume Mount (subPath)           |
| [Q12](#q12) | Troubleshooting        | Ingress Misconfiguration                   |
| [Q13](#q13) | Services & Networking  | Gateway API — TLS Configuration            |
| [Q14](#q14) | Services & Networking  | HTTPRoute — Path-Based Routing             |
| [Q15](#q15) | Storage                | PersistentVolumeClaim Creation             |
| [Q16](#q16) | Troubleshooting        | Missing Kubelet — Cluster Recovery         |

---

<a id="q5"></a>

## Q5 — ResourceQuota — Deployment Troubleshooting

**Section:** Workloads & Scheduling  
**Cluster:** `ssh cluster3-controlplane`

### Question

Your cluster has a failed deployment named `backend-api` with multiple pods. Troubleshoot the deployment so that all pods are in a running state. **Do not** adjust the resource **limits** defined on the deployment pods.

> A `ResourceQuota` named `cpu-mem-quota` is applied to the default namespace and **should not** be edited or modified.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster3-controlplane
```

#### Step 2 — Check the deployment status

```bash
kubectl get deploy backend-api
```

Expected output — only 2 out of 3 pods are running:

```
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
backend-api   2/3     2            2           3m48s
```

#### Step 3 — Find the root cause

```bash
# Get the ReplicaSet name
kubectl get rs | grep backend-api

# Describe the ReplicaSet to see why the 3rd pod can't be created
kubectl describe rs <backend-api-rs-name>
```

Look for the error:

```
exceeded quota: cpu-mem-quota,
requested: requests.memory=128Mi, used: requests.memory=256Mi, limited: requests.memory=300Mi
```

**Root cause:** The namespace has a `ResourceQuota` limiting `requests.memory` to `300Mi`. With 3 pods each requesting `128Mi`, the total is `384Mi` — exceeding the quota.

#### Step 4 — Check the current ResourceQuota usage

```bash
kubectl describe resourcequota cpu-mem-quota -n default
```

This confirms the quota limits and current usage.

#### Step 5 — Reduce memory requests (not limits) to fit within the quota

```bash
kubectl edit deployment backend-api -n default
```

Modify the `resources.requests` section (do **not** change `limits`):

```yaml
resources:
  requests:
    cpu: "50m" # Reduced from 100m
    memory: "90Mi" # Reduced from 128Mi (3 × 90Mi = 270Mi < 300Mi quota)
  limits:
    cpu: "150m" # Keep unchanged
    memory: "150Mi" # Keep unchanged
```

> **Key Insight:** `3 × 90Mi = 270Mi` fits within the `300Mi` quota. The question says do not change limits, so only `requests` are modified.

#### Step 6 — Clean up old ReplicaSet if needed

```bash
# Check if old RS pods are still consuming quota
kubectl get rs -n default | grep backend-api

# If old RS is preventing new pods from starting, delete it
kubectl delete rs <old-backend-api-rs-name> -n default
```

#### Step 7 — Wait for rollout to finish

```bash
kubectl rollout status deploy backend-api -n default
```

### Validation

```bash
# All 3 pods should be Running
kubectl get deploy backend-api
# READY should show 3/3

kubectl get pods -n default | grep backend-api
# All pods should show STATUS: Running
```

### 📖 Official Documentation

- [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
- [Managing Resources for Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

---

## Q10 — Secrets & 2-Tier Web App Configuration

**Section:** Workloads & Scheduling  
**Cluster:** `ssh cluster3-controlplane`

### Question

A 2-tier web application is deployed in the `canara-wl05` namespace. The web app pod cannot connect to the MySQL pod. Create a secret `db-secret-wl05` with the correct DB connection details and configure the web app pod to use it.

Secret key-value pairs:

1. `DB_Host=mysql-svc-wl05`
2. `DB_User=root`
3. `DB_Password=password123`

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster3-controlplane
```

#### Step 2 — Verify the current failure

```bash
# Get the NodePort
kubectl get svc -n canara-wl05

# Test the app (use the node IP and NodePort from above)
curl http://cluster3-controlplane:<NODE-PORT>
```

You will see: `Failed connecting to the MySQL database` and `DB_Host=Not Set`.

#### Step 3 — Create the secret

```bash
kubectl create secret generic db-secret-wl05 \
  -n canara-wl05 \
  --from-literal=DB_Host=mysql-svc-wl05 \
  --from-literal=DB_User=root \
  --from-literal=DB_Password=password123
```

#### Step 4 — Get the existing pod spec

```bash
kubectl get pod webapp-pod-wl05 -n canara-wl05 -o yaml > /tmp/webapp-pod.yaml
```

#### Step 5 — Edit the pod to load environment variables from the secret

```bash
vi /tmp/webapp-pod.yaml
```

Add `envFrom` to the container spec:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webapp-pod-wl05
  namespace: canara-wl05
  labels:
    run: webapp-pod-wl05
spec:
  containers:
    - name: webapp-pod-wl05
      image: kodekloud/simple-webapp-mysql
      envFrom:
        - secretRef:
            name: db-secret-wl05
```

> **Important:** Clean up managed fields, `status`, `uid`, `resourceVersion`, etc. from the exported YAML before replacing.

#### Step 6 — Force-replace the pod

```bash
kubectl replace -f /tmp/webapp-pod.yaml --force
```

> **Tip:** `--force` deletes and recreates the pod. This is needed because you can't add `envFrom` to a running pod.

#### Step 7 — Wait for the pod to be Ready

```bash
kubectl wait pod webapp-pod-wl05 -n canara-wl05 --for=condition=Ready --timeout=60s
```

### Validation

```bash
# Test the app again
curl http://cluster3-controlplane:<NODE-PORT>
# Should show: "Successfully connected to the MySQL database."

# Verify the environment variables are set
kubectl exec -n canara-wl05 webapp-pod-wl05 -- env | grep DB_
# Expected:
# DB_Host=mysql-svc-wl05
# DB_User=root
# DB_Password=password123
```

### 📖 Official Documentation

- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Using Secrets as Environment Variables](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables)
- [Distribute Credentials Securely Using Secrets](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/)

---

<a id="q11"></a>

## Q11 — ConfigMap Volume Mount with subPath

**Section:** Troubleshooting  
**Cluster:** `ssh cluster4-controlplane`

### Question

Troubleshoot and resolve the issue with the deployment named `nginx-frontend` in the `cka4974` namespace, which is currently failing to run. The application is intended to serve traffic on **port 81**.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster4-controlplane
```

#### Step 2 — Check the pod status

```bash
kubectl get pods -n cka4974
```

You will see the pod in `CrashLoopBackOff`.

#### Step 3 — Describe the pod to find the error

```bash
kubectl describe pod -n cka4974 -l app=nginx-frontend
```

Look for the key error:

```
error mounting ".../nginx-conf-vol" to rootfs at "/etc/nginx/conf.d/default.conf":
mount ...:/etc/nginx/conf.d/default.conf ... not a directory: unknown
```

**Root cause:** The ConfigMap volume is being mounted as a directory over a file path (`/etc/nginx/conf.d/default.conf`). The `subPath` directive is missing, which is needed to mount a single file from a ConfigMap.

#### Step 4 — Fix the deployment

```bash
kubectl edit deployment nginx-frontend -n cka4974
```

Update the `volumeMounts` section to include `subPath`:

```yaml
volumeMounts:
  - name: nginx-conf-vol
    mountPath: /etc/nginx/conf.d/default.conf
    subPath: default.conf
```

> **Explanation:** Without `subPath`, Kubernetes mounts the entire ConfigMap as a directory at the `mountPath`. Since `/etc/nginx/conf.d/default.conf` is expected to be a file, the mount fails. Adding `subPath: default.conf` tells Kubernetes to mount only that specific key from the ConfigMap as a file.

Save and exit. The deployment will automatically create a new pod.

### Validation

```bash
# Wait for the new pod to be Running
kubectl get pods -n cka4974 -w

# Test the application on port 81
kubectl exec -it -n cka4974 deploy/nginx-frontend -- curl -I http://localhost:81
```

Expected output:

```
HTTP/1.1 200 OK
Server: nginx/1.27.4
Content-Type: text/html
```

### 📖 Official Documentation

- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Using ConfigMaps as Files in a Pod (subPath)](https://kubernetes.io/docs/concepts/storage/volumes/#using-subpath)
- [Populate a Volume with Data Stored in a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#populate-a-volume-with-data-stored-in-a-configmap)

---

<a id="q12"></a>

## Q12 — Troubleshoot Ingress Misconfiguration

**Section:** Troubleshooting  
**Cluster:** `ssh cluster1-controlplane`

### Question

A deployment `nodeapp-dp-cka08-trb` is using an ingress `nodeapp-ing-cka08-trb`. Access via `curl http://kodekloud-ingress.app` should work but returns 404. Troubleshoot and fix the issue.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Confirm the failure

```bash
curl http://kodekloud-ingress.app
# Returns: 404 Not Found
```

#### Step 3 — Inspect the ingress resource

```bash
kubectl get ingress nodeapp-ing-cka08-trb
kubectl describe ingress nodeapp-ing-cka08-trb
```

#### Step 4 — Check the backend service and port

```bash
# Find the correct service name and port
kubectl get svc | grep nodeapp
kubectl describe svc nodeapp-svc-cka08-trb
```

#### Step 5 — Edit the ingress to fix all issues

```bash
kubectl edit ingress nodeapp-ing-cka08-trb
```

Make the following corrections:

| Field                         | Wrong Value       | Correct Value           |
| ----------------------------- | ----------------- | ----------------------- |
| `rules[].host`                | `example.com`     | `kodekloud-ingress.app` |
| `backend.service.name`        | `example-service` | `nodeapp-svc-cka08-trb` |
| `backend.service.port.number` | `80`              | `3000`                  |

The corrected ingress spec should look like:

```yaml
spec:
  rules:
    - host: kodekloud-ingress.app
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nodeapp-svc-cka08-trb
                port:
                  number: 3000
```

### Validation

```bash
# Test the ingress
curl http://kodekloud-ingress.app
# Should return the application response (200 OK)

# Verify ingress details
kubectl describe ingress nodeapp-ing-cka08-trb
# Host should be kodekloud-ingress.app, backend should point to nodeapp-svc-cka08-trb:3000
```

### 📖 Official Documentation

- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Debugging Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)

---

<a id="q13"></a>

## Q13 — Gateway API — TLS Configuration

**Section:** Services & Networking  
**Cluster:** `ssh cluster3-controlplane`

### Question

Modify the existing `web-gateway` in the `cka5673` namespace to handle HTTPS traffic on **port 443** for `kodekloud.com`, using a TLS certificate stored in a secret named `kodekloud-tls`.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster3-controlplane
```

#### Step 2 — Check the current gateway configuration

```bash
kubectl get gateway web-gateway -n cka5673 -o yaml
```

Current (incorrect) configuration — listening on port 80 with HTTP protocol.

#### Step 3 — Verify the TLS secret exists

```bash
kubectl get secret kodekloud-tls -n cka5673
```

#### Step 4 — Update the gateway for HTTPS

```bash
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
  namespace: cka5673
spec:
  gatewayClassName: kodekloud
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      hostname: kodekloud.com
      tls:
        mode: Terminate
        certificateRefs:
          - name: kodekloud-tls
      allowedRoutes:
        namespaces:
          from: Same
EOF
```

> **Key fields explained:**
>
> - `protocol: HTTPS` — enables TLS termination
> - `port: 443` — standard HTTPS port
> - `hostname: kodekloud.com` — restricts to this domain
> - `tls.certificateRefs` — references the TLS secret containing the certificate and key
> - `tls.mode: Terminate` — TLS is terminated at the gateway

### Validation

```bash
# Verify the gateway is updated
kubectl get gateway web-gateway -n cka5673 -o yaml

# Check the listener status
kubectl describe gateway web-gateway -n cka5673
# Listener should show port 443, protocol HTTPS, and the TLS certificate reference
```

### 📖 Official Documentation

- [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/)
- [Gateway API — TLS Configuration](https://gateway-api.sigs.k8s.io/guides/tls/)
- [Gateway Listeners](https://gateway-api.sigs.k8s.io/api-types/gateway/#listeners)

---

<a id="q14"></a>

## Q14 — HTTPRoute — Path-Based Routing

**Section:** Services & Networking  
**Cluster:** `ssh cluster3-controlplane`

### Question

Extend the `web-route` HTTPRoute in namespace `cka7395` to direct traffic with path prefix `/api` to `api-service` on port `8080`, while all other traffic continues to route to `web-service`.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster3-controlplane
```

#### Step 2 — Check the current HTTPRoute configuration

```bash
kubectl get httproute web-route -n cka7395 -o yaml
```

Current config routes all traffic (`/`) to `web-service` on port 80.

#### Step 3 — Update the HTTPRoute with the new `/api` rule

```bash
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: cka7395
spec:
  parentRefs:
    - name: nginx-gateway
      namespace: nginx-gateway
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: api-service
          port: 8080
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: web-service
          port: 80
EOF
```

> **Important:** The `/api` rule must come **before** the `/` rule. Kubernetes Gateway API evaluates rules in order, and the more specific path should be listed first.

### Validation

```bash
# Verify the HTTPRoute
kubectl get httproute web-route -n cka7395 -o yaml

# Check the rules
kubectl describe httproute web-route -n cka7395
# Should show two rules:
# 1. /api → api-service:8080
# 2. /    → web-service:80
```

### 📖 Official Documentation

- [Gateway API — HTTPRoute](https://gateway-api.sigs.k8s.io/api-types/httproute/)
- [HTTPRoute Matching](https://gateway-api.sigs.k8s.io/guides/http-routing/)
- [Kubernetes Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/)

---

<a id="q15"></a>

## Q15 — Create a PersistentVolumeClaim

**Section:** Storage  
**Cluster:** `ssh cluster1-controlplane`

### Question

There is a PV named `apple-pv-cka04-str`. Create a PVC named `apple-pvc-cka04-str` requesting **40Mi** of storage from that PV, with access mode `ReadWriteOnce` and storage class `manual`.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Verify the existing PV

```bash
kubectl get pv apple-pv-cka04-str
kubectl describe pv apple-pv-cka04-str
```

Note the storage class, capacity, and access modes.

#### Step 3 — Create the PVC

```bash
cat <<EOF > /tmp/apple-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: apple-pvc-cka04-str
spec:
  volumeName: apple-pv-cka04-str
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 40Mi
EOF
```

```bash
kubectl apply -f /tmp/apple-pvc.yaml
```

> **Tip:** Using `volumeName` explicitly binds this PVC to the specific PV `apple-pv-cka04-str`, preventing it from binding to any other PV.

### Validation

```bash
# Verify the PVC is Bound
kubectl get pvc apple-pvc-cka04-str
# STATUS should be "Bound"

# Verify the PV is Bound to the correct PVC
kubectl get pv apple-pv-cka04-str
# CLAIM should show "default/apple-pvc-cka04-str"

# Confirm storage details
kubectl describe pvc apple-pvc-cka04-str
# StorageClass: manual, Access Modes: RWO, Capacity: 40Mi (or up to PV capacity)
```

### 📖 Official Documentation

- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [PersistentVolumeClaims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)
- [Configure a Pod to Use a PersistentVolume](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/)

---

<a id="q16"></a>

## Q16 — Missing Kubelet — Full Cluster Recovery

**Section:** Troubleshooting  
**Cluster:** `ssh cluster2-controlplane`

### Question

As a Kubernetes administrator, you are unable to run any `kubectl` commands on the cluster. Troubleshoot the problem and get the cluster to a functioning state.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster2-controlplane
```

#### Step 2 — Attempt to query the cluster

```bash
kubectl get nodes
```

Output:

```
The connection to the server cluster2-controlplane:6443 was refused - did you specify the right host or port?
```

This means the **kube-apiserver is not running**.

#### Step 3 — Check running containers using crictl

```bash
crictl ps -a
```

You will notice:

- `etcd` — Running ✅
- `coredns` — Running ✅
- `kube-controller-manager` — **Exited** ❌
- `kube-scheduler` — **Exited** ❌
- `kube-apiserver` — **Missing entirely** ❌

#### Step 4 — Check if kubelet is running

```bash
systemctl status kubelet
```

Output:

```
Unit kubelet.service could not be found.
```

**Root cause:** `kubelet` is **not installed** on this node. Without kubelet, static pod manifests (including kube-apiserver) cannot be managed.

#### Step 5 — Find the correct Kubernetes version

```bash
kubeadm version
```

Note the `GitVersion` (e.g., `v1.32.0`).

#### Step 6 — Install kubelet

```bash
sudo apt update
sudo apt install -y kubelet=1.32.0-1.1
```

> **Important:** The kubelet version must match the kubeadm/cluster version. Using a mismatched version can cause compatibility issues.

#### Step 7 — Enable and start kubelet

```bash
sudo systemctl daemon-reload
sudo systemctl enable kubelet
sudo systemctl start kubelet
```

#### Step 8 — Wait for the control plane to recover

```bash
# Watch kubelet start bringing up static pods
# The kube-apiserver should start within 30-60 seconds
sleep 30

# Verify the cluster is functional
kubectl get nodes
```

### Validation

```bash
# All nodes should be Ready
kubectl get nodes
# Expected:
# NAME                      STATUS   ROLES           AGE   VERSION
# cluster2-controlplane     Ready    control-plane   27m   v1.32.0
# cluster2-node01           Ready    <none>          26m   v1.32.0

# All control plane pods should be Running
kubectl get pods -n kube-system

# Verify kubelet is running
systemctl status kubelet
# Should show: Active: active (running)
```

### 📖 Official Documentation

- [kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/)
- [Installing kubeadm (includes kubelet)](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [Troubleshooting kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/)
- [Static Pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)

---

## Quick Reference — Key `kubectl` Commands

| Action                   | Command                                                         |
| ------------------------ | --------------------------------------------------------------- |
| Get deployments          | `kubectl get deploy -n <ns>`                                    |
| Describe ReplicaSet      | `kubectl describe rs <rs-name>`                                 |
| Edit deployment          | `kubectl edit deploy <name> -n <ns>`                            |
| Scale deployment         | `kubectl scale deploy <name> --replicas=<n>`                    |
| Rollout status           | `kubectl rollout status deploy <name>`                          |
| Create secret (literals) | `kubectl create secret generic <name> --from-literal=KEY=VALUE` |
| Get pod YAML             | `kubectl get pod <name> -o yaml > pod.yaml`                     |
| Force-replace a pod      | `kubectl replace -f <file> --force`                             |
| Check ingress            | `kubectl describe ingress <name>`                               |
| Edit ingress             | `kubectl edit ingress <name>`                                   |
| Get Gateway              | `kubectl get gateway -n <ns> -o yaml`                           |
| Get HTTPRoute            | `kubectl get httproute -n <ns> -o yaml`                         |
| Get PV/PVC               | `kubectl get pv,pvc`                                            |
| Describe ResourceQuota   | `kubectl describe resourcequota <name>`                         |
| Check container runtime  | `crictl ps -a`                                                  |
| Exec into pod            | `kubectl exec -it <pod> -n <ns> -- <cmd>`                       |
| View pod events          | `kubectl describe pod <name> -n <ns>`                           |

## Quick Reference — Key `kubeadm` Commands

| Action                           | Command                                     |
| -------------------------------- | ------------------------------------------- |
| Check kubeadm version            | `kubeadm version`                           |
| Initialize a cluster             | `kubeadm init --pod-network-cidr=<cidr>`    |
| Generate join token              | `kubeadm token create --print-join-command` |
| List tokens                      | `kubeadm token list`                        |
| Reset node (remove from cluster) | `kubeadm reset`                             |
| Upgrade plan                     | `kubeadm upgrade plan`                      |
| Upgrade apply                    | `kubeadm upgrade apply v<version>`          |
| Upgrade node                     | `kubeadm upgrade node`                      |
| Check cluster config             | `kubeadm config print init-defaults`        |
| Install kubelet (apt)            | `sudo apt install -y kubelet=<version>`     |
| Start kubelet                    | `sudo systemctl enable --now kubelet`       |
| Check kubelet status             | `systemctl status kubelet`                  |
| View kubelet logs                | `journalctl -u kubelet -f`                  |
