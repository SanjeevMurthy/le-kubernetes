# CKA Mock Exam 1 — Refined Solutions

> **Source:** Udemy CKA Mock Test 1  
> **Total Questions:** 16  
> **Sections:** Workloads & Scheduling · Cluster Architecture, Installation & Configuration · Troubleshooting · Storage · Services & Networking

---

## Table of Contents

| #           | Section                | Topic                                 |
| ----------- | ---------------------- | ------------------------------------- |
| [Q1](#q1)   | Workloads & Scheduling | Horizontal Pod Autoscaler (HPA)       |
| [Q2](#q2)   | Cluster Architecture   | ClusterRole Permissions Update        |
| [Q3](#q3)   | Troubleshooting        | Kube Controller Manager Fix           |
| [Q4](#q4)   | Storage                | PVC Resize                            |
| [Q5](#q5)   | Cluster Architecture   | Helm Chart Debugging & Deployment     |
| [Q6](#q6)   | Services & Networking  | HTTPRoute (Gateway API)               |
| [Q7](#q7)   | Cluster Architecture   | ServiceAccount, ClusterRole & Binding |
| [Q8](#q8)   | Services & Networking  | DNS Lookup / nslookup                 |
| [Q9](#q9)   | —                      | _(No content in draft)_               |
| [Q10](#q10) | Workloads & Scheduling | Rollback & Scale Deployment           |
| [Q11](#q11) | Troubleshooting        | Secret Key Mismatch Fix               |
| [Q12](#q12) | Workloads & Scheduling | Rolling Update Strategy               |
| [Q13](#q13) | Services & Networking  | Ingress Resource                      |
| [Q14](#q14) | Troubleshooting        | Paused Deployment                     |
| [Q15](#q15) | Troubleshooting        | Service Port Mismatch                 |
| [Q16](#q16) | Storage                | StorageClass Creation                 |

---

<a id="q1"></a>

## Q1 — Horizontal Pod Autoscaler (HPA)

**Section:** Workloads & Scheduling  
**Cluster:** `ssh cluster1-controlplane`

### Question

In the `default` namespace, there is a deployment called `frontend-deployment`. Create a Horizontal Pod Autoscaler (HPA), also called `frontend-deployment`, that keeps the average CPU utilization of the deployment's pods to **70%**, limiting the number of pods from a minimum of **2** to a maximum of **10**.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Option A: Imperative command (fastest)

```bash
kubectl autoscale deployment frontend-deployment \
  --name=frontend-deployment \
  --cpu-percent=70 \
  --min=2 \
  --max=10
```

#### Step 2 — Option B: Declarative YAML

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: frontend-deployment
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: frontend-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

```bash
kubectl apply -f hpa.yaml
```

### Validation

```bash
# Check that HPA was created and targets the correct deployment
kubectl get hpa frontend-deployment

# Verify HPA details
kubectl describe hpa frontend-deployment
```

Expected output should show `REFERENCE: Deployment/frontend-deployment`, `MINPODS: 2`, `MAXPODS: 10`, and `TARGETS: <cpu>/70%`.

### 📖 Official Documentation

- [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [HPA Walkthrough](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)

---

<a id="q2"></a>

## Q2 — Update ClusterRole Permissions

**Section:** Cluster Architecture, Installation & Configuration  
**Cluster:** `ssh cluster1-controlplane`

### Question

A service account `green-sa-cka22-arch`, a cluster role `green-role-cka22-arch`, and a cluster role binding `green-role-binding-cka22-arch` already exist. Update the permissions of this service account so that it can **only get all the namespaces** in cluster1.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Edit the ClusterRole

```bash
kubectl edit clusterrole green-role-cka22-arch
```

Replace or add the following rules section:

```yaml
rules:
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["get"]
```

> **Tip:** `namespaces` belong to the core API group (`""`), not `"*"`. Using `""` is more precise and follows the principle of least privilege.

### Validation

```bash
# Confirm the service account can get namespaces
kubectl auth can-i get namespaces \
  --as=system:serviceaccount:default:green-sa-cka22-arch
# Expected: yes

# Confirm it cannot list or delete namespaces
kubectl auth can-i list namespaces \
  --as=system:serviceaccount:default:green-sa-cka22-arch
# Expected: no

kubectl auth can-i delete namespaces \
  --as=system:serviceaccount:default:green-sa-cka22-arch
# Expected: no
```

### 📖 Official Documentation

- [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [ClusterRole and ClusterRoleBinding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#clusterrole-example)

---

<a id="q3"></a>

## Q3 — Troubleshoot Kube Controller Manager

**Section:** Troubleshooting  
**Cluster:** `ssh cluster4-controlplane`

### Question

The `pink-depl-cka14-trb` Deployment was scaled to 2 replicas; however, the current replica count is still 1. Troubleshoot and fix the issue so that the CURRENT count equals the DESIRED count.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster4-controlplane
```

#### Step 2 — Verify the deployment status

```bash
kubectl get deployment pink-depl-cka14-trb
```

You will see `DESIRED: 2` but `CURRENT: 1`.

#### Step 3 — Check the kube-controller-manager

```bash
kubectl get pods -n kube-system | grep controller
```

The kube-controller-manager pod will be in a `CrashLoopBackOff` state.

#### Step 4 — Inspect the events for the root cause

```bash
kubectl get events -n kube-system \
  --field-selector involvedObject.name=kube-controller-manager-cluster4-controlplane
```

Look for an error like:

```
exec: "kube-controller-manage": executable file not found in $PATH
```

The binary name is truncated — `kube-controller-manage` instead of `kube-controller-manager`.

#### Step 5 — Fix the static pod manifest

```bash
vi /etc/kubernetes/manifests/kube-controller-manager.yaml
```

Under `spec.containers[0].command`, find and fix:

```diff
- - kube-controller-manage
+ - kube-controller-manager
```

Save the file. The kubelet will automatically restart the pod.

#### Step 6 — Wait and verify

```bash
# Wait for the controller manager to become Running
kubectl get pods -n kube-system -w | grep controller

# Verify the deployment now has 2/2 replicas
kubectl get deployment pink-depl-cka14-trb
```

### Validation

```bash
kubectl get deployment pink-depl-cka14-trb
# READY should show 2/2
```

### 📖 Official Documentation

- [Troubleshooting Clusters](https://kubernetes.io/docs/tasks/debug/debug-cluster/)
- [Static Pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
- [kube-controller-manager](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/)

---

<a id="q4"></a>

## Q4 — Resize a Persistent Volume Claim

**Section:** Storage  
**Cluster:** `ssh cluster1-controlplane`

### Question

A PV `papaya-pv-cka09-str` (150Mi, storage class `papaya-stc-cka09-str`, path `/opt/papaya-stc-cka09-str`) and a PVC `papaya-pvc-cka09-str` (50Mi) already exist. Resize the PVC to **80Mi** and make sure the PVC is in the **Bound** state.

### Solution

> **Note:** Since the storage class likely does **not** have `allowVolumeExpansion: true`, a simple `kubectl edit pvc` won't work. We need to delete and recreate the PVC with the updated size, and clean up the PV's `claimRef` so it can rebind.

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Export the PV and PVC definitions

```bash
kubectl get pv papaya-pv-cka09-str -o yaml > /tmp/papaya-pv.yaml
kubectl get pvc papaya-pvc-cka09-str -o yaml > /tmp/papaya-pvc.yaml
```

#### Step 3 — Edit the PV template

```bash
vi /tmp/papaya-pv.yaml
```

Remove these fields so the PV can rebind:

- `metadata.uid`
- `metadata.annotations`
- `metadata.resourceVersion`
- `metadata.creationTimestamp`
- `spec.claimRef` (entire block)
- `status` (entire block)

#### Step 4 — Edit the PVC template

```bash
vi /tmp/papaya-pvc.yaml
```

Change the storage request:

```diff
  resources:
    requests:
-     storage: 50Mi
+     storage: 80Mi
```

Also remove `metadata.uid`, `metadata.resourceVersion`, `metadata.creationTimestamp`, `metadata.annotations`, and `status`.

#### Step 5 — Delete the old PVC and PV, then recreate

```bash
kubectl delete pvc papaya-pvc-cka09-str
kubectl delete pv papaya-pv-cka09-str
kubectl apply -f /tmp/papaya-pv.yaml
kubectl apply -f /tmp/papaya-pvc.yaml
```

#### Alternative — Using `kubectl patch`

```bash
# Remove claimRef so PV can rebind
kubectl patch pv papaya-pv-cka09-str --type=json \
  -p='[{"op": "remove", "path": "/spec/claimRef"}]'

# Update PVC storage request
kubectl patch pvc papaya-pvc-cka09-str --type=json \
  -p='[{"op": "replace", "path": "/spec/resources/requests/storage", "value": "80Mi"}]'
```

> ⚠️ The patch approach may not work if the storage class doesn't allow volume expansion. The delete-and-recreate approach is the safest.

### Validation

```bash
kubectl get pvc papaya-pvc-cka09-str
# STATUS should be "Bound" and CAPACITY should be "80Mi" (or up to 150Mi)

kubectl get pv papaya-pv-cka09-str
# STATUS should be "Bound" and CLAIM should reference papaya-pvc-cka09-str
```

### 📖 Official Documentation

- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Expanding PVCs](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#expanding-persistent-volumes-claims)

---

<a id="q5"></a>

## Q5 — Helm Chart Debugging & Deployment

**Section:** Cluster Architecture, Installation & Configuration  
**Cluster:** `ssh cluster2-controlplane`

### Question

A Helm chart repository is given under `/opt/`. Fix any issues and deploy with:

- Release name: `webapp-color-apd`
- Namespace: `frontend-apd`
- Service type: NodePort
- Replica count: 3
- Application version: 1.20.0

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster2-controlplane
```

#### Step 2 — Create the namespace if it doesn't exist

```bash
kubectl create ns frontend-apd --dry-run=client -o yaml | kubectl apply -f -
```

#### Step 3 — Update `Chart.yaml`

```bash
vi /opt/webapp-color-apd/Chart.yaml
```

Set the application version:

```yaml
appVersion: "1.20.0"
```

#### Step 4 — Update `values.yaml`

```bash
vi /opt/webapp-color-apd/values.yaml
```

```yaml
replicaCount: 3

service:
  type: NodePort
```

#### Step 5 — Fix template issues

**a) Fix Deployment API version:**

```bash
vi /opt/webapp-color-apd/templates/deployment.yaml
```

```diff
- apiVersion: app/v1
+ apiVersion: apps/v1
```

**b) Fix Service template variable typo:**

```bash
vi /opt/webapp-color-apd/templates/service.yaml
```

Fix the typo in the template variable reference (e.g., `{{ .Values.service.name }}` → ensure it matches the key defined in `values.yaml`).

#### Step 6 — Lint the chart

```bash
helm lint /opt/webapp-color-apd/
```

Expected output:

```
==> Linting /opt/webapp-color-apd/
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

#### Step 7 — Install the chart

```bash
helm install webapp-color-apd /opt/webapp-color-apd/ -n frontend-apd
```

### Validation

```bash
# Verify the Helm release
helm ls -n frontend-apd

# Verify the deployment has 3 replicas
kubectl get deploy -n frontend-apd

# Verify the service is NodePort
kubectl get svc -n frontend-apd

# Check app version
helm get metadata webapp-color-apd -n frontend-apd
```

### 📖 Official Documentation

- [Helm Documentation](https://helm.sh/docs/)
- [Helm Install](https://helm.sh/docs/helm/helm_install/)
- [Helm Lint](https://helm.sh/docs/helm/helm_lint/)

---

<a id="q6"></a>

## Q6 — Create an HTTPRoute (Gateway API)

**Section:** Services & Networking  
**Cluster:** `ssh cluster2-controlplane`

### Question

Create an HTTPRoute named `web-route` in the `nginx-gateway` namespace that directs traffic from the `web-gateway` to a backend service named `web-service` on port 80, applied only to requests with hostname `cluster2-controlplane`.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster2-controlplane
```

#### Step 2 — Apply the HTTPRoute manifest

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: nginx-gateway
spec:
  hostnames:
    - cluster2-controlplane
  parentRefs:
    - name: web-gateway
  rules:
    - backendRefs:
        - name: web-service
          port: 80
```

```bash
kubectl apply -f httproute.yaml
```

### Validation

```bash
# Verify the HTTPRoute was created
kubectl get httproute -n nginx-gateway

# Describe the HTTPRoute to check parent references and rules
kubectl describe httproute web-route -n nginx-gateway

# Test connectivity
curl http://cluster2-controlplane:30080
```

### 📖 Official Documentation

- [Gateway API — HTTPRoute](https://gateway-api.sigs.k8s.io/api-types/httproute/)
- [Kubernetes Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/)

---

<a id="q7"></a>

## Q7 — ServiceAccount, ClusterRole & ClusterRoleBinding

**Section:** Cluster Architecture, Installation & Configuration  
**Cluster:** `ssh cluster1-controlplane`

### Question

Create:

1. A service account called `deploy-cka20-arch`
2. A cluster role called `deploy-role-cka20-arch` with permissions to **get** deployments
3. A cluster role binding called `deploy-role-binding-cka20-arch` to bind them together

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Create the ServiceAccount

```bash
kubectl create serviceaccount deploy-cka20-arch
```

#### Step 3 — Create the ClusterRole

```bash
kubectl create clusterrole deploy-role-cka20-arch \
  --resource=deployments \
  --verb=get
```

#### Step 4 — Create the ClusterRoleBinding

```bash
kubectl create clusterrolebinding deploy-role-binding-cka20-arch \
  --clusterrole=deploy-role-cka20-arch \
  --serviceaccount=default:deploy-cka20-arch
```

### Validation

```bash
# Verify permissions
kubectl auth can-i get deployments \
  --as=system:serviceaccount:default:deploy-cka20-arch
# Expected: yes

# Verify no extra permissions
kubectl auth can-i list deployments \
  --as=system:serviceaccount:default:deploy-cka20-arch
# Expected: no

# Inspect the objects
kubectl get sa deploy-cka20-arch
kubectl get clusterrole deploy-role-cka20-arch
kubectl get clusterrolebinding deploy-role-binding-cka20-arch
```

### 📖 Official Documentation

- [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Service Accounts](https://kubernetes.io/docs/concepts/security/service-accounts/)
- [kubectl create clusterrole](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/kubectl_create_clusterrole/)

---

<a id="q8"></a>

## Q8 — DNS Lookup with nslookup

**Section:** Services & Networking  
**Cluster:** `ssh cluster1-controlplane`

### Question

Create an nginx pod `nginx-resolver-cka06-svcn` and expose it internally with a service `nginx-resolver-service-cka06-svcn`. Test DNS lookup for the service and pod using `busybox:1.28` and record results to `/root/CKA/nginx.svc.cka06.svcn` and `/root/CKA/nginx.pod.cka06.svcn`.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Create the pod and service

```bash
kubectl run nginx-resolver-cka06-svcn --image=nginx

kubectl expose pod nginx-resolver-cka06-svcn \
  --name=nginx-resolver-service-cka06-svcn \
  --port=80 \
  --target-port=80 \
  --type=ClusterIP
```

#### Step 3 — Wait for the pod to be Running

```bash
kubectl wait pod nginx-resolver-cka06-svcn --for=condition=Ready --timeout=60s
```

#### Step 4 — Create the output directory

```bash
mkdir -p /root/CKA
```

#### Step 5 — Perform service DNS lookup and save results

```bash
kubectl run test-nslookup --image=busybox:1.28 --rm -it --restart=Never \
  -- nslookup nginx-resolver-service-cka06-svcn > /root/CKA/nginx.svc.cka06.svcn
```

#### Step 6 — Get the pod IP and perform pod DNS lookup

```bash
# Get the pod IP and convert dots to hyphens for the DNS record
IP=$(kubectl get pod nginx-resolver-cka06-svcn -o jsonpath='{.status.podIP}' | tr '.' '-')

# Perform pod DNS lookup
kubectl run test-nslookup --image=busybox:1.28 --rm -it --restart=Never \
  -- nslookup ${IP}.default.pod > /root/CKA/nginx.pod.cka06.svcn
```

> **Tip:** Pod DNS records in Kubernetes follow the format `<pod-ip-with-hyphens>.<namespace>.pod.cluster.local`.

### Validation

```bash
# Verify the service lookup output
cat /root/CKA/nginx.svc.cka06.svcn
# Should contain: Name: nginx-resolver-service-cka06-svcn

# Verify the pod lookup output
cat /root/CKA/nginx.pod.cka06.svcn
# Should contain a Name entry with the pod IP in hyphenated format
```

### 📖 Official Documentation

- [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Debugging DNS Resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)

---

<a id="q9"></a>

## Q9 — _(No content provided in the draft)_

---

<a id="q10"></a>

## Q10 — Rollback Deployment & Scale

**Section:** Workloads & Scheduling  
**Cluster:** `ssh cluster1-controlplane`

### Question

In the `dev-wl07` namespace, a rolling update has broken the application. Roll back to the previous version, save the current image name to `/root/rolling-back-record.txt`, and increase the replica count to **5**.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Check the current status

```bash
kubectl get pods -n dev-wl07
kubectl get deploy -n dev-wl07 webapp-wl07
```

You will see pods in an error state (e.g., `ErrImagePull` or `ImagePullBackOff`).

#### Step 3 — Rollback to the previous revision

```bash
kubectl rollout undo deployment webapp-wl07 -n dev-wl07
```

#### Step 4 — Wait for rollout to complete

```bash
kubectl rollout status deployment webapp-wl07 -n dev-wl07
```

#### Step 5 — Identify the current image and save it

```bash
kubectl describe deploy webapp-wl07 -n dev-wl07 | grep -i "image:"
# Note the image name (e.g., kodekloud/webapp-color)

# Save to the required file
kubectl get deploy webapp-wl07 -n dev-wl07 \
  -o jsonpath='{.spec.template.spec.containers[0].image}' > /root/rolling-back-record.txt
```

#### Step 6 — Scale the deployment to 5 replicas

```bash
kubectl scale deploy webapp-wl07 -n dev-wl07 --replicas=5
```

### Validation

```bash
# Verify all 5 replicas are running
kubectl get deploy webapp-wl07 -n dev-wl07
# READY should show 5/5

# Verify the saved image
cat /root/rolling-back-record.txt

# Verify pods are running
kubectl get pods -n dev-wl07
```

### 📖 Official Documentation

- [Performing a Rollback](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)
- [Scaling a Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#scaling-a-deployment)
- [kubectl rollout](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/)

---

<a id="q11"></a>

## Q11 — Fix Secret Key References in Deployment

**Section:** Troubleshooting  
**Cluster:** `ssh cluster1-controlplane`

### Question

The `db-deployment-cka05-trb` deployment has 0 out of 1 PODs ready. Fix the issues without removing/renaming any DB-related env variable names and without modifying existing Secret contents/keys.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Check the pod status

```bash
kubectl get pods | grep db-deployment
kubectl describe pod <pod-name>
```

Look for `CreateContainerConfigError` in the status.

#### Step 3 — Check events for the specific error

```bash
kubectl get events --field-selector involvedObject.name=<pod-name>
```

You will see: `Error: couldn't find key db in Secret default/db-cka05-trb`

#### Step 4 — Inspect the existing secrets to find the correct keys

```bash
kubectl get secret db-cka05-trb -o jsonpath='{.data}' | python3 -m json.tool
kubectl get secret db-user-pass-cka05-trb -o jsonpath='{.data}' | python3 -m json.tool
kubectl get secret db-root-pass-cka05-trb -o jsonpath='{.data}' | python3 -m json.tool
```

Note the actual key names available in each secret.

#### Step 5 — Edit the deployment to fix the key references

```bash
kubectl edit deployment db-deployment-cka05-trb
```

Make the following corrections:

| Environment Variable | Wrong Key     | Correct Key |
| -------------------- | ------------- | ----------- |
| `MYSQL_DATABASE`     | `db`          | `database`  |
| `MYSQL_USER`         | `db-user`     | `username`  |
| `MYSQL_PASSWORD`     | `db-password` | `password`  |

Also fix the secret name reference:

```diff
- secretKeyRef:
-   name: db-user-cka05-trb        # Wrong secret name
+ secretKeyRef:
+   name: db-user-pass-cka05-trb   # Correct secret name
```

Save and exit.

### Validation

```bash
# Wait for the new pod to start
kubectl get pods | grep db-deployment
# STATUS should be Running and READY should be 1/1

# Check the pod logs
kubectl logs <new-pod-name>
# Should show MySQL startup messages without errors
```

### 📖 Official Documentation

- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Using Secrets as Environment Variables](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables)

---

<a id="q12"></a>

## Q12 — Deployment with Rolling Update Strategy

**Section:** Workloads & Scheduling  
**Cluster:** `ssh cluster1-controlplane`

### Question

Create deployment `ocean-tv-wl09` using `kodekloud/webapp-color:v1` with 3 replicas, maxUnavailable 40%, maxSurge 55%. Upgrade to `v2`, record revision count, then rollback.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Create the deployment YAML

```bash
cat <<EOF > /tmp/ocean-tv-wl09.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ocean-tv-wl09
  labels:
    app: ocean-tv-wl09
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ocean-tv-wl09
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 40%
      maxSurge: 55%
  template:
    metadata:
      labels:
        app: ocean-tv-wl09
    spec:
      containers:
        - name: webapp-color
          image: kodekloud/webapp-color:v1
EOF
```

#### Step 3 — Create the deployment

```bash
kubectl apply -f /tmp/ocean-tv-wl09.yaml
```

#### Step 4 — Wait for all pods to be ready

```bash
kubectl rollout status deploy ocean-tv-wl09
```

#### Step 5 — Upgrade to v2

```bash
kubectl set image deploy ocean-tv-wl09 webapp-color=kodekloud/webapp-color:v2
```

#### Step 6 — Check rollout status

```bash
kubectl rollout status deploy ocean-tv-wl09
```

#### Step 7 — Check rollout history and save revision count

```bash
kubectl rollout history deploy ocean-tv-wl09
```

Output will show revision numbers (e.g., revision 2). Save the current revision:

```bash
kubectl rollout history deploy ocean-tv-wl09 --revision=0 2>/dev/null | head -1
# Or simply:
echo "2" > /opt/revision-count.txt
```

#### Step 8 — Rollback to previous version

```bash
kubectl rollout undo deploy ocean-tv-wl09
```

### Validation

```bash
# Verify the image is back to v1
kubectl describe deploy ocean-tv-wl09 | grep -i "image:"
# Expected: kodekloud/webapp-color:v1

# Verify replicas
kubectl get deploy ocean-tv-wl09
# READY should show 3/3

# Verify strategy
kubectl get deploy ocean-tv-wl09 -o jsonpath='{.spec.strategy}' | python3 -m json.tool
# Should show maxUnavailable: 40%, maxSurge: 55%

# Verify revision file
cat /opt/revision-count.txt
```

### 📖 Official Documentation

- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Rolling Update Strategy](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-update-deployment)
- [Rollback a Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)

---

<a id="q13"></a>

## Q13 — Create an Ingress Resource

**Section:** Services & Networking  
**Cluster:** `ssh cluster3-controlplane`

### Question

Create an ingress resource `nginx-ingress-cka04-svcn` for the existing deployment `nginx-deployment-cka04-svcn` (exposed via `nginx-service-cka04-svcn`) with:

- `ingressClassName: nginx-cka04`
- `pathType: Prefix`, path: `/`
- Backend: `nginx-service-cka04-svcn` on port `80`
- SSL redirect set to `false`

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster3-controlplane
```

#### Step 2 — Apply the Ingress manifest

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress-cka04-svcn
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx-cka04
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-service-cka04-svcn
                port:
                  number: 80
EOF
```

### Validation

```bash
# Verify the ingress was created
kubectl get ingress nginx-ingress-cka04-svcn

# Get the ingress address
kubectl describe ingress nginx-ingress-cka04-svcn

# Test connectivity using the ADDRESS from the above output
curl -I <INGRESS-ADDRESS>
# Expected: HTTP/1.1 200 OK
```

### 📖 Official Documentation

- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)

---

<a id="q14"></a>

## Q14 — Resume a Paused Deployment

**Section:** Troubleshooting  
**Cluster:** `ssh cluster1-controlplane`

### Question

The `black-cka25-trb` deployment shows **0** under the `UP-TO-DATE` column. Troubleshoot and fix the issue.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Check the deployment status

```bash
kubectl get deploy black-cka25-trb
```

Notice `UP-TO-DATE: 0`.

#### Step 3 — Inspect the deployment for the cause

```bash
kubectl get deploy black-cka25-trb -o yaml | grep -A2 "status:"
```

Look for `message: Deployment is paused`.

```bash
kubectl rollout status deployment black-cka25-trb
# Output: Waiting for deployment "black-cka25-trb" rollout to finish: 0 out of 1 new replicas have been updated...
```

#### Step 4 — Resume the deployment

```bash
kubectl rollout resume deployment black-cka25-trb
```

### Validation

```bash
# Wait for rollout to complete
kubectl rollout status deployment black-cka25-trb
# Expected: deployment "black-cka25-trb" successfully rolled out

# Verify UP-TO-DATE is no longer 0
kubectl get deploy black-cka25-trb
# UP-TO-DATE should match DESIRED
```

### 📖 Official Documentation

- [Pausing and Resuming a Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#pausing-and-resuming-a-rollout-of-a-deployment)

---

<a id="q15"></a>

## Q15 — Fix Service Port Mismatch

**Section:** Troubleshooting  
**Cluster:** `ssh cluster1-controlplane`

### Question

The `purple-app-cka27-trb` pod runs nginx on container port 80 and is exposed via `purple-svc-cka27-trb` (ClusterIP). The monitoring pod `purple-curl-cka27-trb` reports errors when accessing the service. Identify and fix the issue.

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Check the monitoring pod logs

```bash
kubectl logs purple-curl-cka27-trb
```

You will see: `Not able to connect to the nginx app on http://purple-svc-cka27-trb`

#### Step 3 — Inspect the service configuration

```bash
kubectl get svc purple-svc-cka27-trb -o yaml
```

Notice that `port` and `targetPort` are set to `8080`, but nginx listens on port `80`.

#### Step 4 — Fix the service ports

```bash
kubectl edit svc purple-svc-cka27-trb
```

Change both `port` and `targetPort` from `8080` to `80`:

```diff
  ports:
-   - port: 8080
-     targetPort: 8080
+   - port: 80
+     targetPort: 80
```

Save and exit.

### Validation

```bash
# Test from within the cluster
kubectl exec -it purple-app-cka27-trb -- curl http://purple-svc-cka27-trb
# Expected: nginx welcome page HTML

# Check the monitoring pod logs
kubectl logs purple-curl-cka27-trb
# Should show: "Thank you for using nginx."
```

### 📖 Official Documentation

- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Debugging Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)

---

<a id="q16"></a>

## Q16 — Create a StorageClass

**Section:** Storage  
**Cluster:** `ssh cluster1-controlplane`

### Question

Create a StorageClass named `banana-sc-cka08-str` with:

- Provisioner: `kubernetes.io/no-provisioner`
- Volume binding mode: `WaitForFirstConsumer`
- Volume expansion: enabled

### Solution

#### Step 1 — SSH into the control plane

```bash
ssh cluster1-controlplane
```

#### Step 2 — Create the StorageClass YAML

```bash
cat <<EOF > /tmp/banana-sc.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: banana-sc-cka08-str
provisioner: kubernetes.io/no-provisioner
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF
```

#### Step 3 — Apply the manifest

```bash
kubectl apply -f /tmp/banana-sc.yaml
```

### Validation

```bash
# Verify the StorageClass was created
kubectl get sc banana-sc-cka08-str

# Verify the details
kubectl describe sc banana-sc-cka08-str
# Check:
#   Provisioner:           kubernetes.io/no-provisioner
#   VolumeBindingMode:     WaitForFirstConsumer
#   AllowVolumeExpansion:  True
```

### 📖 Official Documentation

- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Volume Binding Mode](https://kubernetes.io/docs/concepts/storage/storage-classes/#volume-binding-mode)

---

## Quick Reference — Key `kubectl` Commands

| Action                    | Command                                                                                    |
| ------------------------- | ------------------------------------------------------------------------------------------ |
| Create HPA                | `kubectl autoscale deployment <name> --cpu-percent=70 --min=2 --max=10`                    |
| Create ServiceAccount     | `kubectl create sa <name>`                                                                 |
| Create ClusterRole        | `kubectl create clusterrole <name> --resource=<res> --verb=<verb>`                         |
| Create ClusterRoleBinding | `kubectl create clusterrolebinding <name> --clusterrole=<role> --serviceaccount=<ns>:<sa>` |
| Check RBAC                | `kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa>`                |
| Rollback                  | `kubectl rollout undo deployment <name>`                                                   |
| Resume paused rollout     | `kubectl rollout resume deployment <name>`                                                 |
| Scale deployment          | `kubectl scale deploy <name> --replicas=<n>`                                               |
| DNS lookup                | `kubectl run tmp --image=busybox:1.28 --rm -it --restart=Never -- nslookup <svc>`          |
| Helm lint                 | `helm lint <chart-path>`                                                                   |
| Helm install              | `helm install <release> <chart-path> -n <ns>`                                              |
