# CKAD Simulator - Complete Study Guide

> [!NOTE]
> This is a comprehensive study guide for the CKAD (Certified Kubernetes Application Developer) exam based on the Killer.sh Simulator (Kubernetes 1.35). Each question includes detailed context, step-by-step solutions, troubleshooting tips, and official documentation links.

---

## Table of Contents

1. [Question 1: Namespaces](#question-1-namespaces)
2. [Question 2: Pods](#question-2-pods)
3. [Question 3: Job](#question-3-job)
4. [Question 4: Helm Management](#question-4-helm-management)
5. [Question 5: ServiceAccount, Secret](#question-5-serviceaccount-secret)
6. [Question 6: ReadinessProbe](#question-6-readinessprobe)
7. [Question 7: Pods, Namespaces](#question-7-pods-namespaces)
8. [Question 8: Deployment, Rollouts](#question-8-deployment-rollouts)
9. [Question 9: Pod to Deployment](#question-9-pod-to-deployment)
10. [Question 10: Service, Logs](#question-10-service-logs)
11. [Question 11: Working with Containers](#question-11-working-with-containers)
12. [Question 12: Storage, PV, PVC, Pod Volume](#question-12-storage-pv-pvc-pod-volume)
13. [Question 13: Storage, StorageClass, PVC](#question-13-storage-storageclass-pvc)
14. [Question 14: Secret, Secret-Volume, Secret-Env](#question-14-secret-secret-volume-secret-env)
15. [Question 15: ConfigMap, ConfigMap-Volume](#question-15-configmap-configmap-volume)
16. [Question 16: Logging Sidecar](#question-16-logging-sidecar)
17. [Question 17: InitContainer](#question-17-initcontainer)
18. [Question 18: Service Misconfiguration](#question-18-service-misconfiguration)
19. [Question 19: Service ClusterIP to NodePort](#question-19-service-clusterip-to-nodeport)
20. [Question 20: NetworkPolicy](#question-20-networkpolicy)
21. [Question 21: Requests and Limits, ServiceAccount](#question-21-requests-and-limits-serviceaccount)
22. [Question 22: Labels, Annotations](#question-22-labels-annotations)
23. [Preview Question 1: Liveness Probe](#preview-question-1-liveness-probe)
24. [Preview Question 2: Deployment, Service, ServiceAccount](#preview-question-2-deployment-service-serviceaccount)
25. [Preview Question 3: Fix Broken Service](#preview-question-3-fix-broken-service)
26. [Exam Tips](#exam-tips)

---

## Question 1: Namespaces

### Context

**What is being tested:** Your ability to list cluster resources and save output to files.

**Why this matters:** A straightforward warm-up question. In the real exam, simple tasks like this should be done in under a minute so you can bank time for harder questions. Being comfortable with `kubectl get` output redirection is fundamental.

**CKAD Domain:** Application Design and Build

**Task Summary:** Get the list of all Namespaces and save to a file.

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad5601`

### Solution

```bash
ssh ckad5601

# List all namespaces and save to file
k get ns > /opt/course/1/namespaces
```

Expected content:

```
NAME              STATUS   AGE
default           Active   136m
earth             Active   105m
jupiter           Active   105m
kube-node-lease   Active   136m
kube-public       Active   136m
kube-system       Active   136m
mars              Active   105m
shell-intern      Active   105m
```

### Tips & Troubleshooting

> [!TIP]
> **Speed tip:** `k` is pre-aliased to `kubectl` in the exam environment. Use it everywhere.

> [!TIP]
> For simple file-output questions, always verify with `cat /opt/course/1/namespaces` before moving on.

### References

- [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)

---

## Question 2: Pods

### Context

**What is being tested:** Creating Pods with specific container names, and writing kubectl commands to files.

**Why this matters:** Pod creation with `kubectl run` is the most fundamental skill. The twist here is renaming the container (default name matches the Pod name) and writing a reusable status-check command.

**CKAD Domain:** Application Design and Build

**Task Summary:**

1. Create Pod `pod1` with image `httpd:2.4.41-alpine` and container name `pod1-container`
2. Write a command to check the Pod's status into a script file

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad5601`

### Solution

#### Step 1: Create the Pod

```bash
ssh ckad5601

# Generate yaml to modify container name
k run pod1 --image=httpd:2.4.41-alpine --dry-run=client -oyaml > 2.yaml
```

Edit the yaml to change the container name:

```yaml
# 2.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: pod1
  name: pod1
spec:
  containers:
  - image: httpd:2.4.41-alpine
    name: pod1-container  # change from pod1 to pod1-container
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

```bash
k create -f 2.yaml

# Verify
k get pod pod1
```

#### Step 2: Write the status command

```bash
vim /opt/course/2/pod1-status-command.sh
```

```bash
# /opt/course/2/pod1-status-command.sh
kubectl -n default describe pod pod1 | grep -i status:
```

Alternative using jsonpath:

```bash
# /opt/course/2/pod1-status-command.sh
kubectl -n default get pod pod1 -o jsonpath="{.status.phase}"
```

Test the command:

```bash
sh /opt/course/2/pod1-status-command.sh
# Output: Running
```

### Tips & Troubleshooting

> [!TIP]
> **Container naming:** `kubectl run` names the container the same as the Pod by default. When a different container name is required, you must use `--dry-run=client -oyaml` and edit.

> [!WARNING]
> Don't forget to include `kubectl` (not `k`) in the command file — the alias may not be available when the script is evaluated.

### References

- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)

---

## Question 3: Job

### Context

**What is being tested:** Creating Jobs with completions, parallelism, custom labels, and container naming.

**Why this matters:** Jobs are a core CKAD topic. Understanding `completions` (total runs), `parallelism` (concurrent runs), and how to apply labels to Pod templates is essential. This tests multiple Job spec fields at once.

**CKAD Domain:** Application Design and Build

**Key Concepts:**

- **completions:** Total number of Pods that must successfully complete
- **parallelism:** Maximum number of Pods running concurrently
- **Pod template labels:** Applied via `spec.template.metadata.labels`

**Task Summary:** Create a Job named `neb-new-job` in namespace `neptune` with image `busybox:1.31.0`, running `sleep 2 && echo done`. 3 total completions, 2 parallel, container name `neb-new-job-container`, Pod label `id: awesome-job`. Save template at `/opt/course/3/job.yaml`.

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad7326`

### Solution

```bash
ssh ckad7326

# Generate Job yaml
k -n neptune create job neb-new-job --image=busybox:1.31.0 \
  --dry-run=client -oyaml -- sh -c "sleep 2 && echo done" > /opt/course/3/job.yaml
```

Edit the yaml to add completions, parallelism, labels, and container name:

```yaml
# /opt/course/3/job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: neb-new-job
  namespace: neptune
spec:
  completions: 3
  parallelism: 2
  template:
    metadata:
      labels:
        id: awesome-job
    spec:
      containers:
      - command:
        - sh
        - -c
        - sleep 2 && echo done
        image: busybox:1.31.0
        name: neb-new-job-container
      restartPolicy: Never
```

```bash
k -f /opt/course/3/job.yaml create

# Watch the Job progress — you'll see 2 running in parallel, then the 3rd
k -n neptune get pod,job | grep neb-new-job
```

Verify all 3 completed:

```bash
k -n neptune describe job neb-new-job
# Events show: Created pod1, Created pod2 (parallel), then Created pod3
```

### Tips & Troubleshooting

> [!TIP]
> **Quick check:** The `AGE` column on Pods reveals parallelism — two Pods start at the same time, the third starts after one completes.

> [!WARNING]
> Don't confuse `completions` with `replicas`. Jobs don't have replicas — `completions` is how many times the Job should run to success.

> [!TIP]
> **Labels go on the Pod template**, not on the Job metadata. The `spec.template.metadata.labels` field controls what labels the created Pods get.

### References

- [Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [Running Automated Tasks with a CronJob](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/)

---

## Question 4: Helm Management

### Context

**What is being tested:** Helm operations — list, delete, upgrade, install with custom values, and identifying broken releases.

**Why this matters:** Helm is now part of the CKAD curriculum. You need fluency with `helm ls`, `helm uninstall`, `helm upgrade`, `helm install --set`, and `helm show values`. The "broken release" part tests your ability to spot `pending-install` state.

**CKAD Domain:** Application Deployment

**Key Concepts:**

- **Helm Chart:** Kubernetes YAML templates bundled into a package
- **Helm Release:** An installed instance of a Chart
- **Helm Values:** Customization parameters for Charts

**Task Summary:** In namespace `mercury`:

1. Delete release `internal-issue-report-apiv1`
2. Upgrade release `internal-issue-report-apiv2` to any newer version of `killershell/nginx`
3. Install new release `internal-issue-report-apache` of `killershell/apache` with 2 replicas
4. Find and delete a broken release stuck in `pending-install`

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad7326`

### Solution

#### Step 1: Delete release

```bash
ssh ckad7326

helm -n mercury ls
helm -n mercury uninstall internal-issue-report-apiv1
```

#### Step 2: Upgrade release

```bash
# Check available versions
helm repo update
helm search repo nginx --versions

# Upgrade to latest
helm -n mercury upgrade internal-issue-report-apiv2 killershell/nginx
```

#### Step 3: Install with custom values

```bash
# Find the value name for replicas
helm show values killershell/apache | head -20
# Look for: replicaCount: 1

# Install with 2 replicas
helm -n mercury install internal-issue-report-apache killershell/apache --set replicaCount=2

# Verify
k -n mercury get deploy internal-issue-report-apache
# Should show 2/2 READY
```

#### Step 4: Find and delete broken release

```bash
helm -n mercury ls
# Look for STATUS: pending-install
# Found: internal-issue-report-daniel

helm -n mercury uninstall internal-issue-report-daniel
```

### Tips & Troubleshooting

> [!TIP]
> **Quick Helm cheatsheet:**
>
> ```bash
> helm ls -A                          # list all releases in all namespaces
> helm show values <chart>            # show configurable values
> helm install <name> <chart> --set key=value
> helm upgrade <name> <chart>
> helm rollback <name> <revision>
> helm uninstall <name>
> ```

> [!TIP]
> **Nested values** use dot notation: `--set image.debug=true`

> [!WARNING]
> `helm ls` only shows `deployed` releases by default. Use `helm ls -a` to see all statuses including `pending-install`, `failed`, etc.

### References

- [Helm Documentation](https://helm.sh/docs/)
- [Helm Install](https://helm.sh/docs/helm/helm_install/)
- [Helm Show Values](https://helm.sh/docs/helm/helm_show_values/)

---

## Question 5: ServiceAccount, Secret

### Context

**What is being tested:** Finding Secrets associated with ServiceAccounts and extracting base64-decoded tokens.

**Why this matters:** Understanding the relationship between ServiceAccounts and their token Secrets is critical for debugging authentication issues. Modern K8s versions don't auto-create Secrets for SAs, but manually-created ones use the `kubernetes.io/service-account.name` annotation.

**CKAD Domain:** Application Environment, Configuration and Security

**Task Summary:** Find the Secret token for ServiceAccount `neptune-sa-v2` in namespace `neptune`, decode it, and save to `/opt/course/5/token`.

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad7326`

### Solution

```bash
ssh ckad7326

# Find the secret associated with the ServiceAccount
k -n neptune get secrets
k -n neptune get secrets -oyaml | grep annotations -A 1
# Look for: kubernetes.io/service-account.name: neptune-sa-v2

# The Secret is neptune-secret-1 — get the decoded token
k -n neptune describe secret neptune-secret-1
# Copy the token from the Data section (it's already decoded in describe output)
```

Save the decoded token:

```bash
vim /opt/course/5/token
# Paste the token value from the describe output
```

### Tips & Troubleshooting

> [!TIP]
> **Finding SA Secrets quickly:**
>
> ```bash
> k -n neptune get secrets -oyaml | grep "service-account.name" -A 0
> ```

> [!WARNING]
> `kubectl describe secret` shows the **decoded** token. `kubectl get secret -oyaml` shows it **base64-encoded**. If using the yaml output, pipe through `base64 -d`.

> [!TIP]
> In K8s 1.24+, Secrets are NOT automatically created for ServiceAccounts. They must be manually created with the annotation `kubernetes.io/service-account.name`.

### References

- [ServiceAccounts](https://kubernetes.io/docs/concepts/security/service-accounts/)
- [Managing Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)

---

## Question 6: ReadinessProbe

### Context

**What is being tested:** Configuring an exec-based readiness probe with timing parameters.

**Why this matters:** Readiness probes control when a Pod is added to Service endpoints. An exec probe running `cat /tmp/ready` is a classic pattern — the Pod becomes ready only when the file exists. This tests your knowledge of probe types, `initialDelaySeconds`, and `periodSeconds`.

**CKAD Domain:** Application Observability and Maintenance

**Task Summary:** Create Pod `pod6` in default namespace with image `busybox:1.31.0`. Add a readiness probe that executes `cat /tmp/ready` with `initialDelaySeconds: 5` and `periodSeconds: 10`. The Pod should run `touch /tmp/ready && sleep 1d`.

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad5601`

### Solution

```bash
ssh ckad5601

k run pod6 --image=busybox:1.31.0 --dry-run=client -oyaml \
  --command -- sh -c "touch /tmp/ready && sleep 1d" > 6.yaml
```

Add the readiness probe:

```yaml
# 6.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: pod6
  name: pod6
spec:
  containers:
  - command:
    - sh
    - -c
    - touch /tmp/ready && sleep 1d
    image: busybox:1.31.0
    name: pod6
    readinessProbe:
      exec:
        command:
        - sh
        - -c
        - cat /tmp/ready
      initialDelaySeconds: 5
      periodSeconds: 10
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

```bash
k -f 6.yaml create

# Watch it become ready after ~5 seconds
k get pod pod6        # 0/1 Running initially
k get pod pod6        # 1/1 Running after readiness passes
```

### Tips & Troubleshooting

> [!TIP]
> **Three probe types:**
>
> - `exec` — runs a command, success if exit code 0
> - `httpGet` — HTTP GET request, success if status 200-399
> - `tcpSocket` — TCP connection, success if port is open

> [!TIP]
> `readinessProbe` vs `livenessProbe`: Readiness controls Service traffic routing. Liveness controls Pod restart. A failing readiness probe removes the Pod from endpoints. A failing liveness probe kills and restarts the container.

### References

- [Configure Liveness, Readiness, and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

---

## Question 7: Pods, Namespaces

### Context

**What is being tested:** Finding a Pod by its annotations/labels and moving it between namespaces.

**Why this matters:** You can't simply "move" a Pod in Kubernetes. You must export its yaml, change the namespace, remove runtime fields (`status`, `nodeName`, token volumes), create the new Pod, and delete the old one. This tests your ability to work with Pod yaml and clean it up.

**CKAD Domain:** Application Design and Build

**Task Summary:** Find the Pod in namespace `saturn` that belongs to the e-commerce system `my-happy-shop` and move it to namespace `neptune`.

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad7326`

### Solution

```bash
ssh ckad7326

# Find the Pod — search annotations/labels for "my-happy-shop"
k -n saturn get pod -o yaml | grep my-happy-shop -A10
# Found: webserver-sat-003 has annotation: "description: this is the server for the E-Commerce System my-happy-shop"

# Export the Pod yaml
k -n saturn get pod webserver-sat-003 -o yaml > 7_webserver-sat-003.yaml
```

Clean the yaml — change namespace, remove `status`, `nodeName`, token volume/volumeMount:

```yaml
# 7_webserver-sat-003.yaml (cleaned)
apiVersion: v1
kind: Pod
metadata:
  annotations:
    description: this is the server for the E-Commerce System my-happy-shop
  labels:
    id: webserver-sat-003
  name: webserver-sat-003
  namespace: neptune          # changed from saturn
spec:
  containers:
  - image: nginx:1.16.1-alpine
    name: webserver-sat
  restartPolicy: Always
```

```bash
# Create in new namespace
k -n neptune create -f 7_webserver-sat-003.yaml

# Verify it's running
k -n neptune get pod | grep webserver

# Delete from old namespace
k -n saturn delete pod webserver-sat-003 --force --grace-period=0

# Confirm only one exists
k get pod -A | grep webserver-sat-003
```

### Tips & Troubleshooting

> [!TIP]
> **Finding Pods by keyword:** Use `describe all` or `grep -A` on yaml output to search annotations, labels, and other metadata across all pods.

> [!WARNING]
> When exporting a Pod yaml, you **must** remove:
>
> - `status:` section
> - `spec.nodeName` (forces scheduling to a specific node)
> - Token volumes and volumeMounts (auto-injected, will differ)
> - `metadata.uid`, `metadata.resourceVersion`, `metadata.creationTimestamp`

### References

- [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)

---

## Question 8: Deployment, Rollouts

### Context

**What is being tested:** Deployment rollout history and rollback when a bad image is deployed.

**Why this matters:** Rollback is a critical production skill. When someone pushes a broken image, you need to identify the bad revision from history and undo it. This tests `rollout history`, identifying `ImagePullBackOff`, and `rollout undo`.

**CKAD Domain:** Application Deployment

**Task Summary:** Deployment `api-new-c32` in namespace `neptune` has a broken update. Check the rollout history, find the error, and rollback to a working revision. Report the error to the team.

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad7326`

### Solution

```bash
ssh ckad7326

# Check rollout history
k -n neptune rollout history deploy api-new-c32
# Shows 5 revisions

# Check current state
k -n neptune get deploy,pod | grep api-new-c32
# One Pod shows ImagePullBackOff

# Identify the error
k -n neptune describe pod api-new-c32-7d64747c87-zh648 | grep -i image
# Image: ngnix:1-alpine  ← typo! (ngnix instead of nginx)

# Rollback to previous working revision
k -n neptune rollout undo deploy api-new-c32

# Verify all Pods are running
k -n neptune get pod | grep api-new-c32
```

### Tips & Troubleshooting

> [!TIP]
> **Rollout commands:**
>
> ```bash
> k rollout history deploy <name>               # show all revisions
> k rollout history deploy <name> --revision=3  # show specific revision details
> k rollout undo deploy <name>                  # rollback to previous
> k rollout undo deploy <name> --to-revision=2  # rollback to specific revision
> ```

> [!TIP]
> **Identifying image issues:** `ImagePullBackOff` or `ErrImagePull` almost always means a typo in the image name/tag, or the image doesn't exist in the registry.

### References

- [Deployments - Rolling Back](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)

---

## Question 9: Pod to Deployment

### Context

**What is being tested:** Converting a standalone Pod into a Deployment with security context.

**Why this matters:** In production, standalone Pods should be managed by Deployments for self-healing and scaling. This tests your ability to extract a Pod's spec into a Deployment yaml while preserving env vars, volumes, and adding security settings.

**CKAD Domain:** Application Design and Build

**Task Summary:** A standalone Pod `holy-api` runs in namespace `pluto`. Convert it into a Deployment with 3 replicas. Add `allowPrivilegeEscalation: false` and `privileged: false` security context. Save the yaml and delete the original Pod.

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad5601`

### Solution

```bash
ssh ckad5601

# Export the existing Pod
k -n pluto get pod holy-api -o yaml > /opt/course/9/holy-api-pod.yaml

# Create a Deployment template
k -n pluto create deploy holy-api --image=nginx:1.17.3-alpine --replicas=3 \
  --dry-run=client -oyaml > /opt/course/9/holy-api-deployment.yaml
```

Edit the Deployment yaml — copy the Pod's env vars, volumes, volumeMounts, and add security context:

```yaml
# /opt/course/9/holy-api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: holy-api
  namespace: pluto
spec:
  replicas: 3
  selector:
    matchLabels:
      id: holy-api
  template:
    metadata:
      labels:
        id: holy-api
      name: holy-api
    spec:
      containers:
      - env:
        - name: CACHE_KEY_1
          value: "b&MTCi0=[T66RXm!jO@"
        - name: CACHE_KEY_2
          value: "PCAILGej5Ld@Q%{Q1=#"
        - name: CACHE_KEY_3
          value: "2qz-]2OJlWDSTn_;RFQ"
        image: nginx:1.17.3-alpine
        name: holy-api-container
        securityContext:
          allowPrivilegeEscalation: false
          privileged: false
        volumeMounts:
        - mountPath: /cache1
          name: cache-volume1
        - mountPath: /cache2
          name: cache-volume2
        - mountPath: /cache3
          name: cache-volume3
      volumes:
      - emptyDir: {}
        name: cache-volume1
      - emptyDir: {}
        name: cache-volume2
      - emptyDir: {}
        name: cache-volume3
```

```bash
k -f /opt/course/9/holy-api-deployment.yaml create

# Verify 3 replicas are running
k -n pluto get pod | grep holy

# Delete the original standalone Pod
k -n pluto delete pod holy-api --force --grace-period=0
```

### Tips & Troubleshooting

> [!TIP]
> **Vim indentation tip:** Set `shiftwidth` with `:set shiftwidth=2`. Mark lines with `Shift+V` and arrow keys, then press `>` to indent or `<` to dedent. Press `.` to repeat.

> [!WARNING]
> Ensure the Deployment's `spec.selector.matchLabels` matches `spec.template.metadata.labels`. Mismatches cause creation errors.

### References

- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

---

## Question 10: Service, Logs

### Context

**What is being tested:** Creating a ClusterIP Service, testing internal connectivity, and collecting logs.

**Why this matters:** This is a complete end-to-end Service exercise: create a Pod with labels, expose it via Service with port redirection, test using a temporary Pod with DNS resolution, and check logs. All essential day-to-day skills.

**CKAD Domain:** Services & Networking

**Task Summary:**

1. Create Pod `project-plt-6cc-api` (image `nginx:1.17.3-alpine`, label `project: plt-6cc-api`) in namespace `pluto`
2. Create ClusterIP Service `project-plt-6cc-svc` with tcp port 3333 → targetPort 80
3. Test with curl and save response to `/opt/course/10/service_test.html`
4. Save Pod logs to `/opt/course/10/service_test.log`

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad9043`

### Solution

```bash
ssh ckad9043

# Create the Pod with custom label
k -n pluto run project-plt-6cc-api --image=nginx:1.17.3-alpine --labels project=plt-6cc-api

# Expose the Pod as a Service
k -n pluto expose pod project-plt-6cc-api --name project-plt-6cc-svc --port 3333 --target-port 80

# Verify endpoints exist
k -n pluto get endpointslice

# Test the Service using a temporary Pod (note: cross-namespace DNS)
k run tmp --restart=Never --rm --image=nginx:alpine -i -- curl http://project-plt-6cc-svc.pluto:3333

# Save the response
k run tmp --restart=Never --rm --image=nginx:alpine -i -- curl -s http://project-plt-6cc-svc.pluto:3333 \
  > /opt/course/10/service_test.html

# Save the Pod logs
k -n pluto logs project-plt-6cc-api > /opt/course/10/service_test.log
```

### Tips & Troubleshooting

> [!TIP]
> **Service DNS resolution:**
>
> - Same namespace: `service-name`
> - Cross-namespace: `service-name.namespace`
> - Full FQDN: `service-name.namespace.svc.cluster.local`

> [!TIP]
> **`kubectl expose` vs `kubectl create service`:** `expose` automatically copies the Pod's labels as the Service selector. `create service` requires manual selector configuration.

> [!WARNING]
> If the Service has no endpoints, check that the Service selector labels match the Pod labels exactly.

### References

- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)

---

## Question 11: Working with Containers

### Context

**What is being tested:** Building container images with Docker and Podman, tagging, pushing to registries, and running containers.

**Why this matters:** The CKAD requires container-level skills beyond Kubernetes. You must be comfortable with Dockerfiles, multi-stage builds, environment variables, image registries, and running containers with both Docker and Podman.

**CKAD Domain:** Application Design and Build

**Task Summary:**

1. Modify Dockerfile to set `ENV SUN_CIPHER_ID=5b9c1065-e39d-4a43-a04a-e59bcea3e03f`
2. Build with Docker, tag `registry.killer.sh:5000/sun-cipher:v1-docker`, push
3. Build with Podman, tag `registry.killer.sh:5000/sun-cipher:v1-podman`, push
4. Run a detached Podman container named `sun-cipher` from the podman image
5. Save container logs to `/opt/course/11/logs`

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad9043`
> Run all Docker and Podman commands as root: `sudo docker`, `sudo podman`

### Solution

#### Step 1: Modify Dockerfile

```bash
ssh ckad9043

cp /opt/course/11/image/Dockerfile /opt/course/11/image/Dockerfile_bak
vim /opt/course/11/image/Dockerfile
```

```dockerfile
# build container stage 1
FROM docker.io/library/golang:1.15.15-alpine3.14
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o bin/app .

# app container stage 2
FROM docker.io/library/alpine:3.12.4
COPY --from=0 /src/bin/app app
ENV SUN_CIPHER_ID=5b9c1065-e39d-4a43-a04a-e59bcea3e03f
CMD ["./app"]
```

#### Step 2: Docker build and push

```bash
cd /opt/course/11/image
sudo docker build -t registry.killer.sh:5000/sun-cipher:v1-docker .
sudo docker push registry.killer.sh:5000/sun-cipher:v1-docker
```

#### Step 3: Podman build and push

```bash
sudo podman build -t registry.killer.sh:5000/sun-cipher:v1-podman .
sudo podman push registry.killer.sh:5000/sun-cipher:v1-podman
```

#### Step 4: Run detached container

```bash
sudo podman run -d --name sun-cipher registry.killer.sh:5000/sun-cipher:v1-podman
```

#### Step 5: Save logs

```bash
sudo podman logs sun-cipher > /opt/course/11/logs
```

### Tips & Troubleshooting

> [!TIP]
> **Docker vs Podman:** Commands are nearly identical. Both support `build`, `push`, `pull`, `run`, `logs`, `images`. Key difference: Podman is daemonless and rootless by default.

> [!TIP]
> **Key container concepts:**
>
> - **Dockerfile** — list of commands to build an Image
> - **Image** — binary package containing all dependencies
> - **Container** — running instance of an Image
> - **Registry** — storage for pushing/pulling Images

### References

- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Podman Documentation](https://podman.io/docs)

---

## Question 12: Storage, PV, PVC, Pod Volume

### Context

**What is being tested:** Creating PersistentVolumes, PersistentVolumeClaims, and mounting them in Deployments.

**Why this matters:** Storage is fundamental to stateful applications. Understanding the PV→PVC→Pod binding chain, access modes, and volume mounts is a core CKAD requirement. The key detail here is NOT setting a `storageClassName` so the PVC binds to the PV via capacity/access mode matching.

**CKAD Domain:** Application Design and Build

**Task Summary:**

1. Create PV `earth-project-earthflower-pv` — 2Gi, ReadWriteOnce, hostPath `/Volumes/Data`, no storageClassName
2. Create PVC `earth-project-earthflower-pvc` in namespace `earth` — 2Gi, ReadWriteOnce, no storageClassName
3. Create Deployment `project-earthflower` in namespace `earth` mounting the volume at `/tmp/project-data`

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad5601`

### Solution

#### Step 1: Create PersistentVolume

```yaml
# 12_pv.yaml
kind: PersistentVolume
apiVersion: v1
metadata:
  name: earth-project-earthflower-pv
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/Volumes/Data"
```

```bash
ssh ckad5601
k -f 12_pv.yaml create
```

#### Step 2: Create PersistentVolumeClaim

```yaml
# 12_pvc.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: earth-project-earthflower-pvc
  namespace: earth
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
```

```bash
k -f 12_pvc.yaml create

# Verify both are Bound
k -n earth get pv,pvc
```

#### Step 3: Create Deployment with volume mount

```bash
k -n earth create deploy project-earthflower --image=httpd:2.4.41-alpine \
  --dry-run=client -oyaml > 12_dep.yaml
```

```yaml
# 12_dep.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: project-earthflower
  namespace: earth
spec:
  replicas: 1
  selector:
    matchLabels:
      app: project-earthflower
  template:
    metadata:
      labels:
        app: project-earthflower
    spec:
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: earth-project-earthflower-pvc
      containers:
      - image: httpd:2.4.41-alpine
        name: container
        volumeMounts:
        - name: data
          mountPath: /tmp/project-data
```

```bash
k -f 12_dep.yaml create

# Verify mount
k -n earth describe pod project-earthflower-... | grep -A2 Mounts:
```

### Tips & Troubleshooting

> [!TIP]
> **PV-PVC binding rules:** When no storageClassName is set on either, Kubernetes matches by capacity and access mode. Set `storageClassName: ""` explicitly if the cluster has a default StorageClass and you want to avoid it.

> [!WARNING]
> If the PVC stays in `Pending`, check that the PV's capacity >= PVC request and access modes match.

### References

- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Configure a Pod to Use a PersistentVolume](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/)

---

## Question 13: Storage, StorageClass, PVC

### Context

**What is being tested:** Creating a StorageClass with a custom provisioner and reclaimPolicy, then creating a PVC that uses it.

**Why this matters:** StorageClasses abstract storage provisioning. Understanding `provisioner`, `reclaimPolicy` (Retain vs Delete), and how PVCs reference StorageClasses is essential. The PVC will stay `Pending` since the provisioner doesn't exist — and that's expected.

**CKAD Domain:** Application Design and Build

**Task Summary:**

1. Create StorageClass `moon-retain` with provisioner `moon-retainer` and reclaimPolicy `Retain`
2. Create PVC `moon-pvc-126` in namespace `moon` — 3Gi, ReadWriteOnce, using `moon-retain` StorageClass
3. Write the PVC event message explaining why it's Pending to `/opt/course/13/pvc-126-reason`

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad9043`

### Solution

```yaml
# 13_sc.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: moon-retain
provisioner: moon-retainer
reclaimPolicy: Retain
```

```yaml
# 13_pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: moon-pvc-126
  namespace: moon
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
  storageClassName: moon-retain
```

```bash
ssh ckad9043

k create -f 13_sc.yaml
k -f 13_pvc.yaml create

# Check PVC status — should be Pending
k -n moon get pvc
k -n moon describe pvc moon-pvc-126
# Copy the event message

vim /opt/course/13/pvc-126-reason
```

```
Waiting for a volume to be created either by the external provisioner 'moon-retainer' or manually by the system administrator. If volume creation is delayed, please verify that the provisioner is running and correctly registered.
```

### Tips & Troubleshooting

> [!TIP]
> **ReclaimPolicy values:**
>
> - `Retain` — PV is kept after PVC deletion (manual cleanup)
> - `Delete` — PV is deleted automatically when PVC is deleted
> - `Recycle` — deprecated, don't use

### References

- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)

---

## Question 14: Secret, Secret-Volume, Secret-Env

### Context

**What is being tested:** Creating Secrets, mounting as volumes, and injecting as environment variables with specific names.

**Why this matters:** This is a comprehensive Secret exercise combining both consumption methods: env vars via `secretKeyRef` (with custom env var names) and volume mounts. Understanding the difference between `env.valueFrom.secretKeyRef` (per-key) and `envFrom.secretRef` (all keys) is critical.

**CKAD Domain:** Application Environment, Configuration and Security

**Task Summary:**

1. Create Secret `secret1` with `user=test` and `pass=pwd` in namespace `moon`
2. Mount Secret `secret2` (already exists) at `/tmp/secret2` in Pod `secret-handler`
3. Inject `secret1` as env vars `SECRET1_USER` (from key `user`) and `SECRET1_PASS` (from key `pass`)
4. Save modified yaml at `/opt/course/14/secret-handler-new.yaml`

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad9043`

### Solution

```bash
ssh ckad9043

# Create secret1
k -n moon create secret generic secret1 --from-literal user=test --from-literal pass=pwd

# Create secret2 from provided yaml
k -n moon -f /opt/course/14/secret2.yaml create

# Copy and modify the Pod yaml
cp /opt/course/14/secret-handler.yaml /opt/course/14/secret-handler-new.yaml
vim /opt/course/14/secret-handler-new.yaml
```

Add the volume, volumeMount, and env vars:

```yaml
# /opt/course/14/secret-handler-new.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-handler
  namespace: moon
spec:
  volumes:
  - name: cache-volume1
    emptyDir: {}
  - name: cache-volume2
    emptyDir: {}
  - name: cache-volume3
    emptyDir: {}
  - name: secret2-volume              # add
    secret:                           # add
      secretName: secret2             # add
  containers:
  - name: secret-handler
    image: bash:5.0.11
    args: ['bash', '-c', 'sleep 2d']
    volumeMounts:
    - mountPath: /cache1
      name: cache-volume1
    - mountPath: /cache2
      name: cache-volume2
    - mountPath: /cache3
      name: cache-volume3
    - name: secret2-volume            # add
      mountPath: /tmp/secret2         # add
    env:
    - name: SECRET_KEY_1
      value: ">8$kH#kj..i8}HImQd{"
    - name: SECRET_KEY_2
      value: "IO=a4L/XkRdvN8jM=Y+"
    - name: SECRET_KEY_3
      value: "-7PA0_Z]>{pwa43r)__"
    - name: SECRET1_USER              # add
      valueFrom:                      # add
        secretKeyRef:                 # add
          name: secret1               # add
          key: user                   # add
    - name: SECRET1_PASS              # add
      valueFrom:                      # add
        secretKeyRef:                 # add
          name: secret1               # add
          key: pass                   # add
```

```bash
# Replace the Pod
k -f /opt/course/14/secret-handler-new.yaml replace --force --grace-period=0

# Verify
k -n moon exec secret-handler -- env | grep SECRET1
# SECRET1_USER=test
# SECRET1_PASS=pwd

k -n moon exec secret-handler -- find /tmp/secret2
# /tmp/secret2/key
```

### Tips & Troubleshooting

> [!TIP]
> **Two ways to inject Secrets as env vars:**
>
> ```yaml
> # Per-key with custom names (used here):
> env:
> - name: MY_VAR
>   valueFrom:
>     secretKeyRef:
>       name: my-secret
>       key: my-key
>
> # All keys at once (env var names = Secret keys):
> envFrom:
> - secretRef:
>     name: my-secret
> ```

> [!TIP]
> **Recreating Pods:** Use `kubectl replace --force --grace-period=0` to delete and recreate in one command. Faster than separate delete + create.

### References

- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Distribute Credentials Securely](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/)

---

## Question 15: ConfigMap, ConfigMap-Volume

### Context

**What is being tested:** Creating a ConfigMap from a file with a specific key name, and understanding how volume-mounted ConfigMaps work.

**Why this matters:** ConfigMaps mounted as volumes create files inside the container. The **key name** becomes the **filename**. This is why `--from-file=index.html=/path/to/file` is critical — without specifying the key, the original filename is used, which may not be what nginx expects.

**CKAD Domain:** Application Environment, Configuration and Security

**Task Summary:** Create ConfigMap `configmap-web-moon-html` in namespace `moon` from file `/opt/course/15/web-moon.html` with key name `index.html`. The existing Deployment `web-moon` is already configured to mount it.

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad9043`

### Solution

```bash
ssh ckad9043

# The Pods are failing because the ConfigMap doesn't exist yet
k -n moon get pod
# web-moon-* pods show ContainerCreating with FailedMount

# Create ConfigMap with correct key name
k -n moon create configmap configmap-web-moon-html \
  --from-file=index.html=/opt/course/15/web-moon.html

# Wait for Pods to pick up the ConfigMap (or restart)
k -n moon rollout restart deploy web-moon
k -n moon get pod  # should show Running

# Test the configuration
k -n moon get pod -o wide  # get a Pod IP
k run tmp --restart=Never --rm -i --image=nginx:alpine -- curl <POD_IP>
# Should return the HTML content
```

### Tips & Troubleshooting

> [!TIP]
> **ConfigMap from file — key naming:**
>
> ```bash
> # Key = original filename (web-moon.html)
> k create cm my-cm --from-file=/path/to/web-moon.html
>
> # Key = custom name (index.html) — THIS IS WHAT YOU USUALLY WANT
> k create cm my-cm --from-file=index.html=/path/to/web-moon.html
> ```

> [!TIP]
> When a ConfigMap is mounted as a volume, each key in the ConfigMap becomes a file. The key name is the filename and the value is the file content.

### References

- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)

---

## Question 16: Logging Sidecar

### Context

**What is being tested:** Adding a sidecar container to an existing Deployment for log aggregation.

**Why this matters:** Sidecar containers are the standard K8s pattern for log collection, monitoring, and proxying. In modern K8s (1.28+), sidecars are defined as `initContainers` with `restartPolicy: Always`. They share volumes with the main container, enabling patterns like tailing log files to stdout for `kubectl logs`.

**CKAD Domain:** Application Observability and Maintenance

**Task Summary:** Add a sidecar container `logger-con` (image `busybox:1.31.0`) to Deployment `cleaner` in namespace `mercury`. It should mount the same `logs` volume and run `tail -f /var/log/cleaner/cleaner.log`.

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad7326`

### Solution

```bash
ssh ckad7326

cp /opt/course/16/cleaner.yaml /opt/course/16/cleaner-new.yaml
vim /opt/course/16/cleaner-new.yaml
```

Add the sidecar as an initContainer with `restartPolicy: Always`:

```yaml
# /opt/course/16/cleaner-new.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cleaner
  namespace: mercury
spec:
  replicas: 2
  selector:
    matchLabels:
      id: cleaner
  template:
    metadata:
      labels:
        id: cleaner
    spec:
      volumes:
      - name: logs
        emptyDir: {}
      initContainers:
      - name: init
        image: bash:5.0.11
        command: ['bash', '-c', 'echo init > /var/log/cleaner/cleaner.log']
        volumeMounts:
        - name: logs
          mountPath: /var/log/cleaner
      - name: logger-con                                                # add
        image: busybox:1.31.0                                           # add
        restartPolicy: Always                                           # add — makes it a sidecar
        command: ["sh", "-c", "tail -f /var/log/cleaner/cleaner.log"]   # add
        volumeMounts:                                                   # add
        - name: logs                                                    # add
          mountPath: /var/log/cleaner                                   # add
      containers:
      - name: cleaner-con
        image: bash:5.0.11
        args: ['bash', '-c', 'while true; do echo `date`: "remove random file" >> /var/log/cleaner/cleaner.log; sleep 1; done']
        volumeMounts:
        - name: logs
          mountPath: /var/log/cleaner
```

```bash
k -f /opt/course/16/cleaner-new.yaml apply

# Wait for rollout
k -n mercury get pod

# Check the sidecar logs
k -n mercury logs <pod-name> -c logger-con
# Shows: "init" followed by timestamped "remove random file" entries
```

### Tips & Troubleshooting

> [!TIP]
> **Sidecar containers (K8s 1.28+):** Defined as `initContainers` with `restartPolicy: Always`. They start before the main container, keep running alongside it, and restart if they crash.

> [!TIP]
> **Legacy approach (pre-1.28):** Define the sidecar as a regular container under `containers:`. Both approaches work, but the new sidecar approach is preferred.

> [!TIP]
> **Viewing specific container logs:** `k logs <pod> -c <container-name>`

### References

- [Sidecar Containers](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/)
- [Logging Architecture](https://kubernetes.io/docs/concepts/cluster-administration/logging/)

---

## Question 17: InitContainer

### Context

**What is being tested:** Adding an InitContainer to prepare data before the main container starts.

**Why this matters:** InitContainers run to completion before any app containers start. They're used for setup tasks: downloading config, waiting for dependencies, populating shared volumes. This is a simple but common pattern.

**CKAD Domain:** Application Design and Build

**Task Summary:** Add InitContainer `init-con` (image `busybox:1.31.0`) to Deployment `test-init-container` in namespace `mars`. It should mount the shared volume and create `index.html` with content `check this out!` at the volume root.

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad5601`

### Solution

```bash
ssh ckad5601

cp /opt/course/17/test-init-container.yaml ~/17_test-init-container.yaml
vim 17_test-init-container.yaml
```

```yaml
# 17_test-init-container.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-init-container
  namespace: mars
spec:
  replicas: 1
  selector:
    matchLabels:
      id: test-init-container
  template:
    metadata:
      labels:
        id: test-init-container
    spec:
      volumes:
      - name: web-content
        emptyDir: {}
      initContainers:
      - name: init-con
        image: busybox:1.31.0
        command: ['sh', '-c', 'echo "check this out!" > /tmp/web-content/index.html']
        volumeMounts:
        - name: web-content
          mountPath: /tmp/web-content
      containers:
      - image: nginx:1.17.3-alpine
        name: nginx
        volumeMounts:
        - name: web-content
          mountPath: /usr/share/nginx/html
        ports:
        - containerPort: 80
```

```bash
k -f 17_test-init-container.yaml create

# Test it
k -n mars get pod -o wide  # get cluster IP
k run tmp --restart=Never --rm -i --image=nginx:alpine -- curl <POD_IP>
# Output: check this out!
```

### Tips & Troubleshooting

> [!TIP]
> **InitContainer vs Sidecar:** InitContainers run to completion and exit. Sidecars run alongside the main container continuously. Use InitContainers for one-time setup, sidecars for ongoing tasks.

> [!WARNING]
> The InitContainer and main container can mount the same volume at **different paths**. The volume content is shared regardless of mount path.

### References

- [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)

---

## Question 18: Service Misconfiguration

### Context

**What is being tested:** Debugging a Service with no endpoints due to incorrect selector labels.

**Why this matters:** This is one of the most common Kubernetes debugging scenarios. Services select Pods by labels, not by Deployment names. A mismatch between the Service selector and Pod labels means zero endpoints and connection timeouts.

**CKAD Domain:** Services & Networking

**Task Summary:** ClusterIP Service `manager-api-svc` in namespace `mars` can't reach Pods of Deployment `manager-api-deployment`. Find and fix the misconfiguration.

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad5601`

### Solution

```bash
ssh ckad5601

# Check if Service has endpoints
k -n mars describe service manager-api-svc
# Endpoints: <none>  ← Problem!

# Check the Service selector
k -n mars get svc manager-api-svc -oyaml | grep selector -A5
# selector: id: manager-api-deployment  ← Wrong! Points to deployment name, not pod label

# Check the Pod labels
k -n mars get pod --show-labels | grep manager
# Pod labels show: id=manager-api-pod

# Fix: Edit the Service selector to match Pod labels
k -n mars edit service manager-api-svc
# Change selector from: id: manager-api-deployment
# To:                    id: manager-api-pod
```

Verify the fix:

```bash
# Check endpoints now exist
k -n mars get endpointslice
# Should show endpoints with Pod IPs

# Test connectivity
k -n mars run tmp --restart=Never --rm -i --image=nginx:alpine -- curl -m 5 manager-api-svc:4444
# Should return nginx welcome page
```

### Tips & Troubleshooting

> [!TIP]
> **Debugging Service connectivity — the checklist:**
>
> 1. Does the Service exist? `k get svc`
> 2. Does it have endpoints? `k describe svc <name>` or `k get endpointslice`
> 3. Do the selector labels match Pod labels? Compare `svc.spec.selector` with `pod.metadata.labels`
> 4. Are the Pods Running and Ready?
> 5. Is the targetPort correct?

> [!TIP]
> **Key insight:** Services select **Pods** directly via labels, not Deployments. Even if a Deployment creates the Pods, the Service selector must match the Pod template labels.

### References

- [Debugging Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)

---

## Question 19: Service ClusterIP to NodePort

### Context

**What is being tested:** Converting a ClusterIP Service to NodePort to expose it on all node IPs.

**Why this matters:** NodePort is the simplest way to expose a service externally. Understanding that a NodePort Service builds on top of a ClusterIP (it still has a ClusterIP) and that the service is available on ALL node IPs regardless of where the Pod runs is critical.

**CKAD Domain:** Services & Networking

**Task Summary:** In namespace `jupiter`, convert ClusterIP Service `jupiter-crew-svc` to NodePort on port 30100. Test connectivity using node internal IPs.

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad5601`

### Solution

```bash
ssh ckad5601

# Check current state
k -n jupiter get all

# Verify ClusterIP Service works internally (optional)
k -n jupiter run tmp --restart=Never --rm -i --image=nginx:alpine -- curl -m 5 jupiter-crew-svc:8080

# Edit the Service — change type and add nodePort
k -n jupiter edit service jupiter-crew-svc
```

```yaml
spec:
  type: NodePort          # change from ClusterIP
  ports:
  - name: 8080-80
    port: 8080
    protocol: TCP
    targetPort: 80
    nodePort: 30100       # add
```

```bash
# Verify the change
k -n jupiter get svc
# TYPE: NodePort, PORT(S): 8080:30100/TCP

# Get node internal IPs
k get nodes -o wide

# Test NodePort access from main terminal
curl <NODE_INTERNAL_IP>:30100
# Returns: <html><body><h1>It works!</h1></body></html>
```

### Tips & Troubleshooting

> [!TIP]
> **NodePort behavior:** The Service is reachable on ALL node IPs (internal and external) on port 30100, even if the Pod only runs on one node. The kube-proxy handles routing.

> [!TIP]
> **NodePort range:** Default is 30000-32767. You can specify a specific port within this range.

> [!TIP]
> **Service types hierarchy:** `ClusterIP` (internal only) → `NodePort` (extends ClusterIP, adds node port) → `LoadBalancer` (extends NodePort, adds external LB)

### References

- [Service Types - NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)

---

## Question 20: NetworkPolicy

### Context

**What is being tested:** Creating a NetworkPolicy that restricts egress traffic with DNS exceptions.

**Why this matters:** NetworkPolicies are critical for security isolation. The key challenge here is understanding the difference between multiple egress rules (logical OR) vs multiple selectors within one rule (logical AND). You must allow DNS (port 53 UDP/TCP) separately from the API access rule.

**CKAD Domain:** Services & Networking

**Task Summary:** In namespace `venus`, create NetworkPolicy `np1` that restricts **outgoing** traffic from Deployment `frontend` to only allow connections to Deployment `api`, plus DNS on port 53 (UDP/TCP).

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad7326`

### Solution

```bash
ssh ckad7326

# Verify current connectivity (both should work initially)
k -n venus exec <frontend-pod> -- wget -O- www.google.com    # works
k -n venus exec <frontend-pod> -- wget -O- api:2222           # works
```

```yaml
# 20_np1.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: np1
  namespace: venus
spec:
  podSelector:
    matchLabels:
      id: frontend
  policyTypes:
  - Egress
  egress:
  - to:                       # 1st egress rule — allow to api pods
    - podSelector:
        matchLabels:
          id: api
  - ports:                    # 2nd egress rule — allow DNS
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
```

> [!WARNING]
> **Critical: Two separate egress rules = logical OR**
>
> ```yaml
> egress:
> - to: [...]      # Rule 1: allow traffic to api pods (any port)
> - ports: [...]   # Rule 2: allow DNS traffic (any destination)
> ```
>
> This means: allow if (destination is api pod) **OR** (port is 53)

> [!WARNING]
> **Common mistake: One rule with `to` + `ports` = logical AND**
>
> ```yaml
> egress:
> - to: [...]       # Same rule!
>   ports: [...]    # Same rule!
> ```
>
> This means: allow if (destination is api pod) **AND** (port is 53) — which would break the API connection on port 2222!

```bash
k -f 20_np1.yaml create

# Test: external should be blocked
k -n venus exec <frontend-pod> -- wget -O- -T 5 www.google.com
# wget: download timed out

# Test: api should still work
k -n venus exec <frontend-pod> -- wget -O- api:2222
# <html><body><h1>It works!</h1></body></html>
```

### Tips & Troubleshooting

> [!TIP]
> **NetworkPolicy learning tool:** https://editor.cilium.io (not allowed in exam, but great for practice)

> [!TIP]
> **NetworkPolicy golden rule:** If ANY NetworkPolicy selects a Pod, ALL traffic not explicitly allowed is denied. An empty `policyTypes: [Egress]` with no `egress` rules blocks ALL outgoing traffic.

### References

- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

---

## Question 21: Requests and Limits, ServiceAccount

### Context

**What is being tested:** Creating a Deployment with resource requests/limits and a custom ServiceAccount.

**Why this matters:** Resource management ensures cluster stability. Requests guarantee minimum resources; limits cap maximum usage. Combined with ServiceAccount assignment, this tests your ability to configure Pods for both resource and security requirements.

**CKAD Domain:** Application Environment, Configuration and Security

**Task Summary:** Create Deployment `neptune-10ab` in namespace `neptune` — 3 replicas, image `httpd:2.4-alpine`, container name `neptune-pod-10ab`, memory request 20Mi, memory limit 50Mi, ServiceAccount `neptune-sa-v2`.

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad7326`

### Solution

```bash
ssh ckad7326

k -n neptune create deploy neptune-10ab --replicas=3 --image=httpd:2.4-alpine \
  --dry-run=client -oyaml > 21.yaml
vim 21.yaml
```

```yaml
# 21.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: neptune-10ab
  namespace: neptune
spec:
  replicas: 3
  selector:
    matchLabels:
      app: neptune-10ab
  template:
    metadata:
      labels:
        app: neptune-10ab
    spec:
      serviceAccountName: neptune-sa-v2
      containers:
      - image: httpd:2.4-alpine
        name: neptune-pod-10ab
        resources:
          limits:
            memory: 50Mi
          requests:
            memory: 20Mi
```

```bash
k create -f 21.yaml

# Verify all 3 pods are running
k -n neptune get pod | grep neptune-10ab
```

### Tips & Troubleshooting

> [!TIP]
> **Resource specs shorthand:**
>
> - `requests` — minimum guaranteed resources (used for scheduling)
> - `limits` — maximum allowed resources (enforced at runtime, OOMKilled if exceeded for memory)
> - If only `limits` is set, `requests` defaults to `limits`

> [!TIP]
> **ServiceAccount assignment:** Add `serviceAccountName` at the Pod spec level (`spec.template.spec`), NOT at the container level.

### References

- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Configure Service Accounts for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)

---

## Question 22: Labels, Annotations

### Context

**What is being tested:** Bulk label and annotation operations using label selectors.

**Why this matters:** Labels and annotations are fundamental Kubernetes metadata. Being able to efficiently query, filter, and bulk-update labels across many Pods using selectors (`-l` flag) is a key operational skill. The `in` operator enables selecting multiple values at once.

**CKAD Domain:** Application Deployment

**Task Summary:** In namespace `sun`:

1. Add label `protected: true` to all Pods with label `type: worker` or `type: runner`
2. Add annotation `protected: do not delete this pod` to all Pods with the new `protected: true` label

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad9043`

### Solution

```bash
ssh ckad9043

# See current labels
k -n sun get pod --show-labels

# Add label to worker and runner pods (two commands or one with "in" operator)
k -n sun label pod -l "type in (worker,runner)" protected=true

# Verify
k -n sun get pod --show-labels | grep protected

# Add annotation to all pods with protected=true
k -n sun annotate pod -l protected=true protected="do not delete this pod"

# Verify
k -n sun get pod -l protected=true -o yaml | grep -A 8 metadata:
```

### Tips & Troubleshooting

> [!TIP]
> **Label selector operators:**
>
> ```bash
> -l key=value           # equality
> -l key!=value          # inequality
> -l "key in (v1,v2)"   # set-based
> -l "key notin (v1)"   # set-based negation
> -l key                 # exists
> -l '!key'             # not exists
> ```

> [!TIP]
> **Bulk operations:** The `-l` flag works with `label`, `annotate`, `delete`, `get`, and most other kubectl commands. Apply changes to many resources at once.

### References

- [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
- [Annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)

---

## Preview Question 1: Liveness Probe

### Context

**What is being tested:** Adding a liveness probe to an existing Deployment.

**Why this matters:** Liveness probes tell Kubernetes to restart a container when it becomes unhealthy. Combined with readiness probes (Q6), they form the foundation of self-healing applications. Here we use `tcpSocket` type which checks if a port is accepting connections.

**CKAD Domain:** Application Observability and Maintenance

**Task Summary:** Add a liveness probe to Deployment `project-23-api` in namespace `pluto` that checks port 80 with `initialDelaySeconds: 10` and `periodSeconds: 15`.

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad9043`

### Solution

```bash
ssh ckad9043

cp /opt/course/p1/project-23-api.yaml /opt/course/p1/project-23-api-new.yaml
vim /opt/course/p1/project-23-api-new.yaml
```

Add the liveness probe to the container spec:

```yaml
containers:
- image: httpd:2.4-alpine
  name: httpd
  # ... existing config ...
  livenessProbe:
    tcpSocket:
      port: 80
    initialDelaySeconds: 10
    periodSeconds: 15
```

```bash
k -f /opt/course/p1/project-23-api-new.yaml apply

# Wait 10+ seconds and verify Pods are still running (not restarting)
k -n pluto get pod

# Confirm probe configuration
k -n pluto describe deploy project-23-api | grep Liveness
# Liveness: tcp-socket :80 delay=10s timeout=1s period=15s
```

### Tips & Troubleshooting

> [!TIP]
> **Probe type selection guide:**
>
> | Probe Type | Use When |
> |---|---|
> | `httpGet` | App has a health endpoint (e.g., `/healthz`) |
> | `tcpSocket` | App listens on a port but has no HTTP endpoint |
> | `exec` | Need to run a custom check command |

### References

- [Configure Liveness, Readiness, and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

---

## Preview Question 2: Deployment, Service, ServiceAccount

### Context

**What is being tested:** Creating a Deployment with a ServiceAccount, exposing it via ClusterIP Service, and writing a status-check command.

**Why this matters:** This is a full end-to-end application deployment exercise combining multiple concepts: Deployments, ServiceAccounts, Services, and operational scripts. A common real-world workflow.

**CKAD Domain:** Application Deployment

**Task Summary:**

1. Create Deployment `sunny` in namespace `sun` — 4 replicas, image `nginx:1.17.3-alpine`, ServiceAccount `sa-sun-deploy`
2. Create ClusterIP Service `sun-srv` on port 9999 → targetPort 80
3. Write a status-check command to `/opt/course/p2/sunny_status_command.sh`

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad9043`

### Solution

```bash
ssh ckad9043

k -n sun create deploy sunny --image=nginx:1.17.3-alpine --dry-run=client -oyaml > p2_sunny.yaml
vim p2_sunny.yaml
```

```yaml
# p2_sunny.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sunny
  namespace: sun
spec:
  replicas: 4
  selector:
    matchLabels:
      app: sunny
  template:
    metadata:
      labels:
        app: sunny
    spec:
      serviceAccountName: sa-sun-deploy
      containers:
      - image: nginx:1.17.3-alpine
        name: nginx
```

```bash
k create -f p2_sunny.yaml
k -n sun get pod | grep sunny  # 4 running

# Expose the Deployment
k -n sun expose deployment sunny --name sun-srv --port 9999 --target-port 80

# Test
k run tmp --restart=Never --rm -i --image=nginx:alpine -- curl -m 5 sun-srv.sun:9999

# Write the status command
vim /opt/course/p2/sunny_status_command.sh
```

```bash
# /opt/course/p2/sunny_status_command.sh
kubectl -n sun get deployment sunny
```

### References

- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)

---

## Preview Question 3: Fix Broken Service

### Context

**What is being tested:** Debugging a Service that stopped working after a rollout — identifying a readiness probe misconfiguration.

**Why this matters:** This is a multi-step debugging exercise that mirrors real production incidents. The Service endpoints exist but show as "not ready" because the Pods' readiness probe is checking the wrong port. This requires systematic investigation: Service → Endpoints → Pod status → Deployment config.

**CKAD Domain:** Application Observability and Maintenance

**Task Summary:** In namespace `earth`, a Service stopped working after a rollout. Find the broken Service, fix it, and document the error in `/opt/course/p3/ticket-654.txt`.

> [!IMPORTANT]
> **Solve this question on:** `ssh ckad5601`

### Solution

```bash
ssh ckad5601

# Get overview
k -n earth get all
# Notice: earth-3cc-web deployment shows 0/4 READY

# Check Services for connectivity
k run tmp --restart=Never --rm -i --image=nginx:alpine -- curl -m 5 earth-3cc-web.earth:6363
# Connection timed out

# Check endpoints
k -n earth describe endpointslice earth-3cc-web-*
# Endpoints show Ready: false

# Investigate the Deployment
k -n earth edit deploy earth-3cc-web
```

Find the issue — the readiness probe port is wrong:

```yaml
readinessProbe:
  tcpSocket:
    port: 82        # Wrong! Should be 80
```

Fix it:

```yaml
readinessProbe:
  tcpSocket:
    port: 80        # Fixed
```

```bash
# Wait for rollout (10 seconds for initialDelaySeconds)
k -n earth get pod -l id=earth-3cc-web
# All pods should show 1/1 Running

# Verify the Service works
k run tmp --restart=Never --rm -i --image=nginx:alpine -- curl -m 5 earth-3cc-web.earth:6363
# Returns nginx welcome page

# Document the error
vim /opt/course/p3/ticket-654.txt
```

```
Wrong port for readinessProbe defined!
```

### Tips & Troubleshooting

> [!TIP]
> **Debugging flowchart for "Service not working":**
>
> 1. `k get svc` — does the Service exist?
> 2. `k get endpointslice` — are endpoints ready?
> 3. `k get pod` — are Pods Running AND Ready (1/1)?
> 4. `k describe pod` — check Events, readiness/liveness probe failures
> 5. `k describe deploy` — check rollout history, probe config

> [!TIP]
> **Pods Running but 0/1 Ready** = readiness probe is failing. Check the probe port, path, and timing.

### References

- [Debugging Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)
- [Troubleshooting](https://kubernetes.io/docs/tasks/debug/)

---

## Exam Tips

### Preparation

- **Study all topics** in the [CKAD curriculum](https://github.com/cncf/curriculum)
- **Practice on** [Killercoda CKAD scenarios](https://killercoda.com/killer-shell-ckad)
- **Read**: [Kubernetes logging concepts](https://kubernetes.io/docs/concepts/cluster-administration/logging)
- **Understand** Rolling Update Deployments including `maxSurge` and `maxUnavailable`
- Do **1-2 test sessions** with the simulator

### Allowed Resources During Exam

- https://kubernetes.io/docs
- https://kubernetes.io/blog
- https://helm.sh/docs

### Speed Tips

- **`k` alias** is pre-configured for `kubectl` with bash autocompletion
- **`history` command** and **`Ctrl+R`** for searching command history
- **Background tasks:** `Ctrl+Z` to background, `fg` to foreground
- **Fast Pod deletion:** `k delete pod x --grace-period 0 --force`
- **`yq`** is available for YAML processing

### Vim Configuration

```vim
set tabstop=2
set expandtab
set shiftwidth=2
```

**Key vim commands:**

| Action | Keys |
|---|---|
| Mark lines | `Esc` + `Shift+V` + arrow keys |
| Copy marked | `y` |
| Cut marked | `d` |
| Paste | `p` or `P` |
| Indent marked | `>` |
| Dedent marked | `<` |
| Repeat last action | `.` |
| Jump to line N | `Esc` + `:N` + Enter |
| Toggle line numbers | `:set number` / `:set nonumber` |

### Copy & Paste in Exam Environment

- **Terminal:** `Ctrl+Shift+C` and `Ctrl+Shift+V`
- **Browser/Firefox:** `Ctrl+C` and `Ctrl+V`
- **Always works:** Right-click context menu

### Exam Structure

- **15-20 questions** with automatic scoring
- Each question is solved on a **different instance** (connect via `ssh`)
- Always **return to main terminal** (`exit`) before connecting to another instance
- You can **flag questions** to return to later
- **Notepad** is available in the browser for notes
- **VSCodium** is available (no extensions allowed)

### Time Management

- Simple questions (1-3 minutes): Namespaces, labels, basic Pod creation
- Medium questions (5-8 minutes): Services, Deployments with volumes, Secrets
- Complex questions (10-15 minutes): NetworkPolicies, Helm, multi-step debugging
- **Flag and skip** questions you're stuck on — come back later
- **66% pass score** — you don't need to get everything right

---

> [!NOTE]
> This guide was generated from the Killer.sh CKAD Simulator (Kubernetes 1.35). Questions and scenarios may be updated over time. Always verify against the latest simulator version.
