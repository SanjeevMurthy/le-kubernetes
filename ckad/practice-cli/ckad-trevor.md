# CKAD Trevor Poirier Practice Exam — Comparison & Unique Questions Guide

> **Source:** [trevor-poirier/CKAD-Exam-Questions](https://github.com/trevor-poirier/CKAD-Exam-Questions) (16 questions)
> **Compared against:** `ckad-exam-qa-guide.md` (22 questions from 12+ candidate reports)

---

## Comparison Summary

### All 16 Trevor Questions vs Local Guide

| Trevor Q# | Topic | Local Guide Match | Verdict |
|---|---|---|---|
| Q1 | Create Secret + Pod with env vars (DB_USER/DB_PASS) | 3.2 — Secret + env var injection | **SIMILAR** — same secretKeyRef pattern |
| Q2 | SecurityContext: runAsUser 30000 + allowPrivilegeEscalation: false | 3.7 — SecurityContext + capabilities | **SIMILAR** — same domain, different fields |
| Q3 | Build image, export OCI format, create container | 1.1 — Build image + save tarball | **SIMILAR** — adds OCI format + container run |
| Q4 | Set memory request to half of namespace ResourceQuota | 3.8 — Resource requests under quota | **SIMILAR** — modify existing deploy vs create new pod |
| **Q5** | **Rolling update with maxSurge/maxUnavailable + rollback** | 2.2 — Rolling update (no strategy params) | **PARTIALLY NEW** — strategy parameters not covered |
| **Q6** | **CronJob with completions, backoffLimit, deadline + manual Job** | 1.2 + 1.3 — CronJob (no completions/retries) | **PARTIALLY NEW** — completions/backoffLimit not covered |
| **Q7** | **Find broken pod (failing livenessProbe) across random namespaces** | 5.2 — CrashLoopBackOff debug | **UNIQUE SCENARIO** — liveness path fix + decoy pods |
| Q8 | RBAC error in pod logs → create Role/RoleBinding | 3.5 — SA + Role + RoleBinding from log error | **SIMILAR** — same RBAC chain creation |
| Q9 | Create namespace + Pod with CPU/memory requests | 3.8 — simpler subset | **COVERED** — simpler version |
| Q10 | ConfigMap from literal, mount in Pod at /data/config | 3.4 — ConfigMap from file, mount | **SIMILAR** — literal vs file source |
| Q11 | Update SA on Deployment/Pod + run as root + SYS_TIME | 3.6 + 3.7 combined | **SIMILAR** — combines SA + SecurityContext |
| **Q12** | **Configure both readiness AND liveness probes on existing Pod** | 5.1 — readiness probe only | **EXPANDS** — adds liveness + endpoint setup |
| **Q13** | **Taints, tolerations + kubectl top for CPU monitoring** | **NONE** | **COMPLETELY NEW** |
| Q14 | Deployment + NodePort Service + Canary (40/60 split) | 2.1 + 4.1 combined | **SIMILAR** — same concepts, different ratio |
| **Q15** | **Node label + Node Affinity + remove taint** | **NONE** | **COMPLETELY NEW** |
| Q16 | Fix pod labels to match existing NetworkPolicy | 4.5 — NetworkPolicy label fix | **SIMILAR** — same concept |

### Summary Statistics

- **10 questions** are similar/covered by the local guide (Q1, Q2, Q3, Q4, Q8, Q9, Q10, Q11, Q14, Q16)
- **6 questions** have unique/new elements worth documenting (Q5, Q6, Q7, Q12, Q13, Q15)
- **2 questions** cover completely new topics not in the local guide at all (Q13, Q15)

---

## Table of Contents — Unique Questions

### [Workloads and Scheduling — New Topics](#workloads-and-scheduling--new-topics)

| # | Question | Source | Novelty |
|---|----------|--------|---------|
| T.1 | [Taints, Tolerations, and kubectl top for CPU Monitoring](#question-t1--taints-tolerations-and-kubectl-top-for-cpu-monitoring) | Trevor Q13 | Completely New |
| T.2 | [Node Affinity with requiredDuringSchedulingIgnoredDuringExecution](#question-t2--node-affinity-with-requiredduringschedulingignoredduringexecution) | Trevor Q15 | Completely New |
| T.3 | [Rolling Update Strategy Parameters (maxSurge / maxUnavailable)](#question-t3--rolling-update-strategy-parameters-maxsurge--maxunavailable) | Trevor Q5 | New Aspect |

### [Application Design and Build — New Topics](#application-design-and-build--new-topics)

| # | Question | Source | Novelty |
|---|----------|--------|---------|
| T.4 | [CronJob with Completions, Retries, and Deadline](#question-t4--cronjob-with-completions-retries-and-deadline) | Trevor Q6 | New Aspect |

### [Application Observability and Maintenance — New Topics](#application-observability-and-maintenance--new-topics)

| # | Question | Source | Novelty |
|---|----------|--------|---------|
| T.5 | [Liveness Probe Troubleshooting Across Multiple Namespaces](#question-t5--liveness-probe-troubleshooting-across-multiple-namespaces) | Trevor Q7 | Unique Scenario |
| T.6 | [Configure Both Readiness and Liveness Probes on an Existing Pod](#question-t6--configure-both-readiness-and-liveness-probes-on-an-existing-pod) | Trevor Q12 | Expands Existing |

---

## Workloads and Scheduling — New Topics

> These topics are absent from the local guide and cover important CKAD exam areas: taints/tolerations, node affinity, and deployment strategy tuning.

### Question T.1 — Taints, Tolerations, and kubectl top for CPU Monitoring

**Source:** Trevor Q13 | **Local Guide Coverage:** None — completely new topic

#### Question

Complete the following tasks:

1. Add a taint to the node `node01` of the cluster. Use the specification below:
   - key: `app_type`, value: `alpha`, effect: `NoSchedule`

2. Create a pod called `alpha` using the image `redis`, with a toleration to `node01`.

3. From the pods running in the Namespace `cpu-stress`, write the name only of the Pod that is consuming the most CPU to the file `~/pod.txt`.

#### Concept

**Taints and Tolerations** control which pods can be scheduled on which nodes. A taint on a node "repels" pods unless they have a matching toleration. This is used to dedicate nodes to specific workloads, prevent scheduling on nodes under maintenance, or isolate special-purpose nodes.

- **Taint** = applied to a node. Format: `key=value:effect`
- **Toleration** = applied to a pod. Declares "I can tolerate this taint."
- **Effects:** `NoSchedule` (hard — won't schedule), `PreferNoSchedule` (soft — try to avoid), `NoExecute` (evict existing pods too)

**kubectl top** shows real-time CPU/memory usage for pods and nodes (requires the Metrics Server to be installed). This is essential for identifying resource-hungry pods.

#### Solution

**Part 1: Add the taint to node01**

```bash
kubectl taint nodes node01 app_type=alpha:NoSchedule
```

Verify:

```bash
kubectl describe node node01 | grep -A5 Taints
# Should show: app_type=alpha:NoSchedule
```

**Part 2: Create the pod with a toleration**

```bash
kubectl run alpha --image=redis --dry-run=client -o yaml > alpha-pod.yaml
```

Edit `alpha-pod.yaml` to add the toleration:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: alpha
spec:
  tolerations:
  - key: "app_type"
    value: "alpha"
    effect: "NoSchedule"
    operator: "Equal"
  containers:
  - name: alpha
    image: redis
```

```bash
kubectl apply -f alpha-pod.yaml
```

Verify the pod is running (and can be scheduled despite the taint):

```bash
kubectl get pod alpha -o wide
# Should show Running, possibly on node01
```

**Part 3: Find the pod consuming the most CPU**

```bash
kubectl top pod -n cpu-stress --sort-by=cpu
```

Write the top pod's name to file:

```bash
kubectl top pod -n cpu-stress --sort-by=cpu --no-headers | head -1 | awk '{print $1}' > ~/pod.txt
```

Verify:

```bash
cat ~/pod.txt
# Expected: stress-2 (the infinite loop pod: while true; do :; done)
```

> **Why stress-2?** In the setup, `stress-2` runs `while true; do :; done` — a CPU-burning infinite loop with no sleep. `stress-3` runs `while true; do usleep 50000; done` which sleeps 50ms between iterations. `stress-1` is a redis container with modest CPU requests.

#### Points to Remember

- **Taint syntax:** `kubectl taint nodes <node> key=value:effect`
- **Remove a taint:** Append `-` to the end: `kubectl taint nodes <node> key=value:effect-`
- **Toleration `operator`:** `Equal` (must match key+value+effect) or `Exists` (only match key+effect, value ignored).
- **`kubectl top` requires Metrics Server** — if it returns "Metrics API not available," the metrics-server isn't installed or ready.
- `--sort-by=cpu` sorts descending (highest first). Also works with `--sort-by=memory`.
- The `--no-headers` flag removes the NAME/CPU/MEMORY header line, useful for piping to `awk`/`head`.

#### Official Documentation

- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Resource Metrics Pipeline](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/)

---


### Question T.2 — Node Affinity with requiredDuringSchedulingIgnoredDuringExecution

**Source:** Trevor Q15 | **Local Guide Coverage:** None — completely new topic

#### Question

1. Apply a label `app_type=beta` to the node `controlplane`.
2. Create a new Deployment called `beta-apps` using the `nginx` image with 3 replicas.
3. Set Node Affinity for the Deployment to place its Pods on the `controlplane` node only, using `requiredDuringSchedulingIgnoredDuringExecution`.
4. Remove the `NoSchedule` taint on the `controlplane` node.
5. Create the Deployment and verify that all Pods are on the `controlplane` node.

#### Concept

**Node Affinity** is an advanced scheduling mechanism that constrains which nodes a pod can be scheduled on, based on node labels. It replaces the older `nodeSelector` with more expressive rules.

Two types:
- `requiredDuringSchedulingIgnoredDuringExecution` — **hard requirement**: pods MUST be placed on matching nodes (like `nodeSelector` but more expressive).
- `preferredDuringSchedulingIgnoredDuringExecution` — **soft preference**: scheduler TRIES to place on matching nodes but will schedule elsewhere if needed.

The `IgnoredDuringExecution` part means: if node labels change after scheduling, existing pods are NOT evicted.

#### Solution

**Step 1: Label the node**

```bash
kubectl label node controlplane app_type=beta
```

Verify:

```bash
kubectl get node controlplane --show-labels | grep app_type
```

**Step 2: Remove the NoSchedule taint from controlplane**

Check existing taints first:

```bash
kubectl describe node controlplane | grep -A5 Taints
```

Remove the taint (the key varies by Kubernetes version):

```bash
# Kubernetes 1.24+
kubectl taint nodes controlplane node-role.kubernetes.io/control-plane:NoSchedule-

# Older clusters (pre-1.24)
kubectl taint nodes controlplane node-role.kubernetes.io/master:NoSchedule-
```

> **Tip:** The `-` at the end removes the taint. If unsure of the exact taint key, copy it from `kubectl describe node` output.

**Step 3: Create the Deployment with Node Affinity**

```bash
kubectl create deployment beta-apps --image=nginx --replicas=3 --dry-run=client -o yaml > beta-apps.yaml
```

Edit `beta-apps.yaml` to add the affinity block:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: beta-apps
spec:
  replicas: 3
  selector:
    matchLabels:
      app: beta-apps
  template:
    metadata:
      labels:
        app: beta-apps
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: app_type
                operator: In
                values:
                - beta
      containers:
      - name: nginx
        image: nginx
```

```bash
kubectl apply -f beta-apps.yaml
```

**Step 4: Verify all pods are on controlplane**

```bash
kubectl get pods -l app=beta-apps -o wide
# All pods should show NODE = controlplane
```

#### Points to Remember

- **Node Affinity YAML is deeply nested** — practice the indentation. The path is: `spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[].matchExpressions[]`.
- **Operators available:** `In`, `NotIn`, `Exists`, `DoesNotExist`, `Gt`, `Lt`.
- `In` means the node label value must be in the provided list. Use for exact matching.
- `Exists` only checks that the key exists — no `values` field needed.
- **Don't forget to remove the control-plane taint** — otherwise pods won't schedule even with correct affinity, since taints override affinity.
- `nodeSelector` is simpler (`nodeSelector: {app_type: beta}`) but less flexible. The exam typically asks for `nodeAffinity`.
- Use `kubectl explain pod.spec.affinity.nodeAffinity` during the exam to see the exact field structure.

#### Official Documentation

- [Assigning Pods to Nodes — Node Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity)
- [Node Affinity (Task)](https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/)

---


### Question T.3 — Rolling Update Strategy Parameters (maxSurge / maxUnavailable)

**Source:** Trevor Q5 | **Local Guide Coverage:** 2.2 covers rolling update/rollback but does NOT cover strategy parameters

#### Question

A Deployment named `web` exists in the `kdpd0023` namespace running `nginx:1.24.0` with 1 replica.

1. Update the `web` Deployment with: `maxSurge` of 10% and `maxUnavailable` of 5%.
2. Perform a rolling update of the `web` Deployment, changing the image from `nginx:1.24.0` to `nginx:1.24.1`.
3. Perform a rollback of the `web` Deployment to the previous version.

#### Concept

The `RollingUpdate` strategy controls how pods are replaced during an update:
- **maxSurge**: Maximum number of pods that can be created above the desired count during an update. Can be an absolute number or percentage.
- **maxUnavailable**: Maximum number of pods that can be unavailable during the update. Can be an absolute number or percentage.

These parameters control the speed vs availability trade-off:
- High `maxSurge` + low `maxUnavailable` = faster rollout, more resource usage, higher availability
- Low `maxSurge` + high `maxUnavailable` = slower rollout, less resource usage, potentially reduced availability

#### Solution

**Step 1: Update the rolling update strategy**

```bash
kubectl edit deployment web -n kdpd0023
```

Add/modify the strategy section under `.spec`:

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: "10%"
      maxUnavailable: "5%"
```

Or use `kubectl patch`:

```bash
kubectl patch deployment web -n kdpd0023 -p \
  '{"spec":{"strategy":{"type":"RollingUpdate","rollingUpdate":{"maxSurge":"10%","maxUnavailable":"5%"}}}}'
```

**Step 2: Perform the rolling update**

```bash
kubectl set image deployment/web nginx=nginx:1.24.1 -n kdpd0023
```

> **Note:** Replace `nginx` with the actual container name. Check with:
> `kubectl get deployment web -n kdpd0023 -o jsonpath='{.spec.template.spec.containers[0].name}'`

Monitor the rollout:

```bash
kubectl rollout status deployment/web -n kdpd0023
```

**Step 3: Rollback to previous version**

```bash
kubectl rollout undo deployment/web -n kdpd0023
```

Verify:

```bash
kubectl describe deployment web -n kdpd0023 | grep Image
# Should show nginx:1.24.0

kubectl rollout history deployment/web -n kdpd0023
```

#### Points to Remember

- **Strategy goes under `.spec.strategy`**, NOT under `.spec.template`.
- `maxSurge` and `maxUnavailable` cannot both be zero — at least one must allow change.
- Percentage values are strings in YAML: `"10%"` not `10%`.
- With 1 replica and `maxUnavailable: 5%`, Kubernetes rounds down to 0 (meaning the existing pod stays running until the new one is ready).
- With 1 replica and `maxSurge: 10%`, Kubernetes rounds up to 1 (meaning 1 extra pod can be created).
- Default values: `maxSurge: 25%`, `maxUnavailable: 25%`.
- The strategy is preserved across updates — set it once before doing the image update.

#### Official Documentation

- [Deployment Strategy](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy)
- [Rolling Update Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-update-deployment)

---


---

## Application Design and Build — New Topics

### Question T.4 — CronJob with Completions, Retries, and Deadline

**Source:** Trevor Q6 | **Local Guide Coverage:** 1.2 covers history limits and deadline; 1.3 covers Job from CronJob. Neither covers `completions` or `backoffLimit`.

#### Question

Developers occasionally need to submit pods that run periodically.

1. Create a CronJob manifest file at `~/CKAD-Exam-Questions/tmp/cronjob.yaml`.

2. The CronJob must run the shell command `uname` in a single container using the `busybox` image. The command should:
   - Run every minute
   - Complete within 28 seconds, or be terminated by Kubernetes
   - Have 2 completions
   - Have 3 retries on failure

3. The CronJob name and container name should both be `hellocron`. Create the CronJob from the manifest file.

4. Create a manual (normal) Job with the same configurations. Store the manifest at `~/CKAD-Exam-Questions/tmp/job.yaml`.

Verify the execution of both the CronJob and Job.

#### Concept

Beyond the basic CronJob fields (schedule, history limits), Jobs support:
- **`completions`**: Number of times the Job's pod must complete successfully. The Job keeps creating pods until this count is reached.
- **`backoffLimit`**: Number of retries before marking the Job as failed. Each retry creates a new pod.
- **`activeDeadlineSeconds`**: Maximum time (in seconds) the Job is allowed to run before Kubernetes terminates it.

These fields go under `.spec.jobTemplate.spec` (CronJob) or `.spec` (standalone Job).

#### Solution

**Step 1: Create the CronJob manifest**

```yaml
# ~/CKAD-Exam-Questions/tmp/cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hellocron
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      completions: 2
      backoffLimit: 3
      activeDeadlineSeconds: 28
      template:
        spec:
          containers:
          - name: hellocron
            image: busybox
            command: ["uname"]
          restartPolicy: OnFailure
```

```bash
kubectl apply -f ~/CKAD-Exam-Questions/tmp/cronjob.yaml
```

**Step 2: Create the standalone Job manifest**

```yaml
# ~/CKAD-Exam-Questions/tmp/job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: hellocron
spec:
  completions: 2
  backoffLimit: 3
  activeDeadlineSeconds: 28
  template:
    spec:
      containers:
      - name: hellocron
        image: busybox
        command: ["uname"]
      restartPolicy: OnFailure
```

```bash
kubectl apply -f ~/CKAD-Exam-Questions/tmp/job.yaml
```

**Step 3: Verify**

```bash
# Check CronJob
kubectl get cronjob hellocron
kubectl get jobs --watch
# Wait for a CronJob-triggered job to appear (within 1 minute)

# Check standalone Job
kubectl get job hellocron
kubectl get pods --selector=job-name=hellocron
kubectl logs job/hellocron
# Should output the uname result (e.g., "Linux") twice (2 completions)
```

#### Points to Remember

- **`completions`** goes under `.spec.jobTemplate.spec` (CronJob level) or `.spec` (Job level) — NOT under the pod template.
- **`backoffLimit`** also goes at the same level as `completions`.
- **`activeDeadlineSeconds`** is at the Job spec level — it limits the entire Job run time, not individual pod run time.
- `restartPolicy` must be `Never` or `OnFailure` — `Always` is not valid for Jobs.
- **Container name matters** — if the question says "container name should be hellocron," don't leave the default.
- With `completions: 2`, Kubernetes runs 2 successful pod completions sequentially (by default). Add `parallelism: 2` to run them simultaneously.
- `backoffLimit: 3` means 3 retries after the first failure (total 4 attempts before the Job is marked failed).
- Use `kubectl create cronjob -h` and `kubectl create job -h` during the exam for quick syntax reminders.

#### Official Documentation

- [Jobs — Completions and Parallelism](https://kubernetes.io/docs/concepts/workloads/controllers/job/#parallel-jobs)
- [Jobs — Pod Backoff Failure Policy](https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-backoff-failure-policy)
- [CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)

---


---

## Application Observability and Maintenance — New Topics

### Question T.5 — Liveness Probe Troubleshooting Across Multiple Namespaces

**Source:** Trevor Q7 | **Local Guide Coverage:** 5.2 covers CrashLoopBackOff debugging but not livenessProbe path diagnosis or multi-namespace pod hunting

#### Question

An application is failing due to a livenessProbe. It is currently running on one of the following namespaces (randomly assigned):
- `qa`
- `lab`
- `prod`
- `dev`

Several decoy pods also exist across these namespaces (jobs, deployments, and pods with similar names like `liveness-pod`, `liveness`, `failed-liveness`).

Tasks:
1. Identify the broken pod. Write its name and namespace to `/var/data/broken.txt` in the format `"namespace"/"pod"`.
2. Copy the application events into the file `/var/data/error.txt` using `-o wide` output specifier.
3. Fix the issue and ensure the application is running successfully.

#### Concept

This is a diagnostic question that tests three skills simultaneously:
1. **Multi-namespace pod hunting** — finding a specific broken pod across several namespaces with decoy resources
2. **Event extraction** — exporting pod events in a specific format to a file
3. **Liveness probe debugging** — identifying and fixing an incorrect probe configuration

The broken pod uses `registry.k8s.io/liveness` image with `args: ["/server"]`. This image serves a `/healthz` endpoint on port 8080. However, the livenessProbe is configured to check path `/` which returns 404, causing the probe to fail continuously.

#### Solution

**Step 1: Find the broken pod across all namespaces**

```bash
# Check all pods across the 4 namespaces
kubectl get pods -n qa -o wide
kubectl get pods -n lab -o wide
kubectl get pods -n prod -o wide
kubectl get pods -n dev -o wide
```

Or more efficiently:

```bash
kubectl get pods -A | grep -E "qa|lab|prod|dev"
```

Look for the pod named `liveness-http` — it will show frequent restarts or `CrashLoopBackOff`. The decoy pods (`liveness-pod`, `liveness`, `failed-liveness`) may also show issues but `liveness-http` is the target.

**Step 2: Write the broken pod info to file**

Once identified (e.g., in the `qa` namespace):

```bash
echo '"qa"/"liveness-http"' > /var/data/broken.txt
```

> **Note:** Replace `qa` with whichever namespace the pod is actually in.

**Step 3: Export events to file**

```bash
kubectl get events -n <namespace> --field-selector involvedObject.name=liveness-http -o wide > /var/data/error.txt
```

**Step 4: Diagnose the issue**

```bash
kubectl describe pod liveness-http -n <namespace>
```

Look at the Events section — you'll see:
```
Warning  Unhealthy  Liveness probe failed: HTTP probe failed with statuscode: 404
```

The livenessProbe checks path `/` but the `registry.k8s.io/liveness` image only serves `/healthz`.

**Step 5: Fix the liveness probe path**

Export the pod YAML:

```bash
kubectl get pod liveness-http -n <namespace> -o yaml > liveness-http.yaml
```

Edit `liveness-http.yaml` — change the probe path:

```yaml
# BEFORE (broken):
livenessProbe:
  httpGet:
    path: /
    port: 8080

# AFTER (fixed):
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
```

Delete and recreate:

```bash
kubectl delete pod liveness-http -n <namespace>
kubectl apply -f liveness-http.yaml
```

**Step 6: Verify**

```bash
kubectl get pod liveness-http -n <namespace> --watch
# Should stay Running without constant restarts
```

> **Note:** The `registry.k8s.io/liveness` image is designed to return 500 on `/healthz` after ~10 seconds (it's a demo image). So the pod WILL eventually restart — this is expected behavior. The key difference is: with path `/`, the pod fails immediately (404 on every probe); with `/healthz`, the pod runs successfully for the initial period and restarts gracefully.

#### Points to Remember

- **Decoy resources are designed to mislead** — don't fix the first broken-looking pod you find. Verify it matches the question description.
- `kubectl get pods -A` with `grep` is the fastest way to scan across namespaces.
- **Liveness probe 404 = wrong path.** Always check `kubectl describe pod` events for the exact probe failure message.
- Pod spec changes (like probes) require delete + recreate — probes are immutable on running pods.
- The `-o wide` flag adds extra columns (NODE, IP, etc.) — make sure to use it when the question specifies it.
- `--field-selector involvedObject.name=<pod>` filters events for a specific pod — essential for clean file output.

#### Official Documentation

- [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Debug Running Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/)

---


### Question T.6 — Configure Both Readiness and Liveness Probes on an Existing Pod

**Source:** Trevor Q12 | **Local Guide Coverage:** 5.1 covers adding a readiness probe only. This question adds liveness probe + both probes on the same pod with nginx endpoint setup.

#### Question

A Pod named `liveness-http` is running in the cluster with a pre-configured nginx server that has custom endpoints, but it is not responding correctly.

The infrastructure provides:
- ConfigMap `nginx-conf` — nginx config listening on port 8080 with `/healthz` and `/started` endpoints
- ConfigMap `healthz` — content served at `/healthz`
- ConfigMap `started` — content served at `/started`
- Service `liveness-http` — ClusterIP on port 8080

It is expected for Kubernetes to:
- **Restart** the Pod when the `/healthz` endpoint returns HTTP 500.
- **Never send traffic** to the Pod when the `/started` endpoint returns HTTP 500.

Configure the `liveness-http` Pod to use these endpoints — using port 8080 for each.

#### Concept

**Liveness probes** detect when an application is broken and needs to be restarted. If the liveness probe fails, Kubernetes kills the container and restarts it.

**Readiness probes** detect when an application is ready to accept traffic. If the readiness probe fails, the pod is removed from Service endpoints (no traffic sent to it) but the container is NOT restarted.

The question maps directly:
- `/healthz` → **liveness probe** (restart if failing)
- `/started` → **readiness probe** (don't send traffic if failing)

#### Solution

**Step 1: Get the current pod YAML**

```bash
kubectl get pod liveness-http -o yaml > liveness-http.yaml
```

**Step 2: Edit to add both probes**

Add under the container spec:

```yaml
spec:
  containers:
  - name: live-readi-container
    image: nginx
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /started
        port: 8080
      initialDelaySeconds: 3
      periodSeconds: 5
    volumeMounts:
      - name: config
        mountPath: /etc/nginx/conf.d/
      - name: healthz-started
        mountPath: /usr/share/nginx/html/
  volumes:
  - name: config
    configMap:
      name: nginx-conf
  - name: healthz-started
    projected:
      sources:
      - configMap:
          name: healthz
          items:
            - key: healthz
              path: healthz
      - configMap:
          name: started
          items:
            - key: started
              path: started
```

**Step 3: Delete and recreate the pod**

```bash
kubectl delete pod liveness-http
kubectl apply -f liveness-http.yaml
```

**Step 4: Verify**

```bash
# Check pod status
kubectl get pod liveness-http
# Should show READY 1/1 and Running

# Verify probes are configured
kubectl describe pod liveness-http | grep -A5 "Liveness\|Readiness"

# Test the endpoints
kubectl exec liveness-http -- curl -s localhost:8080/healthz
kubectl exec liveness-http -- curl -s localhost:8080/started
```

#### Points to Remember

- **Liveness probe failure → restart container.** Maps to "is the application alive?"
- **Readiness probe failure → remove from Service endpoints.** Maps to "can the application accept traffic?"
- Both probes can (and often should) exist on the same container — they serve different purposes.
- **Mapping hint:** If the question says "restart when X fails" → liveness. If "don't send traffic when X fails" → readiness.
- Probes are immutable on running pods — always delete and recreate.
- `initialDelaySeconds` is important — give the app time to start before probing.
- `periodSeconds` controls how often the probe runs (default: 10 seconds).
- Both probes use the same syntax (`httpGet`, `exec`, `tcpSocket`) — only the behavior on failure differs.
- If the container doesn't have `curl`, use `wget -qO- http://localhost:8080/healthz` for testing.

#### Official Documentation

- [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Pod Lifecycle — Container Probes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes)

---


---

## Quick Reference — New Commands from This Guide

```bash
# Taints
kubectl taint nodes <node> key=value:NoSchedule          # Add taint
kubectl taint nodes <node> key=value:NoSchedule-          # Remove taint
kubectl describe node <node> | grep -A5 Taints            # View taints

# Node Labels
kubectl label node <node> key=value                       # Add label
kubectl label node <node> key-                            # Remove label
kubectl get nodes --show-labels                           # View labels

# Resource Metrics
kubectl top pod -n <ns> --sort-by=cpu                     # Top CPU pods
kubectl top pod -n <ns> --sort-by=memory                  # Top memory pods
kubectl top node                                          # Node resource usage

# Rolling Update Strategy
kubectl patch deployment <dep> -n <ns> -p \
  '{"spec":{"strategy":{"type":"RollingUpdate","rollingUpdate":{"maxSurge":"10%","maxUnavailable":"5%"}}}}'

# CronJob with all fields
kubectl create cronjob <name> --image=<img> --schedule="*/1 * * * *" \
  --dry-run=client -o yaml > cronjob.yaml
# Then edit YAML to add: completions, backoffLimit, activeDeadlineSeconds

# Find pods across namespaces
kubectl get pods -A | grep -E "CrashLoopBackOff|Error"
kubectl get events -n <ns> --field-selector involvedObject.name=<pod> -o wide
```

---

## Key Exam Takeaways from Trevor's Questions

1. **Taints/Tolerations and Node Affinity are testable** — the local guide missed these scheduling topics. Practice the YAML structure for tolerations and `nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution`.

2. **`kubectl top` is exam-relevant** — metrics-server-based questions require you to identify resource-hungry pods. This is a quick-win question.

3. **Rolling update strategy parameters** (`maxSurge`/`maxUnavailable`) are distinct from simple rolling updates — know where they go in the YAML.

4. **CronJob `completions` and `backoffLimit`** are different from `successfulJobsHistoryLimit`/`failedJobsHistoryLimit` — know which goes at which level.

5. **Both probes on one pod** is a common pattern — map "restart" → liveness and "don't send traffic" → readiness.

6. **Decoy resources exist** — Trevor's Q7 creates similar-sounding pods across namespaces. The exam does this too. Don't fix the first broken thing you find — confirm it matches the question.

---

*Source: [trevor-poirier/CKAD-Exam-Questions](https://github.com/trevor-poirier/CKAD-Exam-Questions) | Compared against ckad-exam-qa-guide.md (March 2026)*
