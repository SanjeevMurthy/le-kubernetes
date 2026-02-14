# 🚀 Kubectl Imperative Commands — CKA Exam Cheatsheet

> [!NOTE]
> Imperative commands let you create Kubernetes resources **without writing YAML files**. In the CKA exam, using imperative commands saves significant time. This cheatsheet covers every resource that can be created imperatively.

> [!TIP]
> **The Golden Pattern:** Use `--dry-run=client -o yaml` to generate YAML when you need to add fields that imperative commands don't support. Create the base imperatively, then edit the YAML before applying.

---

## Table of Contents

1. [Pods](#1-pods)
2. [Deployments](#2-deployments)
3. [Services](#3-services)
4. [ConfigMaps](#4-configmaps)
5. [Secrets](#5-secrets)
6. [Namespaces](#6-namespaces)
7. [ServiceAccounts](#7-serviceaccounts)
8. [Roles & RoleBindings](#8-roles--rolebindings)
9. [ClusterRoles & ClusterRoleBindings](#9-clusterroles--clusterrolebindings)
10. [Jobs & CronJobs](#10-jobs--cronjobs)
11. [Ingress](#11-ingress)
12. [Resource Quotas & LimitRanges](#12-resource-quotas--limitranges)
13. [PriorityClasses](#13-priorityclasses)
14. [Taints & Labels](#14-taints--labels--annotations)
15. [Scaling & Autoscaling](#15-scaling--autoscaling)
16. [Expose and Port-Forward](#16-expose-and-port-forward)
17. [Tokens & Certificates](#17-tokens--certificates)
18. [Dry-Run + YAML Generation Patterns](#18-dry-run--yaml-generation-patterns)

---

## 1. Pods

### Basic Pod Creation

```bash
# Create a simple pod
kubectl run nginx --image=nginx

# Create a pod with a specific image version
kubectl run nginx --image=nginx:1.25-alpine

# Create a pod with labels
kubectl run nginx --image=nginx --labels="app=web,tier=frontend"

# Create a pod that runs a command
kubectl run busybox --image=busybox -- sleep 3600

# Create a pod running a shell command
kubectl run busybox --image=busybox -- sh -c "echo hello && sleep 3600"

# Create a pod with resource requests and limits
kubectl run nginx --image=nginx \
  --requests="cpu=100m,memory=128Mi" \
  --limits="cpu=200m,memory=256Mi"

# Create a pod with environment variables
kubectl run nginx --image=nginx --env="DB_HOST=mysql" --env="DB_PORT=3306"

# Create a pod in a specific namespace
kubectl run nginx --image=nginx -n my-namespace

# Create a pod with a specific restart policy (for Jobs-like behavior)
kubectl run nginx --image=nginx --restart=Never

# Create a pod and expose it on a specific port
kubectl run nginx --image=nginx --port=80
```

### Interactive / Temporary Pods

```bash
# Run a temporary pod for debugging (deleted when you exit)
kubectl run tmp --image=busybox --rm -it --restart=Never -- sh

# Run a temporary pod with curl
kubectl run tmp --image=curlimages/curl --rm -it --restart=Never -- curl http://my-service

# Run a temporary pod to test DNS
kubectl run tmp --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default

# Run a temporary pod with wget
kubectl run tmp --image=busybox --rm -it --restart=Never -- wget -qO- http://my-service:80
```

### Generate Pod YAML (without creating)

```bash
# Generate YAML template
kubectl run nginx --image=nginx --dry-run=client -o yaml

# Generate YAML and save to file
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml

# Generate YAML with command
kubectl run busybox --image=busybox --dry-run=client -o yaml -- sh -c "sleep 1d" > pod.yaml

# Generate YAML with labels and port
kubectl run nginx --image=nginx --port=80 --labels="app=web" --dry-run=client -o yaml > pod.yaml
```

> [!TIP]
> **When to use `--dry-run=client -o yaml`:**
> Use this when you need to add fields not supported by imperative flags, such as:
>
> - Volume mounts
> - Probes (liveness, readiness, startup)
> - Init containers
> - Tolerations / Node affinity
> - Security contexts

---

## 2. Deployments

### Basic Deployment Creation

```bash
# Create a deployment
kubectl create deployment nginx --image=nginx

# Create with multiple replicas
kubectl create deployment nginx --image=nginx --replicas=3

# Create in a specific namespace
kubectl create deployment nginx --image=nginx -n my-namespace

# Create with a specific port
kubectl create deployment nginx --image=nginx --port=80

# Create with multiple replicas and port
kubectl create deployment webapp --image=nginx:1.25 --replicas=3 --port=80
```

### Deployment Management (Imperative)

```bash
# Scale a deployment
kubectl scale deployment nginx --replicas=5

# Scale to zero (stop all pods)
kubectl scale deployment nginx --replicas=0

# Update image (rolling update)
kubectl set image deployment/nginx nginx=nginx:1.26

# Update image for a specific container in multi-container deployment
kubectl set image deployment/myapp container1=image1:v2 container2=image2:v3

# Rollback to previous version
kubectl rollout undo deployment/nginx

# Rollback to a specific revision
kubectl rollout undo deployment/nginx --to-revision=2

# Check rollout status
kubectl rollout status deployment/nginx

# View rollout history
kubectl rollout history deployment/nginx

# Restart deployment (rolling restart of all pods)
kubectl rollout restart deployment/nginx

# Pause a rollout
kubectl rollout pause deployment/nginx

# Resume a paused rollout
kubectl rollout resume deployment/nginx
```

### Generate Deployment YAML

```bash
# Generate YAML
kubectl create deployment nginx --image=nginx --replicas=3 --dry-run=client -o yaml > deploy.yaml

# Generate YAML with port
kubectl create deployment nginx --image=nginx --port=80 --dry-run=client -o yaml > deploy.yaml
```

> [!IMPORTANT]
> `kubectl run` creates a **Pod**, `kubectl create deployment` creates a **Deployment**. Don't confuse them! In the CKA exam, pay attention to whether the question asks for a Pod or a Deployment.

---

## 3. Services

### Using `kubectl create service`

```bash
# Create a ClusterIP service
kubectl create service clusterip my-svc --tcp=80:80

# Create a NodePort service
kubectl create service nodeport my-svc --tcp=80:80

# Create a NodePort service with a specific node port
kubectl create service nodeport my-svc --tcp=80:80 --node-port=30080

# Create a LoadBalancer service
kubectl create service loadbalancer my-svc --tcp=80:80

# Create an ExternalName service
kubectl create service externalname my-svc --external-name=my.database.example.com
```

### Using `kubectl expose` (preferred — auto-selects labels)

```bash
# Expose a pod as a ClusterIP service
kubectl expose pod nginx --port=80

# Expose a pod as a ClusterIP with a custom service name
kubectl expose pod nginx --name=nginx-svc --port=80

# Expose a pod as a NodePort
kubectl expose pod nginx --type=NodePort --port=80

# Expose a pod with target port different from service port
kubectl expose pod nginx --port=8080 --target-port=80

# Expose a deployment
kubectl expose deployment nginx --port=80 --type=ClusterIP

# Expose a deployment as NodePort
kubectl expose deployment nginx --port=80 --type=NodePort

# Expose a deployment as LoadBalancer
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Expose with a specific name in a namespace
kubectl expose deployment webapp --name=webapp-svc --port=80 --target-port=8080 -n my-namespace

# Expose with specific protocol
kubectl expose pod nginx --port=80 --protocol=TCP
```

> [!TIP]
> **`kubectl expose` vs `kubectl create service`:**
>
> - `kubectl expose` automatically copies labels from the target resource and uses them as selectors — **preferred for most cases**
> - `kubectl create service` creates the service with a generic `app=<name>` selector — you may need to fix it manually
> - For static pods, use the full pod name (with node suffix): `kubectl expose pod my-pod-node1 --name=my-svc --port=80`

### Generate Service YAML

```bash
kubectl expose deployment nginx --port=80 --type=NodePort --dry-run=client -o yaml > svc.yaml
kubectl create service clusterip my-svc --tcp=80:80 --dry-run=client -o yaml > svc.yaml
```

---

## 4. ConfigMaps

### From Literals

```bash
# Create from key-value pairs
kubectl create configmap my-config --from-literal=key1=value1

# Create with multiple key-value pairs
kubectl create configmap my-config \
  --from-literal=DB_HOST=mysql \
  --from-literal=DB_PORT=3306 \
  --from-literal=DB_NAME=mydb

# Create in a specific namespace
kubectl create configmap my-config --from-literal=key=value -n my-namespace
```

### From Files

```bash
# Create from a file (key = filename, value = file content)
kubectl create configmap my-config --from-file=config.txt

# Create with a custom key name
kubectl create configmap my-config --from-file=my-key=config.txt

# Create from multiple files
kubectl create configmap my-config --from-file=file1.txt --from-file=file2.txt

# Create from all files in a directory
kubectl create configmap my-config --from-file=./config-dir/

# Create from an env file
kubectl create configmap my-config --from-env-file=app.env
```

### Generate ConfigMap YAML

```bash
kubectl create configmap my-config \
  --from-literal=key1=value1 \
  --from-literal=key2=value2 \
  --dry-run=client -o yaml > cm.yaml
```

> [!TIP]
> **Using ConfigMaps in Pods — common patterns (add to generated YAML):**
>
> ```yaml
> # As environment variables (all keys)
> envFrom:
>   - configMapRef:
>       name: my-config
>
> # As individual env vars
> env:
>   - name: DB_HOST
>     valueFrom:
>       configMapKeyRef:
>         name: my-config
>         key: DB_HOST
>
> # As a volume mount
> volumes:
>   - name: config-vol
>     configMap:
>       name: my-config
> ```

---

## 5. Secrets

### From Literals

```bash
# Create a generic secret
kubectl create secret generic my-secret --from-literal=username=admin --from-literal=password=Pa$$w0rd

# Create in a namespace
kubectl create secret generic my-secret \
  --from-literal=user=admin \
  --from-literal=pass=secret123 \
  -n my-namespace
```

### From Files

```bash
# Create from files
kubectl create secret generic my-secret --from-file=ssh-key=id_rsa

# Create from a TLS certificate and key
kubectl create secret tls my-tls-secret \
  --cert=tls.crt \
  --key=tls.key

# Create a docker-registry secret
kubectl create secret docker-registry my-reg-secret \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass \
  --docker-email=user@example.com
```

### Generate Secret YAML

```bash
kubectl create secret generic my-secret \
  --from-literal=user=admin \
  --from-literal=pass=secret \
  --dry-run=client -o yaml > secret.yaml
```

> [!TIP]
> **Using Secrets in Pods — common patterns (add to generated YAML):**
>
> ```yaml
> # As environment variables
> env:
>   - name: APP_USER
>     valueFrom:
>       secretKeyRef:
>         name: my-secret
>         key: user
>
> # As a volume mount (read-only)
> volumeMounts:
>   - name: secret-vol
>     mountPath: /etc/secret
>     readOnly: true
> volumes:
>   - name: secret-vol
>     secret:
>       secretName: my-secret
> ```

---

## 6. Namespaces

```bash
# Create a namespace
kubectl create namespace my-namespace

# Short form
kubectl create ns my-namespace

# Generate YAML
kubectl create ns my-namespace --dry-run=client -o yaml > ns.yaml

# Set default namespace for current context
kubectl config set-context --current --namespace=my-namespace
```

---

## 7. ServiceAccounts

```bash
# Create a service account
kubectl create serviceaccount my-sa

# Create in a namespace
kubectl create sa my-sa -n my-namespace

# Generate YAML
kubectl create sa my-sa --dry-run=client -o yaml > sa.yaml

# Create a token for the service account
kubectl create token my-sa

# Create a token with a specific duration
kubectl create token my-sa --duration=24h
```

> [!TIP]
> **Assigning a ServiceAccount to a Pod (add to YAML):**
>
> ```yaml
> spec:
>   serviceAccountName: my-sa
> ```

---

## 8. Roles & RoleBindings

### Roles (Namespace-scoped permissions)

```bash
# Create a Role with specific permissions
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods

# Create a Role for multiple resources
kubectl create role dev-role \
  --verb=get,list,watch,create,update,delete \
  --resource=pods,services,deployments

# Create a Role for a specific API group
kubectl create role crd-reader \
  --verb=list \
  --resource=students.education.killer.sh

# Create a Role for specific resource names
kubectl create role pod-reader \
  --verb=get \
  --resource=pods \
  --resource-name=my-pod

# Create a Role in a namespace
kubectl create role pod-reader \
  --verb=get,list \
  --resource=pods \
  -n my-namespace

# Generate YAML
kubectl create role pod-reader \
  --verb=get,list \
  --resource=pods \
  --dry-run=client -o yaml > role.yaml
```

### RoleBindings (Bind Role to User/Group/ServiceAccount)

```bash
# Bind a Role to a user
kubectl create rolebinding my-binding \
  --role=pod-reader \
  --user=john

# Bind a Role to a service account
kubectl create rolebinding my-binding \
  --role=pod-reader \
  --serviceaccount=my-namespace:my-sa

# Bind a Role to a group
kubectl create rolebinding my-binding \
  --role=pod-reader \
  --group=developers

# Bind a ClusterRole to a user in a specific namespace (RoleBinding + ClusterRole)
kubectl create rolebinding my-binding \
  --clusterrole=view \
  --user=john \
  -n my-namespace

# Generate YAML
kubectl create rolebinding my-binding \
  --role=pod-reader \
  --serviceaccount=default:my-sa \
  --dry-run=client -o yaml > rb.yaml
```

---

## 9. ClusterRoles & ClusterRoleBindings

### ClusterRoles (Cluster-wide permissions)

```bash
# Create a ClusterRole
kubectl create clusterrole node-reader \
  --verb=get,list,watch \
  --resource=nodes

# Create a ClusterRole for non-resource URLs
kubectl create clusterrole api-access \
  --verb=get \
  --non-resource-url="/api/*"

# Create a ClusterRole for all verbs
kubectl create clusterrole admin-role \
  --verb="*" \
  --resource=pods,services,deployments

# Generate YAML
kubectl create clusterrole node-reader \
  --verb=get,list \
  --resource=nodes \
  --dry-run=client -o yaml > cr.yaml
```

### ClusterRoleBindings

```bash
# Bind a ClusterRole to a user
kubectl create clusterrolebinding my-binding \
  --clusterrole=node-reader \
  --user=john

# Bind to a service account
kubectl create clusterrolebinding my-binding \
  --clusterrole=node-reader \
  --serviceaccount=my-namespace:my-sa

# Bind to a group
kubectl create clusterrolebinding my-binding \
  --clusterrole=cluster-admin \
  --group=admins

# Generate YAML
kubectl create clusterrolebinding my-binding \
  --clusterrole=node-reader \
  --user=john \
  --dry-run=client -o yaml > crb.yaml
```

### Verify RBAC Permissions

```bash
# Check if a user can do something
kubectl auth can-i get pods --as=john

# Check for a service account
kubectl auth can-i list pods --as=system:serviceaccount:my-namespace:my-sa

# Check in a specific namespace
kubectl auth can-i create deployments --as=john -n my-namespace

# Check all permissions
kubectl auth can-i --list --as=john

# Check all permissions for a service account
kubectl auth can-i --list --as=system:serviceaccount:default:my-sa -n default
```

---

## 10. Jobs & CronJobs

### Jobs

```bash
# Create a job
kubectl create job my-job --image=busybox -- echo "Hello World"

# Create a job with a shell command
kubectl create job my-job --image=busybox -- sh -c "echo hello; sleep 5; echo done"

# Create a job from a cronjob (trigger it manually)
kubectl create job test-job --from=cronjob/my-cronjob

# Generate YAML
kubectl create job my-job --image=busybox --dry-run=client -o yaml -- echo "Hello" > job.yaml
```

### CronJobs

```bash
# Create a cronjob (runs every minute)
kubectl create cronjob my-cron --image=busybox --schedule="*/1 * * * *" -- echo "tick"

# Create a cronjob (runs daily at midnight)
kubectl create cronjob daily-backup --image=busybox --schedule="0 0 * * *" -- sh -c "echo backup"

# Create a cronjob (runs every 5 minutes)
kubectl create cronjob my-cron --image=busybox --schedule="*/5 * * * *" -- date

# Generate YAML
kubectl create cronjob my-cron \
  --image=busybox \
  --schedule="*/1 * * * *" \
  --dry-run=client -o yaml -- echo "tick" > cj.yaml
```

> [!TIP]
> **Cron Schedule Quick Reference:**
>
> ```
> ┌───────────── minute (0–59)
> │ ┌───────────── hour (0–23)
> │ │ ┌───────────── day of month (1–31)
> │ │ │ ┌───────────── month (1–12)
> │ │ │ │ ┌───────────── day of week (0–6, Sun=0)
> │ │ │ │ │
> * * * * *
>
> */5 * * * *     → every 5 minutes
> 0 */2 * * *     → every 2 hours
> 0 0 * * *       → daily at midnight
> 0 0 * * 0       → weekly on Sunday
> 0 0 1 * *       → monthly on 1st
> ```

---

## 11. Ingress

```bash
# Create a simple ingress rule
kubectl create ingress my-ingress \
  --rule="myapp.example.com/=my-svc:80"

# Create with path-based routing
kubectl create ingress my-ingress \
  --rule="myapp.example.com/api=api-svc:8080" \
  --rule="myapp.example.com/web=web-svc:80"

# Create with TLS
kubectl create ingress my-ingress \
  --rule="myapp.example.com/=my-svc:80,tls=my-tls-secret"

# Create with a specific ingress class
kubectl create ingress my-ingress \
  --class=nginx \
  --rule="myapp.example.com/=my-svc:80"

# Create with a default backend
kubectl create ingress my-ingress \
  --default-backend=default-svc:80 \
  --rule="myapp.example.com/api=api-svc:8080"

# Create with pathType (add via YAML generation)
kubectl create ingress my-ingress \
  --rule="myapp.example.com/=my-svc:80" \
  --dry-run=client -o yaml > ingress.yaml

# Create ingress in a namespace
kubectl create ingress my-ingress \
  --rule="myapp.example.com/=my-svc:80" \
  -n my-namespace

# Generate YAML
kubectl create ingress my-ingress \
  --rule="myapp.example.com/=my-svc:80" \
  --dry-run=client -o yaml > ingress.yaml
```

> [!NOTE]
> **Ingress rule format:** `--rule="host/path=service:port[,tls[=secret]]"`
>
> - Host and path define the routing rule
> - Service and port define the backend
> - Optionally add TLS with a secret name

---

## 12. Resource Quotas & LimitRanges

### Resource Quotas

```bash
# Create a resource quota
kubectl create quota my-quota \
  --hard=pods=10,requests.cpu=4,requests.memory=8Gi,limits.cpu=8,limits.memory=16Gi

# Create a quota limiting specific resources
kubectl create quota my-quota \
  --hard=pods=5,services=3,persistentvolumeclaims=2

# Create quota in a namespace
kubectl create quota my-quota \
  --hard=pods=10,requests.cpu=2 \
  -n my-namespace

# Generate YAML
kubectl create quota my-quota \
  --hard=pods=10 \
  --dry-run=client -o yaml > quota.yaml
```

> [!NOTE]
> **LimitRanges cannot be created imperatively.** You must write YAML:
>
> ```yaml
> apiVersion: v1
> kind: LimitRange
> metadata:
>   name: my-limits
>   namespace: my-namespace
> spec:
>   limits:
>     - default:
>         cpu: 500m
>         memory: 256Mi
>       defaultRequest:
>         cpu: 100m
>         memory: 128Mi
>       type: Container
> ```

---

## 13. PriorityClasses

```bash
# Create a PriorityClass
kubectl create priorityclass high-priority --value=1000 --description="High priority workloads"

# Create with preemption policy
kubectl create priorityclass high-priority \
  --value=1000 \
  --preemption-policy=Never \
  --description="High priority, no preemption"

# Create a global default priority class
kubectl create priorityclass default-priority \
  --value=0 \
  --global-default=true \
  --description="Default priority"

# Generate YAML
kubectl create priorityclass high-priority \
  --value=1000 \
  --dry-run=client -o yaml > pc.yaml
```

> [!TIP]
> **Using PriorityClass in Pods (add to YAML):**
>
> ```yaml
> spec:
>   priorityClassName: high-priority
> ```

---

## 14. Taints, Labels & Annotations

### Labels

```bash
# Add a label to a node
kubectl label node worker-1 disktype=ssd

# Add a label to a pod
kubectl label pod nginx app=web

# Overwrite an existing label
kubectl label pod nginx app=api --overwrite

# Remove a label (use minus sign)
kubectl label node worker-1 disktype-

# Add labels to multiple resources
kubectl label pods --all env=production

# Add label to a namespace
kubectl label namespace my-ns team=backend
```

### Annotations

```bash
# Add annotation
kubectl annotate pod nginx description="my web server"

# Remove annotation
kubectl annotate pod nginx description-

# Overwrite annotation
kubectl annotate pod nginx description="updated" --overwrite
```

### Taints

```bash
# Add a taint to a node
kubectl taint node worker-1 key=value:NoSchedule

# Add a taint with NoExecute effect
kubectl taint node worker-1 key=value:NoExecute

# Add a taint with PreferNoSchedule effect
kubectl taint node worker-1 key=value:PreferNoSchedule

# Remove a taint (use minus sign at the end)
kubectl taint node worker-1 key=value:NoSchedule-

# Remove all taints with a specific key
kubectl taint node worker-1 key-

# Example: Taint controlplane for no scheduling
kubectl taint node controlplane node-role.kubernetes.io/control-plane:NoSchedule
```

> [!TIP]
> **Toleration to match a taint (add to Pod YAML):**
>
> ```yaml
> tolerations:
>   - key: "key"
>     operator: "Equal"
>     value: "value"
>     effect: "NoSchedule"
> ```
>
> Or to tolerate all taints with a specific key:
>
> ```yaml
> tolerations:
>   - key: "key"
>     operator: "Exists"
>     effect: "NoSchedule"
> ```

---

## 15. Scaling & Autoscaling

### Manual Scaling

```bash
# Scale a deployment
kubectl scale deployment nginx --replicas=5

# Scale a statefulset
kubectl scale statefulset mysql --replicas=3

# Scale a replicaset
kubectl scale replicaset my-rs --replicas=2

# Scale to zero
kubectl scale deployment nginx --replicas=0

# Scale conditionally (only if current replicas match)
kubectl scale deployment nginx --current-replicas=3 --replicas=5
```

### Horizontal Pod Autoscaler (HPA)

```bash
# Create an HPA
kubectl autoscale deployment nginx --min=2 --max=10 --cpu-percent=80

# Create HPA in a namespace
kubectl autoscale deployment nginx --min=1 --max=5 --cpu-percent=50 -n my-namespace

# Generate YAML
kubectl autoscale deployment nginx \
  --min=2 --max=10 --cpu-percent=80 \
  --dry-run=client -o yaml > hpa.yaml

# Check HPA status
kubectl get hpa

# Delete HPA
kubectl delete hpa nginx
```

> [!NOTE]
> `kubectl autoscale` creates an HPA using API version `autoscaling/v1` which only supports CPU-based scaling. For memory or custom metrics, you'll need to write YAML with `autoscaling/v2`:
>
> ```yaml
> apiVersion: autoscaling/v2
> kind: HorizontalPodAutoscaler
> metadata:
>   name: my-hpa
> spec:
>   scaleTargetRef:
>     apiVersion: apps/v1
>     kind: Deployment
>     name: nginx
>   minReplicas: 2
>   maxReplicas: 10
>   metrics:
>     - type: Resource
>       resource:
>         name: memory
>         target:
>           type: Utilization
>           averageUtilization: 80
> ```

---

## 16. Expose and Port-Forward

### Port Forwarding (for debugging)

```bash
# Forward a local port to a pod port
kubectl port-forward pod/nginx 8080:80

# Forward to a service
kubectl port-forward svc/nginx-svc 8080:80

# Forward to a deployment
kubectl port-forward deployment/nginx 8080:80

# Forward on all interfaces (accessible from other machines)
kubectl port-forward --address 0.0.0.0 pod/nginx 8080:80

# Forward in background
kubectl port-forward pod/nginx 8080:80 &
```

### Additional Expose Patterns

```bash
# Expose with multiple ports
kubectl expose deployment nginx --port=80 --port=443 --type=ClusterIP

# Using patch to change service type
kubectl patch svc my-svc -p '{"spec":{"type":"NodePort"}}'
```

---

## 17. Tokens & Certificates

### Tokens

```bash
# Create a bootstrap token
kubeadm token create

# Create and print join command
kubeadm token create --print-join-command

# List tokens
kubeadm token list
```

### Certificate Signing Requests (CSR)

```bash
# Approve a pending CSR
kubectl certificate approve my-csr

# Deny a CSR
kubectl certificate deny my-csr

# List CSRs
kubectl get csr
```

---

## 18. Dry-Run + YAML Generation Patterns

### The Complete Pattern

```bash
# Step 1: Generate base YAML imperatively
kubectl run nginx --image=nginx --port=80 --dry-run=client -o yaml > pod.yaml

# Step 2: Edit the YAML to add what you need
vim pod.yaml

# Step 3: Apply
kubectl apply -f pod.yaml
```

### Common YAML Additions You'll Need

#### Add Volumes and Volume Mounts

```yaml
spec:
  containers:
    - name: nginx
      image: nginx
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      emptyDir: {} # or hostPath, pvc, configMap, secret
```

#### Add Probes

```yaml
spec:
  containers:
    - name: nginx
      image: nginx
      livenessProbe:
        httpGet:
          path: /healthz
          port: 8080
        initialDelaySeconds: 5
        periodSeconds: 10
      readinessProbe:
        exec:
          command:
            - cat
            - /tmp/ready
        initialDelaySeconds: 5
        periodSeconds: 5
```

#### Add Init Containers

```yaml
spec:
  initContainers:
    - name: init
      image: busybox
      command: ["sh", "-c", "until nslookup myservice; do sleep 2; done"]
  containers:
    - name: main
      image: nginx
```

#### Add Node Selector

```yaml
spec:
  nodeSelector:
    disktype: ssd
```

#### Add Tolerations

```yaml
spec:
  tolerations:
    - key: "node-role.kubernetes.io/control-plane"
      operator: "Exists"
      effect: "NoSchedule"
```

#### Add Node Affinity

```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                  - linux
```

#### Add Security Context

```yaml
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  containers:
    - name: nginx
      image: nginx
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
```

#### Add Resource Requests & Limits

```yaml
spec:
  containers:
    - name: nginx
      image: nginx
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 500m
          memory: 256Mi
```

#### Add Downward API (Environment Variables)

```yaml
spec:
  containers:
    - name: nginx
      image: nginx
      env:
        - name: MY_NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: MY_POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: MY_POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
```

---

## Quick Reference: Resources That CANNOT Be Created Imperatively

These resources **must** be created via YAML:

| Resource                        | Why                                             |
| ------------------------------- | ----------------------------------------------- |
| **PersistentVolume (PV)**       | Requires hostPath/nfs/cloud provider config     |
| **PersistentVolumeClaim (PVC)** | Requires access modes, storage class, size      |
| **StorageClass**                | Requires provisioner, reclaim policy            |
| **NetworkPolicy**               | Complex ingress/egress rules                    |
| **LimitRange**                  | Default limits/requests per container           |
| **DaemonSet**                   | Similar to Deployment but no imperative command |
| **StatefulSet**                 | Similar to Deployment but no imperative command |
| **Pod Disruption Budget**       | Requires minAvailable/maxUnavailable            |
| **Custom Resources (CRDs)**     | Depends on the CRD schema                       |

> [!TIP]
> **For DaemonSets and StatefulSets**, generate a Deployment YAML and change the `kind`:
>
> ```bash
> kubectl create deployment my-ds --image=nginx --dry-run=client -o yaml > ds.yaml
> # Then edit: change kind to DaemonSet, remove replicas and strategy fields
> ```

---

## Exam Speed Tips

> [!IMPORTANT]
> **Top time-savers for the CKA exam:**
>
> 1. **Always use `k` alias** — it's pre-configured: `alias k=kubectl`
> 2. **Use `--dry-run=client -o yaml >` to generate YAML** — never write from scratch
> 3. **Use `kubectl explain`** to look up field names:
>    ```bash
>    kubectl explain pod.spec.containers.livenessProbe
>    kubectl explain deployment.spec.strategy
>    kubectl explain pv.spec.hostPath
>    ```
> 4. **Use `kubectl get -o yaml`** to copy from existing resources
> 5. **Use `kubectl edit`** for quick in-place changes
> 6. **Delete fast:** `k delete pod x --grace-period 0 --force`
> 7. **Search K8s docs:** bookmark nothing, use the search bar
> 8. **Bash shortcuts:** `Ctrl+r` (reverse search), `Ctrl+a/e` (start/end of line)
> 9. **Vim settings for YAML editing:**
>    ```
>    :set tabstop=2 shiftwidth=2 expandtab
>    ```
