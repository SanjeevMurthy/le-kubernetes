# CKAD kubectl Cheatsheet — Imperative Commands & YAML-Only Resources

> Derived from all practice questions in `ckad-exam-qa-guide.md` and `ckad-trevor.md`.
> Organized for speed during the 2-hour CKAD exam.

---

## Table of Contents

- [The Golden Pattern: Generate → Edit → Apply](#the-golden-pattern-generate--edit--apply)
- [Part 1: Resources Creatable with Imperative Commands](#part-1-resources-creatable-with-imperative-commands)
  - [Pod](#pod)
  - [Deployment](#deployment)
  - [Service](#service)
  - [CronJob](#cronjob)
  - [Job](#job)
  - [Secret](#secret)
  - [ConfigMap](#configmap)
  - [ServiceAccount](#serviceaccount)
  - [Role and RoleBinding](#role-and-rolebinding)
  - [ClusterRole and ClusterRoleBinding](#clusterrole-and-clusterrolebinding)
  - [Namespace](#namespace)
  - [ResourceQuota](#resourcequota)
  - [Ingress](#ingress)
- [Part 2: Resources That CANNOT Be Created Imperatively](#part-2-resources-that-cannot-be-created-imperatively)
  - [NetworkPolicy](#networkpolicy)
  - [PersistentVolumeClaim (PVC)](#persistentvolumeclaim-pvc)
  - [PersistentVolume (PV)](#persistentvolume-pv)
  - [LimitRange](#limitrange)
- [Part 3: Features That Require YAML Editing](#part-3-features-that-require-yaml-editing)
  - [Liveness and Readiness Probes](#liveness-and-readiness-probes)
  - [SecurityContext](#securitycontext)
  - [Tolerations](#tolerations)
  - [Node Affinity](#node-affinity)
  - [Resource Requests and Limits](#resource-requests-and-limits)
  - [Volume Mounts](#volume-mounts)
  - [Multi-Container Pods (Sidecar / Init)](#multi-container-pods-sidecar--init)
  - [Rolling Update Strategy (maxSurge / maxUnavailable)](#rolling-update-strategy-maxsurge--maxunavailable)
  - [CronJob Advanced Fields (completions / backoffLimit)](#cronjob-advanced-fields-completions--backofflimit)
- [Part 4: Operational Commands](#part-4-operational-commands)
  - [Rollouts (Update, Undo, History)](#rollouts-update-undo-history)
  - [Scaling](#scaling)
  - [Taints and Labels on Nodes](#taints-and-labels-on-nodes)
  - [Labels on Pods](#labels-on-pods)
  - [Resource Metrics (kubectl top)](#resource-metrics-kubectl-top)
  - [Debugging and Inspection](#debugging-and-inspection)
  - [Events](#events)
  - [Exec into Pods](#exec-into-pods)
- [Part 5: Essential Flags Reference](#part-5-essential-flags-reference)
- [Part 6: Quick Decision Matrix — Imperative vs YAML?](#part-6-quick-decision-matrix--imperative-vs-yaml)

---

## The Golden Pattern: Generate → Edit → Apply

**This is the single most important pattern for the CKAD exam.** Never write YAML from scratch. Generate a scaffold imperatively, edit the parts you need, and apply.

```bash
# Step 1: Generate YAML scaffold
kubectl run my-pod --image=nginx --dry-run=client -o yaml > my-pod.yaml

# Step 2: Edit YAML (add probes, volumes, securityContext, etc.)
vim my-pod.yaml

# Step 3: Apply
kubectl apply -f my-pod.yaml
```

**Works with:** `kubectl run`, `kubectl create deployment`, `kubectl create cronjob`, `kubectl create job`, `kubectl create service`, `kubectl expose`, `kubectl create ingress`.

> **Exam tip:** If you need to modify an existing running resource and the fields are immutable (probes, volumes, containers), export → edit → delete → apply:
> ```bash
> kubectl get pod my-pod -o yaml > my-pod.yaml
> # Edit the YAML
> kubectl delete pod my-pod
> kubectl apply -f my-pod.yaml
> ```

---

## Part 1: Resources Creatable with Imperative Commands

### Pod

```bash
# Create a basic pod
kubectl run nginx-pod --image=nginx

# Create in a specific namespace
kubectl run nginx-pod --image=nginx -n my-namespace

# Create with port exposed
kubectl run nginx-pod --image=nginx --port=80

# Create with labels
kubectl run nginx-pod --image=nginx --labels="app=web,tier=frontend"

# Create with a command
kubectl run busybox-pod --image=busybox --command -- sleep 3600

# Create with restart policy (for one-off tasks)
kubectl run temp-pod --image=busybox --restart=Never -- echo "hello"

# Generate YAML only (most common exam pattern)
kubectl run nginx-pod --image=nginx --dry-run=client -o yaml > pod.yaml
```

### Deployment

```bash
# Create a deployment
kubectl create deployment web-app --image=nginx

# Create with replicas
kubectl create deployment web-app --image=nginx --replicas=3

# Create in a specific namespace
kubectl create deployment web-app --image=nginx --replicas=3 -n my-namespace

# Create with port
kubectl create deployment web-app --image=nginx --port=80

# Generate YAML only
kubectl create deployment web-app --image=nginx --replicas=3 --dry-run=client -o yaml > deploy.yaml
```

### Service

```bash
# Expose a deployment as ClusterIP (default)
kubectl expose deployment web-app --port=80 --target-port=8080

# Expose as NodePort
kubectl expose deployment web-app --port=80 --target-port=8080 --type=NodePort

# Expose with a custom service name
kubectl expose deployment web-app --name=web-svc --port=80 --target-port=8080 --type=NodePort

# Expose a pod directly
kubectl expose pod nginx-pod --port=80 --target-port=80 --type=ClusterIP

# Alternative: create service directly (useful when deployment doesn't exist yet)
kubectl create service nodeport web-svc --tcp=80:8080 --dry-run=client -o yaml > svc.yaml
# ⚠ Note: kubectl create service sets selector to app=web-svc (matches service name),
#   NOT the deployment name. You may need to edit the selector.

# Generate YAML only
kubectl expose deployment web-app --port=80 --type=NodePort --dry-run=client -o yaml > svc.yaml
```

> **Exam pitfall:** `kubectl create service nodeport` sets the selector to `app: <service-name>`, not the deployment's labels. Always verify with `kubectl get svc <name> -o yaml | grep -A5 selector`. Prefer `kubectl expose deployment` which auto-matches the deployment's selector.

### CronJob

```bash
# Create a CronJob
kubectl create cronjob my-cron --image=busybox --schedule="*/5 * * * *" -- echo "hello"

# Generate YAML only (to add completions, backoffLimit, activeDeadlineSeconds)
kubectl create cronjob my-cron --image=busybox --schedule="*/1 * * * *" \
  --dry-run=client -o yaml > cronjob.yaml
```

### Job

```bash
# Create a Job from an existing CronJob (exam favorite!)
kubectl create job test-job --from=cronjob/my-cron

# Create a Job in a specific namespace
kubectl create job test-job --from=cronjob/report-generator -n analytics

# Create a standalone Job
kubectl create job my-job --image=busybox -- echo "hello"

# Generate YAML only
kubectl create job my-job --image=busybox --dry-run=client -o yaml > job.yaml
```

### Secret

```bash
# Create from literal key-value pairs
kubectl create secret generic db-creds \
  --from-literal=username=admin \
  --from-literal=password='P@ssw0rd123'

# Create from a file
kubectl create secret generic db-creds --from-file=/opt/credentials/db-config.txt

# Create from a file with a custom key name
kubectl create secret generic db-creds --from-file=config=/opt/credentials/db-config.txt

# Create in a namespace
kubectl create secret generic db-creds -n my-namespace --from-literal=key=value

# Decode a secret value
kubectl get secret db-creds -o jsonpath='{.data.username}' | base64 -d
```

### ConfigMap

```bash
# Create from literal key-value pairs
kubectl create configmap app-config --from-literal=key1=value1 --from-literal=key2=value2

# Create from a file
kubectl create configmap web-config --from-file=/opt/index.html

# Create from a file with a custom key name
kubectl create configmap web-config --from-file=index.html=/opt/index.html

# Create from a directory (each file becomes a key)
kubectl create configmap app-config --from-file=/opt/configs/
```

### ServiceAccount

```bash
# Create a service account
kubectl create serviceaccount my-sa

# Create in a namespace
kubectl create serviceaccount my-sa -n my-namespace
```

### Role and RoleBinding

```bash
# Create a Role (namespace-scoped permissions)
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n my-namespace

# Create a Role with multiple resource types
kubectl create role full-access \
  --verb=get,list,watch,create,update,delete \
  --resource=pods,deployments,services \
  -n my-namespace

# Create a RoleBinding (bind Role to ServiceAccount)
kubectl create rolebinding pod-reader-binding \
  --role=pod-reader \
  --serviceaccount=my-namespace:my-sa \
  -n my-namespace

# Create a RoleBinding (bind Role to a User)
kubectl create rolebinding pod-reader-binding \
  --role=pod-reader \
  --user=jane \
  -n my-namespace
```

> **Exam gotcha:** The `--serviceaccount` flag format is `<namespace>:<sa-name>`, not just the SA name.

### ClusterRole and ClusterRoleBinding

```bash
# Create a ClusterRole (cluster-wide permissions)
kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes

# Create a ClusterRoleBinding
kubectl create clusterrolebinding node-reader-binding \
  --clusterrole=node-reader \
  --serviceaccount=default:my-sa
```

### Namespace

```bash
# Create a namespace
kubectl create namespace my-namespace

# Short form
kubectl create ns my-namespace
```

### ResourceQuota

```bash
# Create a resource quota
kubectl create quota my-quota \
  --hard=cpu=1,memory=1G,pods=10 \
  -n my-namespace
```

### Ingress

```bash
# Create an Ingress with a simple rule
kubectl create ingress web-ingress \
  --rule="web.example.com/=web-svc:80"

# Create with TLS
kubectl create ingress web-ingress \
  --rule="web.example.com/=web-svc:80,tls=web-tls"

# Create with path-based routing
kubectl create ingress api-ingress \
  --rule="example.com/api=api-svc:8080" \
  --rule="example.com/web=web-svc:80"

# Generate YAML only (recommended — often need annotations)
kubectl create ingress web-ingress \
  --rule="web.example.com/=web-svc:80" \
  --dry-run=client -o yaml > ingress.yaml
```

> **Note:** `kubectl create ingress` exists in kubectl 1.19+. You may still need to edit YAML for annotations like `nginx.ingress.kubernetes.io/rewrite-target`.

---

## Part 2: Resources That CANNOT Be Created Imperatively

These resources have **no `kubectl create` command** and **must** be written as YAML manifests.

### NetworkPolicy

**No imperative command exists.** Must write full YAML.

```yaml
# Example: Allow ingress from pods with label app=frontend only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
  namespace: my-namespace
spec:
  podSelector:
    matchLabels:
      app: backend               # Apply to pods with this label
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend           # Allow traffic FROM these pods
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database           # Allow traffic TO these pods
    ports:
    - protocol: TCP
      port: 5432
```

```yaml
# Default deny all traffic in a namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: my-namespace
spec:
  podSelector: {}                 # Match ALL pods
  policyTypes:
  - Ingress
  - Egress
```

```yaml
# Allow traffic with CIDR exception
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-external
  namespace: my-namespace
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:
        cidr: 10.0.0.0/8
        except:
        - 10.0.5.0/24             # Block this specific subnet
```

> **Key rules:**
> - `podSelector: {}` = matches ALL pods in the namespace
> - If `policyTypes` includes `Ingress` but no `ingress` rules → all ingress denied
> - If `policyTypes` includes `Egress` but no `egress` rules → all egress denied
> - NetworkPolicies are additive — multiple policies combine (union), they don't override

### PersistentVolumeClaim (PVC)

**No imperative command exists.** Must write YAML.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: my-namespace
spec:
  accessModes:
  - ReadWriteOnce               # RWO | ReadWriteMany (RWX) | ReadOnlyMany (ROX)
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard     # Omit for default StorageClass
```

Then mount in a Pod:

```yaml
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: data-vol
      mountPath: /data
  volumes:
  - name: data-vol
    persistentVolumeClaim:
      claimName: data-pvc
```

### PersistentVolume (PV)

**No imperative command exists.** Rarely needed in CKAD (dynamic provisioning is more common), but here's the template:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: data-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain    # Retain | Delete | Recycle
  storageClassName: standard
  hostPath:
    path: /data/pv
```

### LimitRange

**No imperative command exists.** Used to set default resource limits for a namespace.

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: my-namespace
spec:
  limits:
  - default:                      # Default limits (if not specified)
      cpu: 500m
      memory: 256Mi
    defaultRequest:               # Default requests (if not specified)
      cpu: 100m
      memory: 128Mi
    type: Container
```

---

## Part 3: Features That Require YAML Editing

These features exist on resources that CAN be created imperatively, but the specific fields can only be added by editing the YAML. Use the **Generate → Edit → Apply** pattern.

### Liveness and Readiness Probes

```yaml
# Add under spec.containers[]
containers:
- name: app
  image: nginx
  livenessProbe:                  # Restart container if this fails
    httpGet:
      path: /healthz
      port: 8080
    initialDelaySeconds: 5
    periodSeconds: 10
    failureThreshold: 3
  readinessProbe:                 # Remove from Service endpoints if this fails
    httpGet:
      path: /started
      port: 8080
    initialDelaySeconds: 3
    periodSeconds: 5
```

Other probe types:

```yaml
# Exec probe
livenessProbe:
  exec:
    command: ["cat", "/tmp/healthy"]

# TCP socket probe
readinessProbe:
  tcpSocket:
    port: 8080
```

> **Memory aid:** "Restart" → Liveness. "Ready for traffic" → Readiness.

### SecurityContext

```yaml
# Pod-level
spec:
  securityContext:
    runAsUser: 1000               # UID for all containers
    runAsGroup: 3000
    fsGroup: 2000

# Container-level (overrides pod-level)
  containers:
  - name: app
    image: nginx
    securityContext:
      runAsUser: 1000
      allowPrivilegeEscalation: false
      capabilities:
        add: ["NET_ADMIN", "SYS_TIME"]
        drop: ["ALL"]
```

### Tolerations

```yaml
# Add under spec (pod-level)
spec:
  tolerations:
  - key: "app_type"
    value: "alpha"
    effect: "NoSchedule"
    operator: "Equal"             # Equal (match key+value) or Exists (match key only)
  containers:
  - name: app
    image: redis
```

### Node Affinity

```yaml
# Add under spec (pod-level)
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:    # Hard requirement
        nodeSelectorTerms:
        - matchExpressions:
          - key: app_type
            operator: In          # In, NotIn, Exists, DoesNotExist, Gt, Lt
            values:
            - beta
  containers:
  - name: app
    image: nginx
```

> **Simpler alternative:** `nodeSelector` — if the question doesn't require affinity specifically:
> ```yaml
> spec:
>   nodeSelector:
>     app_type: beta
> ```

### Resource Requests and Limits

```yaml
containers:
- name: app
  image: nginx
  resources:
    requests:
      cpu: 200m                   # Minimum guaranteed
      memory: 100Mi
    limits:
      cpu: 500m                   # Maximum allowed
      memory: 256Mi
```

### Volume Mounts

```yaml
# Secret as volume
spec:
  containers:
  - name: app
    volumeMounts:
    - name: secret-vol
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: secret-vol
    secret:
      secretName: db-creds

# ConfigMap as volume
  volumes:
  - name: config-vol
    configMap:
      name: app-config

# EmptyDir (shared between containers)
  volumes:
  - name: shared
    emptyDir: {}
```

Secret/ConfigMap as **environment variables** (no volume needed):

```yaml
containers:
- name: app
  env:
  - name: DB_USER
    valueFrom:
      secretKeyRef:
        name: db-creds
        key: username
  - name: APP_CONFIG
    valueFrom:
      configMapKeyRef:
        name: app-config
        key: key1
```

### Multi-Container Pods (Sidecar / Init)

```yaml
spec:
  initContainers:                 # Runs before main containers, must complete
  - name: init-db
    image: busybox
    command: ["sh", "-c", "until nslookup db-svc; do sleep 2; done"]
  containers:
  - name: app
    image: nginx
  - name: sidecar                 # Runs alongside main container
    image: busybox
    command: ["sh", "-c", "tail -f /var/log/app.log"]
```

### Rolling Update Strategy (maxSurge / maxUnavailable)

```yaml
# Under spec (Deployment-level, NOT under template)
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: "10%"             # Max pods ABOVE desired count during update
      maxUnavailable: "5%"        # Max pods BELOW desired count during update
```

Or via imperative patch:

```bash
kubectl patch deployment web -n my-ns -p \
  '{"spec":{"strategy":{"type":"RollingUpdate","rollingUpdate":{"maxSurge":"10%","maxUnavailable":"5%"}}}}'
```

### CronJob Advanced Fields (completions / backoffLimit)

```yaml
# Under spec.jobTemplate.spec (NOT under template)
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      completions: 2              # Number of successful completions needed
      backoffLimit: 3             # Number of retries before failing
      activeDeadlineSeconds: 28   # Kill the Job after this many seconds
      template:
        spec:
          containers:
          - name: worker
            image: busybox
            command: ["uname"]
          restartPolicy: OnFailure
```

---

## Part 4: Operational Commands

### Rollouts (Update, Undo, History)

```bash
# Update a deployment image
kubectl set image deployment/web nginx=nginx:1.25 -n my-ns

# Monitor rollout progress
kubectl rollout status deployment/web -n my-ns

# View rollout history
kubectl rollout history deployment/web -n my-ns

# Rollback to previous version
kubectl rollout undo deployment/web -n my-ns

# Rollback to a specific revision
kubectl rollout undo deployment/web --to-revision=2 -n my-ns

# Verify image after rollback
kubectl describe deployment web -n my-ns | grep Image
```

### Scaling

```bash
# Scale a deployment
kubectl scale deployment web --replicas=5 -n my-ns
```

### Taints and Labels on Nodes

```bash
# Add a taint
kubectl taint nodes node01 app_type=alpha:NoSchedule

# Remove a taint (trailing dash)
kubectl taint nodes node01 app_type=alpha:NoSchedule-

# Remove control-plane taint (to allow scheduling on control-plane node)
kubectl taint nodes controlplane node-role.kubernetes.io/control-plane:NoSchedule-

# View taints
kubectl describe node node01 | grep -A5 Taints

# Add a label to a node
kubectl label node controlplane app_type=beta

# Remove a label from a node (trailing dash)
kubectl label node controlplane app_type-

# View node labels
kubectl get nodes --show-labels
```

### Labels on Pods

```bash
# Add/update a label on a pod
kubectl label pod my-pod role=frontend --overwrite

# Remove a label
kubectl label pod my-pod role-

# View labels
kubectl get pods --show-labels

# Filter pods by label
kubectl get pods -l app=web
kubectl get pods -l "app=web,tier=frontend"
kubectl get pods -l 'app in (web,api)'
```

### Resource Metrics (kubectl top)

```bash
# Top CPU-consuming pods in a namespace
kubectl top pod -n my-ns --sort-by=cpu

# Top memory-consuming pods
kubectl top pod -n my-ns --sort-by=memory

# Extract just the top pod name (for writing to a file)
kubectl top pod -n my-ns --sort-by=cpu --no-headers | head -1 | awk '{print $1}'

# Node-level resource usage
kubectl top node
```

> **Requires:** Metrics Server must be installed and running. If `kubectl top` returns "Metrics API not available," the metrics-server isn't ready.

### Debugging and Inspection

```bash
# Describe a resource (shows events, status, config)
kubectl describe pod my-pod -n my-ns
kubectl describe deployment web -n my-ns
kubectl describe svc web-svc
kubectl describe ingress web-ingress
kubectl describe networkpolicy my-policy -n my-ns
kubectl describe resourcequota -n my-ns
kubectl describe node node01

# View logs
kubectl logs my-pod -n my-ns
kubectl logs my-pod -c sidecar -n my-ns          # Specific container
kubectl logs my-pod --previous                     # Previous (crashed) container
kubectl logs job/my-job                            # Job logs
kubectl logs deployment/my-deploy                  # First pod in deployment

# Export existing resource YAML (for editing immutable fields)
kubectl get pod my-pod -o yaml > pod.yaml
kubectl get deployment web -o yaml > deploy.yaml

# Check service endpoints (does the service have backing pods?)
kubectl get endpoints web-svc

# Check RBAC bindings
kubectl get rolebindings -n my-ns -o wide
kubectl describe role my-role -n my-ns

# Check which SA a pod uses
kubectl get pod my-pod -o jsonpath='{.spec.serviceAccountName}'

# Explain API fields (built-in docs during the exam)
kubectl explain pod.spec.affinity.nodeAffinity
kubectl explain deployment.spec.strategy
kubectl explain cronjob.spec.jobTemplate.spec
```

### Events

```bash
# All events in a namespace
kubectl get events -n my-ns

# Events for a specific pod
kubectl get events -n my-ns --field-selector involvedObject.name=my-pod

# Events in wide format (more columns) — export to file
kubectl get events -n my-ns --field-selector involvedObject.name=my-pod -o wide > /root/events.txt

# Sort events by time
kubectl get events -n my-ns --sort-by='.lastTimestamp'
```

### Exec into Pods

```bash
# Run a command in a pod
kubectl exec my-pod -- env | grep DB_

# Run a command in a specific container
kubectl exec my-pod -c sidecar -- cat /var/log/app.log

# Interactive shell
kubectl exec -it my-pod -- /bin/sh

# Test network connectivity from inside a pod
kubectl exec my-pod -- curl -s --max-time 3 http://web-svc:80
kubectl exec my-pod -- wget -qO- --timeout=3 http://web-svc:80

# Test DNS resolution
kubectl exec my-pod -- nslookup web-svc.my-ns.svc.cluster.local
```

---

## Part 5: Essential Flags Reference

### Output Formats

| Flag | Purpose | Example |
|------|---------|---------|
| `-o yaml` | Full YAML output | `kubectl get pod my-pod -o yaml` |
| `-o json` | Full JSON output | `kubectl get pod my-pod -o json` |
| `-o wide` | Extra columns (node, IP) | `kubectl get pods -o wide` |
| `-o name` | Just resource names | `kubectl get pods -o name` |
| `-o jsonpath='{...}'` | Extract specific fields | `kubectl get pod -o jsonpath='{.status.podIP}'` |
| `--no-headers` | Strip header line (for scripting) | `kubectl top pod --no-headers` |

### Filtering

| Flag | Purpose | Example |
|------|---------|---------|
| `-n <ns>` | Specific namespace | `kubectl get pods -n prod` |
| `-A` | All namespaces | `kubectl get pods -A` |
| `-l key=value` | Filter by label | `kubectl get pods -l app=web` |
| `--field-selector` | Filter by field | `kubectl get events --field-selector involvedObject.name=my-pod` |
| `--show-labels` | Display labels column | `kubectl get pods --show-labels` |
| `--sort-by` | Sort output | `kubectl get events --sort-by='.lastTimestamp'` |

### The Scaffold Pattern

| Flag | Purpose | Example |
|------|---------|---------|
| `--dry-run=client` | Don't create, just validate | `kubectl run x --image=y --dry-run=client -o yaml` |
| `-o yaml` | Output YAML (pipe to file) | `> pod.yaml` |
| Combine: | Generate → Edit → Apply | `kubectl run x --image=y --dry-run=client -o yaml > x.yaml && vim x.yaml && kubectl apply -f x.yaml` |

### Container Image Operations

```bash
# Build an image (podman or docker)
podman build -t my-app:1.0 .
docker build -t my-app:1.0 .

# Save as tarball
podman save -o /root/my-app.tar my-app:1.0
docker save my-app:1.0 > /root/my-app.tar

# Save in OCI format
podman save --format oci-archive -o /root/my-app-oci.tar my-app:1.0

# Run a container with port binding
podman run -d --name my-container -p 34080:80 my-app:1.0
```

---

## Part 6: Quick Decision Matrix — Imperative vs YAML?

| Resource / Feature | Imperative? | Command / Notes |
|---|---|---|
| **Pod** (basic) | Yes | `kubectl run` |
| **Pod** (with probes/volumes/affinity) | Scaffold + YAML | `kubectl run --dry-run=client -o yaml`, then edit |
| **Deployment** (basic) | Yes | `kubectl create deployment` |
| **Deployment** (with strategy/affinity) | Scaffold + YAML | `kubectl create deployment --dry-run=client -o yaml`, then edit |
| **Service** (ClusterIP/NodePort) | Yes | `kubectl expose` |
| **CronJob** (basic) | Yes | `kubectl create cronjob` |
| **CronJob** (completions/retries) | Scaffold + YAML | `kubectl create cronjob --dry-run=client -o yaml`, then edit |
| **Job** (from CronJob) | Yes | `kubectl create job --from=cronjob/<name>` |
| **Job** (standalone with config) | Scaffold + YAML | `kubectl create job --dry-run=client -o yaml`, then edit |
| **Secret** | Yes | `kubectl create secret generic` |
| **ConfigMap** | Yes | `kubectl create configmap` |
| **ServiceAccount** | Yes | `kubectl create serviceaccount` |
| **Role** | Yes | `kubectl create role` |
| **RoleBinding** | Yes | `kubectl create rolebinding` |
| **ClusterRole** | Yes | `kubectl create clusterrole` |
| **ClusterRoleBinding** | Yes | `kubectl create clusterrolebinding` |
| **Namespace** | Yes | `kubectl create namespace` |
| **ResourceQuota** | Yes | `kubectl create quota` |
| **Ingress** (basic) | Yes | `kubectl create ingress` |
| **Ingress** (with annotations) | Scaffold + YAML | `kubectl create ingress --dry-run=client -o yaml`, then edit |
| **NetworkPolicy** | **YAML only** | No imperative command exists |
| **PVC** | **YAML only** | No imperative command exists |
| **PV** | **YAML only** | No imperative command exists |
| **LimitRange** | **YAML only** | No imperative command exists |

---

## Speed Tips for the Exam

1. **Set up aliases at the start:**
   ```bash
   alias k=kubectl
   alias kaf='kubectl apply -f'
   alias kgp='kubectl get pods'
   alias kdp='kubectl describe pod'
   export do='--dry-run=client -o yaml'
   # Then: k run my-pod --image=nginx $do > pod.yaml
   ```

2. **Use `kubectl explain` instead of docs** when you need a field path:
   ```bash
   kubectl explain pod.spec.affinity --recursive | grep -i node
   kubectl explain deployment.spec.strategy
   ```

3. **Copy YAML blocks from existing resources** rather than writing from scratch:
   ```bash
   kubectl get pod running-pod -o yaml > template.yaml
   # Edit and reuse the spec
   ```

4. **Tab completion saves time** — ensure it's enabled:
   ```bash
   source <(kubectl completion bash)
   alias k=kubectl
   complete -o default -F __start_kubectl k
   ```

5. **For immutable field changes** (probes, containers, volumes): always do export → edit → delete → apply. Don't waste time trying `kubectl edit` for immutable fields.

6. **Test NetworkPolicies** with curl/wget from inside pods:
   ```bash
   kubectl exec source-pod -- curl -s --max-time 3 http://target-svc:80
   # Timeout = blocked. Response = allowed.
   ```

---

*Derived from ckad-exam-qa-guide.md (22 questions) and ckad-trevor.md (6 unique questions). March 2026.*
