# CKAD 2025–2026 Real Exam Questions & Solutions Guide

> **Based on 12+ candidate reports from Oct 2024 – Jan 2026**
> Compiled from: Aravind (Jan 2026), CodeBob (Oct 2024), Artem Lajko (Dec 2024), Umut Deniz (Sep 2025), Tech With Mohamed (2025), Sara Petres (2025), Mischa van den Burg (Jan 2025), Atsushi Suzuki (Jan 2026), Pedro Chang (Jun 2025), and KodeKloud community reports.

---

## Table of Contents

### [Domain 1 — Application Design and Build (20%)](#domain-1--application-design-and-build-20)

| # | Question | Exam Frequency |
|---|----------|----------------|
| 1.1 | [Build a Container Image with Podman and Save as Tarball](#question-11--build-a-container-image-with-podman-and-save-as-tarball) | Frequent (4 sources) |
| 1.2 | [Create a CronJob with Schedule, History Limits, and Deadline](#question-12--create-a-cronjob-with-schedule-history-limits-and-deadline) | Very High (6 sources) |
| 1.3 | [Create a One-Off Job from an Existing CronJob](#question-13--create-a-one-off-job-from-an-existing-cronjob) | Frequent (3 sources) |
| 1.4 | [Create a PVC and Mount in a Pod](#question-14--create-a-pvc-and-mount-in-a-pod) | Rare (1 source) |

### [Domain 2 — Application Deployment (20%)](#domain-2--application-deployment-20)

| # | Question | Exam Frequency |
|---|----------|----------------|
| 2.1 | [Canary Deployment with Manual Replica-Based Traffic Split](#question-21--canary-deployment-with-manual-replica-based-traffic-split) | Very High (5 sources) |
| 2.2 | [Perform a Rolling Update and Rollback](#question-22--perform-a-rolling-update-and-rollback) | High (4 sources) |
| 2.3 | [Fix a Broken Deployment YAML with Deprecated API Version](#question-23--fix-a-broken-deployment-yaml-with-deprecated-api-version) | Moderate (2 sources) |

### [Domain 3 — Application Environment, Configuration and Security (25%)](#domain-3--application-environment-configuration-and-security-25)

| # | Question | Exam Frequency |
|---|----------|----------------|
| 3.1 | [Extract Hardcoded Credentials into a Secret and Inject via secretKeyRef](#question-31--extract-hardcoded-credentials-into-a-secret-and-inject-via-secretkeyref) | Very High (4 sources) |
| 3.2 | [Create a Secret and Mount as an Environment Variable in a Named Container](#question-32--create-a-secret-and-mount-as-an-environment-variable-in-a-named-container) | Moderate (1 source) |
| 3.3 | [Create a Secret from a File and Mount as a Volume](#question-33--create-a-secret-from-a-file-and-mount-as-a-volume) | High (3 sources) |
| 3.4 | [Create a ConfigMap from a File and Mount at a Specific Path](#question-34--create-a-configmap-from-a-file-and-mount-at-a-specific-path) | High (3 sources) |
| 3.5 | [Create SA, Role, and RoleBinding from Pod Log Error](#question-35--create-sa-role-and-rolebinding-from-pod-log-error) | High (3 sources) |
| 3.6 | [Fix a Broken Pod by Finding the Correct Existing ServiceAccount](#question-36--fix-a-broken-pod-by-finding-the-correct-existing-serviceaccount) | High (3 sources) |
| 3.7 | [Configure Pod and Container Security Context with Capabilities](#question-37--configure-pod-and-container-security-context-with-capabilities) | Moderate (2 sources) |
| 3.8 | [Create a Pod with Resource Requests/Limits Under a Namespace Quota](#question-38--create-a-pod-with-resource-requestslimits-under-a-namespace-quota) | High (4 sources) |

### [Domain 4 — Services and Networking (20%)](#domain-4--services-and-networking-20)

| # | Question | Exam Frequency |
|---|----------|----------------|
| 4.1 | [Create a NodePort Service](#question-41--create-a-nodeport-service) | Moderate (2 sources) |
| 4.2 | [Fix a Service Selector Mismatch](#question-42--fix-a-service-selector-mismatch) | Moderate (2 sources) |
| 4.3 | [Create an Ingress Resource with Host-Based Routing](#question-43--create-an-ingress-resource-with-host-based-routing) | Very High (4 sources) |
| 4.4 | [Fix a Broken Ingress Returning 404](#question-44--fix-a-broken-ingress-returning-404) | Very High (4 sources) |
| 4.5 | [Fix NetworkPolicy by Correcting Pod Labels](#question-45--fix-networkpolicy-by-correcting-pod-labels) | High (3 sources) |
| 4.6 | [Create a NetworkPolicy Allowing Specific Pod-to-Pod Traffic](#question-46--create-a-networkpolicy-allowing-specific-pod-to-pod-traffic) | Moderate (1 source) |
| 4.7 | [Create a NetworkPolicy with CIDR Exception](#question-47--create-a-networkpolicy-with-cidr-exception) | Rare (1 source) |

### [Domain 5 — Application Observability and Maintenance (15%)](#domain-5--application-observability-and-maintenance-15)

| # | Question | Exam Frequency |
|---|----------|----------------|
| 5.1 | [Add a Readiness Probe to an Existing Deployment](#question-51--add-a-readiness-probe-to-an-existing-deployment) | High (4 sources) |
| 5.2 | [Debug CrashLoopBackOff and Export Events to File](#question-52--debug-crashloopbackoff-and-export-events-to-file) | Moderate (2 sources) |

### [Quick Reference — Essential Exam Commands](#quick-reference--essential-exam-commands)
### [Exam Strategy Summary](#exam-strategy-summary)

---

## Domain 1 — Application Design and Build (20%)

> **Syllabus topics:** Define, build and modify container images · Choose and use the right workload resource (Deployment, DaemonSet, CronJob, etc.) · Understand multi-container Pod design patterns · Utilize persistent and ephemeral volumes
>
> **Exam reality:** Container image build/save with Podman/Docker, CronJob creation with history limits and deadlines, and creating Jobs from CronJobs are the most consistently reported tasks in this domain. PVC questions are rare but do appear.

### Question 1.1 — Build a Container Image with Podman and Save as Tarball

**Confirmed by:** Aravind (Jan 2026), Mohamed (2025), Mischa (Jan 2025), Tyrone (Jan 2024)

#### Question

A Dockerfile exists at `/root/app-source/Dockerfile`. Perform the following:

1. Build a container image named `my-app` with tag `1.0` using Podman.
2. Save the image to a tarball at `/root/my-app.tar`.

#### Concept

The CKAD exam includes container image management tasks using either Docker or Podman (the exam environment typically has Podman). Commands are nearly identical between the two tools. The key operations are: build an image from a Dockerfile, tag it, and export/save it as a tarball.

#### Solution

**Step 1: Build the image**

```bash
cd /root/app-source
podman build -t my-app:1.0 .
```

Or with Docker:

```bash
docker build -t my-app:1.0 .
```

**Step 2: Verify the image**

```bash
podman images | grep my-app
```

**Step 3: Save to tarball**

```bash
podman save -o /root/my-app.tar my-app:1.0
```

Or with Docker:

```bash
docker save my-app:1.0 > /root/my-app.tar
```

Alternative Podman format (OCI archive):

```bash
podman save --format oci-archive -o /root/my-app.tar my-app:1.0
```

**Step 4: Verify the tarball**

```bash
ls -lh /root/my-app.tar
```

#### Points to Remember

- `podman build` and `docker build` are interchangeable in syntax.
- `podman save` uses Docker format by default. Use `--format oci-archive` if the question asks for OCI format.
- **Don't forget the `.`** at the end of the build command — it specifies the build context directory.
- The `-o` flag in `podman save` specifies the output file. With Docker, you can use `>` redirect instead.
- Some exam variants ask you to export as `.zip` — in that case: `podman save my-app:1.0 | gzip > my-app.tar.gz`.

#### Official Documentation

- [Podman Build](https://docs.podman.io/en/latest/markdown/podman-build.1.html)
- Note: The CKAD exam allows access to https://kubernetes.io/docs and https://helm.sh/docs. Podman docs may not be accessible, so memorize the basic commands.

---


### Question 1.2 — Create a CronJob with Schedule, History Limits, and Deadline

**Confirmed by:** Aravind (Jan 2026), CodeBob (Oct 2024), Umut (Sep 2025), Mohamed (2025), Mischa (Jan 2025), Atsushi (Jan 2026)

#### Question

Create a CronJob named `backup-job` in the `default` namespace with the following specifications:

- Image: `busybox:latest`
- Schedule: every 30 minutes (`*/30 * * * *`)
- Command: `echo "Backup completed"`
- `successfulJobsHistoryLimit`: 3
- `failedJobsHistoryLimit`: 2
- `activeDeadlineSeconds`: 300
- `restartPolicy`: Never

After creating the CronJob, manually trigger a one-off Job from it named `backup-job-test` and verify it completes successfully.

#### Concept

CronJobs create Jobs on a repeating schedule defined by a cron expression. The history limits control how many completed/failed Job objects are retained (for log inspection). `activeDeadlineSeconds` sets the maximum runtime for each Job before it is terminated. This is one of the most frequently reported exam tasks — appearing on nearly every exam sitting.

#### Solution

**Step 1: Create the CronJob imperatively and save YAML**

```bash
kubectl create cronjob backup-job \
  --image=busybox:latest \
  --schedule="*/30 * * * *" \
  --dry-run=client -o yaml > backup-job.yaml \
  -- /bin/sh -c "echo 'Backup completed'"
```

Edit `backup-job.yaml` to add the missing fields:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
spec:
  schedule: "*/30 * * * *"
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 2
  jobTemplate:
    spec:
      activeDeadlineSeconds: 300
      template:
        spec:
          containers:
          - name: backup
            image: busybox:latest
            command: ["/bin/sh", "-c", "echo 'Backup completed'"]
          restartPolicy: Never
```

```bash
kubectl apply -f backup-job.yaml
```

**Step 2: Manually trigger a one-off Job**

```bash
kubectl create job backup-job-test --from=cronjob/backup-job
```

**Step 3: Verify**

```bash
kubectl get jobs
kubectl get pods --selector=job-name=backup-job-test
kubectl logs job/backup-job-test
```

#### Points to Remember

- **The `kubectl create job --from=cronjob/` command is extremely high-yield** — reported by 3 candidates independently. Memorize it.
- `activeDeadlineSeconds` goes under `.spec.jobTemplate.spec`, NOT under `.spec`.
- `successfulJobsHistoryLimit` and `failedJobsHistoryLimit` go under `.spec` (CronJob level).
- `restartPolicy` must be `Never` or `OnFailure` for Jobs — `Always` is not allowed.
- Cron schedule format: `minute hour day-of-month month day-of-week`. `*/30 * * * *` = every 30 minutes.
- Use `kubectl create cronjob -h` during the exam to see the imperative command syntax quickly.

#### Official Documentation

- [CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
- [Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [Running Automated Tasks with a CronJob](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/)

---


### Question 1.3 — Create a One-Off Job from an Existing CronJob

**Confirmed by:** Aravind (Jan 2026), CodeBob (Oct 2024), Atsushi (Jan 2026)

#### Question

A CronJob named `report-generator` already exists in the `analytics` namespace. Create a one-off Job named `report-test` from this CronJob to trigger it immediately. Verify the Job runs to completion.

#### Concept

Sometimes you need to test a CronJob without waiting for its next scheduled run. The `kubectl create job --from=cronjob/` command creates a standalone Job using the CronJob's job template. This is a quick, one-liner task on the exam but easy to forget under pressure.

#### Solution

```bash
kubectl create job report-test --from=cronjob/report-generator -n analytics
```

Verify:

```bash
kubectl get jobs -n analytics
kubectl logs job/report-test -n analytics
```

#### Points to Remember

- This is a single command — no YAML needed.
- The Job inherits all spec from the CronJob's `.spec.jobTemplate`.
- Don't forget the `-n <namespace>` flag.
- The Job name must be unique — it can't match an existing Job name.

#### Official Documentation

- [Running Automated Tasks with a CronJob](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/)

---


### Question 1.4 — Create a PVC and Mount in a Pod

**Confirmed by:** Pedro Chang (Jun 2025). Note: Aravind explicitly reported zero PVC questions on his Jan 2026 exam, so this may be less frequent.

#### Question

Create a PersistentVolumeClaim named `data-pvc` in the `default` namespace with:

- Storage: `1Gi`
- Access mode: `ReadWriteOnce`
- No specific storageClassName (use default)

Then create a Pod named `data-pod` using the `nginx` image that mounts this PVC at `/data`.

#### Concept

PersistentVolumeClaims (PVCs) request storage from the cluster. When a PVC is created, Kubernetes dynamically provisions a PersistentVolume (PV) or binds to an existing one that matches the request. Pods reference PVCs as volumes.

#### Solution

**Step 1: Create the PVC**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

```bash
kubectl apply -f data-pvc.yaml
```

**Step 2: Verify the PVC is Bound**

```bash
kubectl get pvc data-pvc
# STATUS should be "Bound"
```

**Step 3: Create the Pod**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: data-pod
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: data-volume
      mountPath: /data
  volumes:
  - name: data-volume
    persistentVolumeClaim:
      claimName: data-pvc
```

```bash
kubectl apply -f data-pod.yaml
```

**Step 4: Verify**

```bash
kubectl exec data-pod -- ls /data
kubectl exec data-pod -- sh -c "echo 'test' > /data/test.txt && cat /data/test.txt"
```

#### Points to Remember

- Access modes: `ReadWriteOnce` (single node read-write), `ReadOnlyMany` (multiple nodes read-only), `ReadWriteMany` (multiple nodes read-write).
- If no `storageClassName` is specified, the default StorageClass is used.
- The PVC must be in the **same namespace** as the Pod using it.
- If the PVC stays `Pending`, check if a matching PV exists or if the StorageClass supports dynamic provisioning.
- Copy PVC YAML from the docs — it's short but has to be exact.

#### Official Documentation

- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Configure a Pod to Use a PersistentVolume for Storage](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/)

---


---

## Domain 2 — Application Deployment (20%)

> **Syllabus topics:** Use Kubernetes primitives to implement common deployment strategies (e.g., blue/green or canary) · Understand Deployments and how to perform rolling updates · Use the Helm package manager to deploy existing packages · Use Kustomize to manage application configuration
>
> **Exam reality:** Canary deployments via replica-based traffic splitting, rolling updates/rollbacks, and fixing broken Deployment manifests are the three recurring question types. Remarkably, **no 2025–2026 candidate has reported a Helm or Kustomize question** on their actual exam, despite both being on the official syllabus.

### Question 2.1 — Canary Deployment with Manual Replica-Based Traffic Split

**Confirmed by:** Aravind (Jan 2026), CodeBob (Oct 2024), Artem (Dec 2024), Umut (Sep 2025), Mohamed (2025)

#### Question

A Deployment named `web-app` exists in the `default` namespace with 5 replicas, using the image `nginx:1.20` and labels `app=webapp, version=v1`. A Service named `web-service` selects pods using `app=webapp`.

You are asked to implement a canary deployment with an **80/20 traffic split**:

1. Scale the existing `web-app` Deployment to 8 replicas.
2. Create a new Deployment named `web-app-canary` with 2 replicas, using `nginx:latest`, with labels `app=webapp, version=v2`.
3. Ensure the Service routes traffic to both Deployments (80% to v1, 20% to canary).
4. Total pod count should be 10.

#### Concept

Kubernetes does not have native traffic percentage routing. A "canary deployment" at the CKAD level uses replica counts to approximate traffic splitting. A Service selects pods using a shared label (`app=webapp`). Both Deployments have this label, so the Service load-balances across all matching pods. The ratio of replicas determines the approximate traffic split: 8 original + 2 canary = 80/20.

#### Solution

**Step 1: Scale the existing Deployment**

```bash
kubectl scale deployment web-app --replicas=8
```

**Step 2: Generate the canary Deployment YAML**

```bash
kubectl create deployment web-app-canary --image=nginx:latest --replicas=2 \
  --dry-run=client -o yaml > canary.yaml
```

Edit `canary.yaml` to ensure correct labels:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-canary
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
      version: v2
  template:
    metadata:
      labels:
        app: webapp
        version: v2
    spec:
      containers:
      - name: nginx
        image: nginx:latest
```

```bash
kubectl apply -f canary.yaml
```

**Step 3: Verify**

```bash
# Check total pod count
kubectl get pods -l app=webapp --no-headers | wc -l
# Should output: 10

# Verify Service endpoints include both
kubectl get endpoints web-service

# Test traffic distribution
for i in $(seq 1 20); do kubectl exec deployment/web-app -- curl -s web-service 2>/dev/null; done
```

#### Points to Remember

- The **Service selector** must match a label common to BOTH Deployments (e.g., `app=webapp`). The Service does NOT use the `version` label.
- The Deployment `selector.matchLabels` must match the template labels — but can include additional labels (like `version`) that the Service doesn't use.
- Traffic split = canary replicas / total replicas. For 80/20: 8 + 2 = 10. For 60/40: 6 + 4 = 10.
- Never modify the existing Service unless explicitly asked.
- `kubectl create deployment` sets the selector automatically — but verify it includes the shared label.

#### Official Documentation

- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Canary Deployments (concept)](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#canary-deployment)

---


### Question 2.2 — Perform a Rolling Update and Rollback

**Confirmed by:** Aravind (Jan 2026), CodeBob (Oct 2024), Umut (Sep 2025), Atsushi (Jan 2026)

#### Question

A Deployment named `app-v1` exists with the image `nginx:1.20`. Perform the following:

1. Update the image to `nginx:1.25`.
2. Verify the rollout completes successfully.
3. Check the rollout history.
4. Rollback to the previous version.
5. Verify the image is back to `nginx:1.20`.

#### Concept

Rolling updates are the default Deployment strategy. Kubernetes gradually replaces old pods with new ones, ensuring zero downtime. If the new version is faulty, you can rollback to any previous revision. The rollout history tracks each change.

#### Solution

**Step 1: Update the image**

```bash
kubectl set image deployment/app-v1 nginx=nginx:1.25
```

(Replace `nginx` with the actual container name — check with `kubectl get deploy app-v1 -o jsonpath='{.spec.template.spec.containers[0].name}'`)

**Step 2: Monitor rollout**

```bash
kubectl rollout status deployment/app-v1
```

**Step 3: Check history**

```bash
kubectl rollout history deployment/app-v1
```

**Step 4: Rollback**

```bash
kubectl rollout undo deployment/app-v1
```

To rollback to a specific revision:

```bash
kubectl rollout undo deployment/app-v1 --to-revision=1
```

**Step 5: Verify**

```bash
kubectl describe deployment app-v1 | grep Image
# Should show nginx:1.20
```

#### Points to Remember

- `kubectl set image` requires the container name, not just the Deployment name. Format: `deployment/<name> <container-name>=<image>`.
- Use `kubectl rollout status` to confirm before moving on — don't assume it worked.
- `kubectl rollout undo` without `--to-revision` reverts to the immediately previous revision.
- Add `--record` flag when updating to store the command in the rollout history (deprecated but still functional).

#### Official Documentation

- [Updating a Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment)
- [Rolling Back a Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)

---


### Question 2.3 — Fix a Broken Deployment YAML with Deprecated API Version

**Confirmed by:** Aravind (Jan 2026), Mohamed (2025)

#### Question

A file `/root/broken-deploy.yaml` contains a Deployment manifest with multiple errors:

1. It uses the deprecated API version `extensions/v1beta1`.
2. The `selector` field is missing.
3. The selector labels do not match the template labels.

Fix all errors and apply the Deployment successfully. The Deployment should be named `broken-app`, have 2 replicas, use the `nginx` image, and use the label `app: myapp`.

#### Concept

Older Kubernetes manifests used API versions like `extensions/v1beta1` or `apps/v1beta1` for Deployments. These were removed in Kubernetes 1.16+. All Deployments must now use `apps/v1`. Additionally, `apps/v1` requires an explicit `.spec.selector` field that matches `.spec.template.metadata.labels`.

#### Solution

**The broken YAML (typical example):**

```yaml
# BROKEN — DO NOT USE
apiVersion: extensions/v1beta1    # <-- Error 1: deprecated
kind: Deployment
metadata:
  name: broken-app
spec:
  replicas: 2
  # selector: missing entirely    # <-- Error 2: no selector
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: nginx
        image: nginx
```

**The fixed YAML:**

```yaml
apiVersion: apps/v1               # Fix 1: correct API version
kind: Deployment
metadata:
  name: broken-app
spec:
  replicas: 2
  selector:                        # Fix 2: add selector
    matchLabels:
      app: myapp                   # Fix 3: must match template labels
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: nginx
        image: nginx
```

```bash
kubectl apply -f /root/broken-deploy.yaml
kubectl rollout status deployment/broken-app
```

#### Points to Remember

- The fix is always: `extensions/v1beta1` → `apps/v1` or `apps/v1beta1` → `apps/v1`.
- `selector.matchLabels` MUST exactly match `template.metadata.labels` (or be a subset).
- Use `kubectl explain deployment.spec.selector` during the exam to remind yourself of the required fields.
- This is a quick fix task — should take under 2 minutes.

#### Official Documentation

- [Deprecated API Migration Guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide/)
- [Deployment Spec](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/)

---


---

## Domain 3 — Application Environment, Configuration and Security (25%)

> **Syllabus topics:** Discover and use resources that extend Kubernetes (CRDs, Operators) · Understand authentication, authorization and admission control · Understand requests, limits, quotas · Understand ConfigMaps · Define resource requirements · Create and consume Secrets · Understand ServiceAccounts · Understand Application Security (SecurityContexts, Capabilities, etc.)
>
> **Exam reality:** This is the highest-weighted domain and the most question-rich. Secrets (both env var and volume mount variants), ServiceAccount/RBAC debugging from pod log errors, SecurityContext with capabilities, and Resource Quota–bounded pod creation all appear consistently. CRDs have not been reported by any 2025–2026 candidate.

### Question 3.1 — Extract Hardcoded Credentials into a Secret and Inject via secretKeyRef

**Confirmed by:** Aravind (Jan 2026), Umut (Sep 2025), Mohamed (2025), Mischa (Jan 2025)

#### Question

A Deployment named `api-server` in the `default` namespace currently has hardcoded environment variables `DB_USER=admin` and `DB_PASS=Secret123!` in its container spec. This is a security concern. You are asked to:

1. Create a Secret named `db-credentials` in the `default` namespace containing the keys `DB_USER` and `DB_PASS` with the values above.
2. Update the `api-server` Deployment to reference these values from the Secret using `valueFrom.secretKeyRef` instead of hardcoded values.
3. Verify the Deployment rolls out successfully with the new configuration.

#### Concept

Kubernetes Secrets store sensitive data such as passwords, tokens, and keys. Rather than embedding credentials directly in a Pod or Deployment spec, you create a Secret object and reference it. When using `secretKeyRef`, each key from the Secret is injected as an individual environment variable into the container at runtime. Secrets are base64-encoded (not encrypted by default), so for production use you should also enable encryption at rest.

#### Solution

**Step 1: Create the Secret imperatively**

```bash
kubectl create secret generic db-credentials \
  --from-literal=DB_USER=admin \
  --from-literal=DB_PASS='Secret123!'
```

**Step 2: Verify the Secret was created**

```bash
kubectl get secret db-credentials -o yaml
```

You will see the values are base64-encoded. To decode:

```bash
kubectl get secret db-credentials -o jsonpath='{.data.DB_USER}' | base64 -d
kubectl get secret db-credentials -o jsonpath='{.data.DB_PASS}' | base64 -d
```

**Step 3: Edit the Deployment to reference the Secret**

```bash
kubectl edit deployment api-server
```

Replace the hardcoded `env` section in the container spec:

```yaml
# BEFORE (hardcoded — remove this):
env:
  - name: DB_USER
    value: "admin"
  - name: DB_PASS
    value: "Secret123!"

# AFTER (using secretKeyRef):
env:
  - name: DB_USER
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: DB_USER
  - name: DB_PASS
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: DB_PASS
```

**Step 4: Verify rollout**

```bash
kubectl rollout status deployment/api-server
kubectl exec deployment/api-server -- env | grep DB_
```

#### Points to Remember

- Use `kubectl create secret generic` for quick imperative creation — never write YAML from scratch in the exam.
- `secretKeyRef` injects individual keys as env vars; `secretRef` (under `envFrom`) injects ALL keys at once.
- If the Secret doesn't exist when the Pod starts, the container will fail to start with `CreateContainerConfigError`.
- Secret values are base64-encoded, not encrypted. Use `base64 -d` to decode.

#### Official Documentation

- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Using Secrets as Environment Variables](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables)

---


### Question 3.2 — Create a Secret and Mount as an Environment Variable in a Named Container

**Confirmed by:** Artem Lajko (Dec 2024)

#### Question

Create a Secret named `secret1` with a key `API_KEY` and value `my-api-key-12345`. Then create a Pod named `api-pod` using the `nginx` image with a container named `xy`. Inject the `API_KEY` from `secret1` as an environment variable named `API_KEY` in container `xy`.

#### Concept

This is a simpler variant of Question 1 — creating a Secret and injecting a single key as an environment variable into a specifically named container. The key distinction is that on the real exam, the container may have a specific name you must match.

#### Solution

**Step 1: Create the Secret**

```bash
kubectl create secret generic secret1 --from-literal=API_KEY=my-api-key-12345
```

**Step 2: Generate Pod YAML and edit**

```bash
kubectl run api-pod --image=nginx --dry-run=client -o yaml > api-pod.yaml
```

Edit `api-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: api-pod
spec:
  containers:
  - name: xy
    image: nginx
    env:
    - name: API_KEY
      valueFrom:
        secretKeyRef:
          name: secret1
          key: API_KEY
```

```bash
kubectl apply -f api-pod.yaml
```

**Step 3: Verify**

```bash
kubectl exec api-pod -c xy -- env | grep API_KEY
```

#### Points to Remember

- Pay attention to the **container name** in the question — if it says `xy`, don't leave the default name.
- The `-c xy` flag in `kubectl exec` targets a specific container (important in multi-container pods).

#### Official Documentation

- [Distribute Credentials Securely Using Secrets](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/)

---


### Question 3.3 — Create a Secret from a File and Mount as a Volume

**Confirmed by:** Artem Lajko (Dec 2024), Umut (Sep 2025), Mischa (Jan 2025)

#### Question

A file `/opt/credentials/db-config.txt` exists on the exam node. Create a Secret named `secret2` from this file. Then create a Pod named `secret-pod` using the `nginx` image that mounts `secret2` as a volume at the path `/etc/secrets/` inside the container.

#### Concept

Secrets can be created from files and mounted as volumes. When mounted, each key in the Secret becomes a file in the mounted directory, with the file content being the decoded Secret value. This is useful for configuration files, TLS certificates, and credentials that applications read from the filesystem.

#### Solution

**Step 1: Create the Secret from the file**

```bash
kubectl create secret generic secret2 --from-file=/opt/credentials/db-config.txt
```

This creates a Secret where the key is `db-config.txt` and the value is the file content.

**Step 2: Create the Pod with a volume mount**

```bash
kubectl run secret-pod --image=nginx --dry-run=client -o yaml > secret-pod.yaml
```

Edit `secret-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-pod
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets/
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: secret2
```

```bash
kubectl apply -f secret-pod.yaml
```

**Step 3: Verify**

```bash
kubectl exec secret-pod -- ls /etc/secrets/
kubectl exec secret-pod -- cat /etc/secrets/db-config.txt
```

#### Points to Remember

- `--from-file=<path>` uses the filename as the key. Use `--from-file=<key>=<path>` to set a custom key.
- Volume-mounted Secrets are automatically updated when the Secret changes (with a delay), unlike env vars which require a pod restart.
- Always add `readOnly: true` to Secret volume mounts for security.
- The mount path directory will only contain the Secret keys — any existing files at that path will be hidden.

#### Official Documentation

- [Using Secrets as Files from a Pod](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-files-from-a-pod)

---


### Question 3.4 — Create a ConfigMap from a File and Mount at a Specific Path

**Confirmed by:** Artem Lajko (Dec 2024), Umut (Sep 2025), Mischa (Jan 2025)

#### Question

A file `/opt/index.html` exists containing HTML content. Create a ConfigMap named `web-config` from this file. Then create a Pod named `web-pod` using the `nginx` image that mounts the ConfigMap at `/usr/share/nginx/html/`. Verify the HTML content is served correctly.

#### Concept

ConfigMaps work similarly to Secrets but are intended for non-sensitive configuration data. When mounted as a volume, each key becomes a file. This pattern is commonly used for configuration files, HTML content, and application properties. The mount replaces the entire directory contents.

#### Solution

**Step 1: Create the ConfigMap from file**

```bash
kubectl create configmap web-config --from-file=/opt/index.html
```

**Step 2: Create the Pod**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: html-volume
      mountPath: /usr/share/nginx/html/
  volumes:
  - name: html-volume
    configMap:
      name: web-config
```

```bash
kubectl apply -f web-pod.yaml
```

**Step 3: Verify**

```bash
kubectl exec web-pod -- cat /usr/share/nginx/html/index.html
kubectl exec web-pod -- curl -s localhost
```

#### Points to Remember

- ConfigMap vs Secret: ConfigMaps are for non-sensitive data and are stored in plain text. Secrets are base64-encoded.
- Mounting a ConfigMap at a directory replaces all existing files in that directory. Use `subPath` if you need to mount a single file without replacing the directory.
- ConfigMaps have a 1 MiB size limit.
- When using `--from-file`, the key name defaults to the filename.

#### Official Documentation

- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)

---


### Question 3.5 — Create SA, Role, and RoleBinding from Pod Log Error

**Confirmed by:** Aravind (Jan 2026), Umut (Sep 2025), Mischa (Jan 2025)

#### Question

In the `audit` namespace, a Pod named `log-collector` is failing. Check its logs. You will find an error like:

```
Error: User "system:serviceaccount:audit:default" cannot list resource "pods" in API group "" in the namespace "audit"
```

Fix this by:

1. Creating a ServiceAccount named `log-sa` in the `audit` namespace.
2. Creating a Role named `log-role` that allows `get`, `list`, and `watch` on `pods`.
3. Creating a RoleBinding named `log-rb` that binds `log-role` to `log-sa`.
4. Updating the Pod to use `log-sa`.

#### Concept

By default, pods use the `default` ServiceAccount which has minimal permissions. When a pod needs to interact with the Kubernetes API (e.g., list pods), it needs a ServiceAccount with an appropriate Role bound via a RoleBinding. The exam tests whether you can **diagnose** the permission error from logs and then create the correct RBAC chain.

#### Solution

**Step 1: Check the pod logs to identify the error**

```bash
kubectl logs log-collector -n audit
```

**Step 2: Create the ServiceAccount**

```bash
kubectl create serviceaccount log-sa -n audit
```

**Step 3: Create the Role**

```bash
kubectl create role log-role -n audit \
  --verb=get,list,watch \
  --resource=pods
```

**Step 4: Create the RoleBinding**

```bash
kubectl create rolebinding log-rb -n audit \
  --role=log-role \
  --serviceaccount=audit:log-sa
```

**Step 5: Update the Pod**

`serviceAccountName` is immutable on a running Pod, so you must delete and recreate:

```bash
kubectl get pod log-collector -n audit -o yaml > log-collector.yaml
```

Edit `log-collector.yaml` — add under `spec`:

```yaml
spec:
  serviceAccountName: log-sa
  # ... rest of pod spec
```

```bash
kubectl delete pod log-collector -n audit
kubectl apply -f log-collector.yaml
```

**Step 6: Verify**

```bash
kubectl get pod log-collector -n audit
kubectl logs log-collector -n audit
```

#### Points to Remember

- **`serviceAccountName` is immutable** — you MUST delete and recreate the Pod. This catches many candidates off guard.
- ServiceAccount format in RoleBinding: `--serviceaccount=<namespace>:<sa-name>`.
- Always check logs FIRST — the error message tells you exactly what permission is missing.
- Role = namespaced permissions. ClusterRole = cluster-wide. The exam typically uses Role + RoleBinding.
- All three RBAC resources can be created imperatively — no YAML needed.

#### Official Documentation

- [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Configure Service Accounts for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)

---


### Question 3.6 — Fix a Broken Pod by Finding the Correct Existing ServiceAccount

**Confirmed by:** Aravind (Jan 2026), Artem (Dec 2024), Umut (Sep 2025)

#### Question

In the `monitoring` namespace, a Pod named `metrics-pod` is using a ServiceAccount called `wrong-sa` and is failing with permission errors. Several ServiceAccounts exist in the namespace: `monitor-sa`, `wrong-sa`, `admin-sa`. Several Roles and RoleBindings also exist. Investigate which ServiceAccount has the correct permissions and update the Pod accordingly.

#### Concept

This is a **diagnostic** RBAC question. Instead of creating new resources, you must investigate existing ones to find the correct ServiceAccount. The exam uses "decoy" resources to test whether you can trace the RoleBinding → Role → ServiceAccount chain correctly.

#### Solution

**Step 1: Check the pod logs**

```bash
kubectl logs metrics-pod -n monitoring
```

**Step 2: List all RoleBindings to find which SA is bound to which Role**

```bash
kubectl get rolebindings -n monitoring -o wide
```

This shows the Role and the subjects (ServiceAccounts) for each binding. Look for the RoleBinding that grants the needed permissions (e.g., `get` on `pods/metrics`).

**Step 3: Inspect specific RoleBindings**

```bash
kubectl describe rolebinding <binding-name> -n monitoring
```

Look for the `Subjects` field — identify which SA is bound to the Role that has the required verbs/resources.

**Step 4: Verify the Role has the right permissions**

```bash
kubectl describe role <role-name> -n monitoring
```

**Step 5: Update the Pod**

```bash
kubectl get pod metrics-pod -n monitoring -o yaml > metrics-pod.yaml
# Edit: change serviceAccountName from wrong-sa to monitor-sa
kubectl delete pod metrics-pod -n monitoring
kubectl apply -f metrics-pod.yaml
```

#### Points to Remember

- Use `kubectl get rolebindings -o wide` to quickly see the SA → Role mappings.
- Don't assume — always verify the Role's actual permissions with `kubectl describe role`.
- Multiple decoy SAs/Roles exist specifically to mislead you. Trace the full chain.
- Remember: delete and recreate the Pod since `serviceAccountName` is immutable.

#### Official Documentation

- [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Checking API Access](https://kubernetes.io/docs/reference/access-authn-authz/authorization/#checking-api-access)

---


### Question 3.7 — Configure Pod and Container Security Context with Capabilities

**Confirmed by:** Aravind (Jan 2026), CodeBob (Oct 2024)

#### Question

Create a Deployment named `secure-app` with the following security requirements:

- Pod-level: `runAsUser: 1000`
- Container-level (container name `app`): add Linux capability `NET_ADMIN`
- Image: `nginx`

#### Concept

SecurityContext defines privilege and access control settings for pods and containers. Pod-level settings apply to all containers; container-level settings override pod-level for that container. Linux capabilities are fine-grained privileges that can be added or dropped at the container level.

#### Solution

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      securityContext:
        runAsUser: 1000
      containers:
      - name: app
        image: nginx
        securityContext:
          capabilities:
            add:
            - NET_ADMIN
```

```bash
kubectl apply -f secure-app.yaml
```

Verify:

```bash
kubectl exec deployment/secure-app -- id
# Should show uid=1000

kubectl exec deployment/secure-app -- cat /proc/1/status | grep Cap
```

#### Points to Remember

- **Capabilities go under the CONTAINER securityContext, not the pod-level securityContext.** This is a key trap. `capabilities` is not a valid field at the pod level.
- `runAsUser` can be set at either level. Container-level overrides pod-level.
- Capability names are uppercase without the `CAP_` prefix (e.g., `NET_ADMIN`, not `CAP_NET_ADMIN`).
- CodeBob's variant: `runAsUser: 30001` and `allowPrivilegeEscalation: false` — both at container level.

#### Official Documentation

- [Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [Set Capabilities for a Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container)

---


### Question 3.8 — Create a Pod with Resource Requests/Limits Under a Namespace Quota

**Confirmed by:** Aravind (Jan 2026), CodeBob (Oct 2024), Umut (Sep 2025), Mischa (Jan 2025)

#### Question

The namespace `prod` has a ResourceQuota with `limits.cpu: "2"` and `limits.memory: "4Gi"`. Create a Pod named `resource-pod` using the `nginx:latest` image with:

- CPU limit: half the namespace quota limit (i.e., `1` CPU)
- Memory limit: half the namespace quota limit (i.e., `2Gi`)
- CPU request: `100m`
- Memory request: `128Mi`

#### Concept

When a namespace has a ResourceQuota, every Pod must specify resource requests and limits. If a pod's requests exceed what's available in the quota, it will be rejected. The exam tests whether you can calculate the correct values based on the quota constraints.

#### Solution

**Step 1: Check the ResourceQuota**

```bash
kubectl describe resourcequota -n prod
```

**Step 2: Create the Pod**

```bash
kubectl run resource-pod --image=nginx:latest -n prod \
  --dry-run=client -o yaml > resource-pod.yaml
```

Edit `resource-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-pod
  namespace: prod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "1"
        memory: "2Gi"
```

```bash
kubectl apply -f resource-pod.yaml
```

**Step 3: Verify**

```bash
kubectl get pod resource-pod -n prod
kubectl describe resourcequota -n prod
# Check "Used" vs "Hard" values
```

#### Points to Remember

- If a namespace has a ResourceQuota, **every** pod must have resource requests and limits — otherwise it will be rejected.
- Check the quota first with `kubectl describe resourcequota` — it shows `Used` vs `Hard` limits.
- CPU is measured in millicores: `1` = 1000m. Memory: `1Gi` = 1024Mi.
- If you exceed the remaining quota, the pod creation will fail with a `forbidden` error.
- Read the question carefully — "half of the quota" is a common pattern.

#### Official Documentation

- [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
- [Managing Resources for Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

---


---

## Domain 4 — Services and Networking (20%)

> **Syllabus topics:** Demonstrate basic understanding of NetworkPolicies · Provide and troubleshoot access to applications via Services · Use Ingress rules to expose applications
>
> **Exam reality:** This domain has the highest number of distinct question types (7). Ingress creation and troubleshooting appear on nearly every exam. NetworkPolicy questions test label fixing (never policy editing) and CIDR rules. NodePort Services and selector mismatch debugging round out the domain.

### Question 4.1 — Create a NodePort Service

**Confirmed by:** Aravind (Jan 2026), Artem (Dec 2024)

#### Question

A Deployment named `api-server` exists with pods labeled `app=api` running a container on port 9090. Create a Service named `api-nodeport` of type `NodePort` that routes traffic from port 80 to the container's port 9090. Test by curling the node IP and NodePort, and save the output to `/root/nodeport-output.txt`.

#### Concept

NodePort Services expose a pod on a static port on each node's IP. External traffic hits `<NodeIP>:<NodePort>` and is routed to the Service's target pods. The NodePort range is 30000–32767.

#### Solution

**Step 1: Create the Service imperatively**

```bash
kubectl expose deployment api-server \
  --name=api-nodeport \
  --type=NodePort \
  --port=80 \
  --target-port=9090
```

Or create with a selector directly:

```bash
kubectl create service nodeport api-nodeport \
  --tcp=80:9090 \
  --dry-run=client -o yaml > nodeport.yaml
```

Edit the YAML to add the correct selector:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: api-nodeport
spec:
  type: NodePort
  selector:
    app: api
  ports:
  - port: 80
    targetPort: 9090
```

**Step 2: Get the assigned NodePort**

```bash
kubectl get svc api-nodeport
# Note the NodePort (e.g., 30XXX)
```

**Step 3: Test and save output**

```bash
curl <node-ip>:<nodeport> > /root/nodeport-output.txt
```

#### Points to Remember

- `kubectl expose deployment` is the fastest way to create a Service from a Deployment.
- `--port` is the Service port (what clients connect to). `--target-port` is the container port.
- If you need a specific NodePort, add `nodePort: 30080` under `ports` in the YAML (not possible with `kubectl expose`).
- Don't forget to save the curl output to the specified file path.

#### Official Documentation

- [Service — NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)

---


### Question 4.2 — Fix a Service Selector Mismatch

**Confirmed by:** Aravind (Jan 2026), Mischa (Jan 2025)

#### Question

A Deployment named `web-app` has pods with labels `app=webapp, tier=frontend`. A Service named `web-svc` exists but has no endpoints — no traffic is reaching the pods. Investigate and fix the Service selector.

#### Concept

A Service routes traffic to pods based on its `selector`. If the selector labels don't match any pod labels, the Service will have no endpoints, and all traffic will fail.

#### Solution

**Step 1: Check current endpoints**

```bash
kubectl get endpoints web-svc
# Shows: <none>
```

**Step 2: Check the Service selector**

```bash
kubectl get svc web-svc -o yaml | grep -A5 selector
# Might show: app: wrongapp
```

**Step 3: Check pod labels**

```bash
kubectl get pods --show-labels
# Shows: app=webapp,tier=frontend
```

**Step 4: Fix the Service**

```bash
kubectl edit svc web-svc
```

Change selector from `app: wrongapp` to `app: webapp`.

**Step 5: Verify endpoints populate**

```bash
kubectl get endpoints web-svc
# Should now show pod IPs
```

#### Points to Remember

- **Empty endpoints = selector mismatch.** Always check endpoints first when a Service isn't routing traffic.
- `kubectl get endpoints <svc>` is the fastest diagnostic command.
- The selector only needs to match a **subset** of the pod labels — it doesn't need to match all of them.

#### Official Documentation

- [Debugging Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)

---


### Question 4.3 — Create an Ingress Resource with Host-Based Routing

**Confirmed by:** Aravind (Jan 2026), Umut (Sep 2025), Mohamed (2025), killermama (May 2025)

#### Question

A Deployment `web-deploy` and a Service `web-svc` (port 8080) exist in the `default` namespace. Create an Ingress named `web-ingress` with the following specifications:

- Host: `web.example.com`
- Path: `/`
- PathType: `Prefix`
- Backend: Service `web-svc` on port 8080
- API version: `networking.k8s.io/v1`

Verify the Ingress is accessible using `curl`.

#### Concept

Ingress exposes HTTP/HTTPS routes from outside the cluster to Services within the cluster. It requires an Ingress Controller to be running. Each Ingress rule maps a host/path combination to a backend Service and port.

#### Solution

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
spec:
  rules:
  - host: web.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-svc
            port:
              number: 8080
```

```bash
kubectl apply -f web-ingress.yaml
```

Verify:

```bash
kubectl get ingress web-ingress
kubectl describe ingress web-ingress

# Test (if DNS is configured or using /etc/hosts)
curl -H "Host: web.example.com" http://<ingress-controller-ip>/
```

#### Points to Remember

- **PathType is mandatory** in `networking.k8s.io/v1` — valid values: `Prefix`, `Exact`, `ImplementationSpecific`.
- `Prefix` matches URL paths beginning with the given path. `Exact` matches exactly.
- The Service port must match the port the Service is actually listening on (not the container port).
- If the exam environment has a specific `ingressClassName`, you may need to add: `spec.ingressClassName: nginx`.
- Copy the Ingress template from the Kubernetes docs — don't write from memory.

#### Official Documentation

- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)

---


### Question 4.4 — Fix a Broken Ingress Returning 404

**Confirmed by:** Aravind (Jan 2026), Artem (Dec 2024), Mohamed (2025), Mischa (Jan 2025)

#### Question

An existing Ingress named `api-ingress` is returning a 404 error when accessed. Investigate and fix the issue. Possible causes include:

- Wrong service name in the backend
- Wrong port number
- Invalid `pathType` value
- Wrong path

Validate the fix using `curl`.

#### Concept

Ingress troubleshooting is one of the most common CKAD tasks. The approach is to work backwards from the Ingress → Service → Endpoints → Pods chain and verify each link.

#### Solution

**Step 1: Describe the Ingress**

```bash
kubectl describe ingress api-ingress
```

Check: backend service name, port, path, pathType.

**Step 2: Verify the backend Service exists and has endpoints**

```bash
kubectl get svc
kubectl get endpoints <service-name>
```

If endpoints are empty, the Service selector doesn't match any pods.

**Step 3: Compare Ingress backend with Service**

```bash
kubectl get svc <service-name> -o yaml
```

Verify the port in the Ingress matches a port defined on the Service.

**Step 4: Fix the Ingress**

```bash
kubectl edit ingress api-ingress
```

Common fixes:
- Correct the service name to match an existing Service
- Correct the port number to match the Service's port
- Fix `pathType` to a valid value (`Prefix`, `Exact`, or `ImplementationSpecific`)
- Fix the path (e.g., `/api` vs `/api/`)

**Step 5: Verify**

```bash
curl -H "Host: <hostname>" http://<ingress-ip>/api
```

#### Points to Remember

- **Troubleshooting chain:** Ingress → Service → Endpoints → Pods. Check each step.
- `kubectl describe ingress` shows the backend resolution — if it says `<error: endpoints not found>`, the Service name is wrong.
- The most common errors are: wrong service name, wrong port, invalid pathType.
- `pathType` must be one of three exact values — typos cause the Ingress to fail silently.

#### Official Documentation

- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Debugging Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)

---


### Question 4.5 — Fix NetworkPolicy by Correcting Pod Labels

**Confirmed by:** Aravind (Jan 2026), Mohamed (2025), Umut (Sep 2025)

#### Question

In the `network-demo` namespace, three Pods exist: `frontend` (label `role=wrong-frontend`), `backend` (label `role=wrong-backend`), and `database` (label `role=wrong-db`).

Two NetworkPolicies exist:
- `allow-frontend-to-backend`: allows ingress to pods with `role=backend` from pods with `role=frontend`
- `allow-backend-to-db`: allows ingress to pods with `role=db` from pods with `role=backend`

A `deny-all` NetworkPolicy also exists blocking all other traffic.

Communication is currently broken because pod labels don't match the NetworkPolicy selectors. Fix the pod labels so traffic flows correctly. **Do NOT modify the NetworkPolicies.**

#### Concept

NetworkPolicies use label selectors to define allowed traffic. If pod labels don't match the selectors in the policies, traffic will be blocked. The exam specifically tests whether you will correctly fix the labels rather than modifying the policies themselves.

#### Solution

**Step 1: Inspect the NetworkPolicies to understand expected labels**

```bash
kubectl describe networkpolicy allow-frontend-to-backend -n network-demo
kubectl describe networkpolicy allow-backend-to-db -n network-demo
```

**Step 2: Check current pod labels**

```bash
kubectl get pods -n network-demo --show-labels
```

**Step 3: Fix the labels using --overwrite**

```bash
kubectl label pod frontend -n network-demo role=frontend --overwrite
kubectl label pod backend -n network-demo role=backend --overwrite
kubectl label pod database -n network-demo role=db --overwrite
```

**Step 4: Verify connectivity**

```bash
# Test frontend → backend
kubectl exec frontend -n network-demo -- curl -s --max-time 3 backend-service

# Test backend → database
kubectl exec backend -n network-demo -- curl -s --max-time 3 database-service
```

#### Points to Remember

- **NEVER modify the NetworkPolicies** — this is explicitly tested. The fix is always on the Pod labels.
- `--overwrite` is required when a label key already exists with a different value.
- `kubectl label` is an imperative command — fast and exam-friendly.
- NetworkPolicies are **additive** — if any policy allows the traffic, it goes through.
- The `deny-all` policy is typically: `podSelector: {}` with no ingress/egress rules.
- NetworkPolicies cannot be created imperatively — if you need to create one, copy from docs.

#### Official Documentation

- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Declare Network Policy](https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/)

---


### Question 4.6 — Create a NetworkPolicy Allowing Specific Pod-to-Pod Traffic

**Confirmed by:** CodeBob (Oct 2024)

#### Question

Create a NetworkPolicy named `allow-api-to-database` in the `backend` namespace with the following rules:

- Apply to pods with label `app: database`
- Policy type: Ingress
- Allow ingress from pods with label `app: api` that are in a namespace labeled `kubernetes.io/metadata.name: goodnamespace`
- Allow only TCP traffic on port 5432

#### Concept

NetworkPolicies can combine pod selectors AND namespace selectors to tightly control traffic. This question tests creating a policy from scratch with both selectors and port restrictions.

#### Solution

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-to-database
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api
      namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: goodnamespace
    ports:
    - protocol: TCP
      port: 5432
```

```bash
kubectl apply -f allow-api-to-database.yaml
```

**Important YAML structure note:** The `podSelector` and `namespaceSelector` are in the **same** `from` array element (no `-` before `namespaceSelector`), which means they are AND-ed together. If they were separate array elements (each with `-`), they would be OR-ed.

#### Points to Remember

- **AND vs OR in NetworkPolicy `from`:** Single array element = AND. Separate array elements = OR. This is the #1 pitfall.

```yaml
# AND: pod must match BOTH selectors
- from:
  - podSelector: {matchLabels: {app: api}}
    namespaceSelector: {matchLabels: {name: good}}

# OR: pod can match EITHER selector
- from:
  - podSelector: {matchLabels: {app: api}}
  - namespaceSelector: {matchLabels: {name: good}}
```

- NetworkPolicies cannot be created with `kubectl create` — you MUST write YAML. Bookmark the docs page.
- `kubernetes.io/metadata.name` is an auto-applied label on every namespace matching the namespace name.

#### Official Documentation

- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

---


### Question 4.7 — Create a NetworkPolicy with CIDR Exception

**Confirmed by:** CodeBob (Oct 2024)

#### Question

Create a NetworkPolicy named `deny-ip-to-frontend` in the `web` namespace:

- Apply to pods labeled `app: frontend`
- Policy type: Ingress
- Allow ingress from all IPs (`0.0.0.0/0`) EXCEPT `192.168.1.10/32`

#### Concept

NetworkPolicies support CIDR-based rules with `except` blocks, allowing you to permit a broad IP range while blocking specific addresses.

#### Solution

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ip-to-frontend
  namespace: web
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 192.168.1.10/32
```

```bash
kubectl apply -f deny-ip-to-frontend.yaml
```

#### Points to Remember

- `ipBlock.except` is a list — you can exclude multiple CIDR ranges.
- `/32` means a single IP address.
- `ipBlock` rules only apply to traffic from outside the cluster (external IPs). Pod-to-pod traffic within the cluster uses pod/namespace selectors, not ipBlock.
- This question type appeared only in CodeBob's report, so it may be less frequent.

#### Official Documentation

- [Network Policies — ipBlock](https://kubernetes.io/docs/concepts/services-networking/network-policies/#behavior-of-to-and-from-selectors)

---


---

## Domain 5 — Application Observability and Maintenance (15%)

> **Syllabus topics:** Understand API deprecations · Implement probes and health checks · Use built-in CLI tools to monitor Kubernetes applications · Utilize container logs · Debugging in Kubernetes
>
> **Exam reality:** Readiness/liveness probes on existing Deployments and CrashLoopBackOff debugging (with event export to file) are the two confirmed question types. While the lowest-weighted domain, both tasks are straightforward and should be treated as "easy points."

### Question 5.1 — Add a Readiness Probe to an Existing Deployment

**Confirmed by:** Aravind (Jan 2026), CodeBob (Oct 2024), Mohamed (2025), Atsushi (Jan 2026)

#### Question

A Deployment named `api-deploy` runs a web application on port 8080 with no health checks configured. Add a readiness probe with the following specifications:

- Type: HTTP GET
- Path: `/ready`
- Port: 8080
- `initialDelaySeconds`: 5
- `periodSeconds`: 10

Verify the Deployment rolls out successfully after the change.

#### Concept

Readiness probes determine when a container is ready to accept traffic. If the probe fails, the pod is removed from Service endpoints (but not restarted). Liveness probes determine if a container is alive — if it fails, the container is restarted. The exam commonly asks for readiness probes on existing Deployments.

#### Solution

```bash
kubectl edit deployment api-deploy
```

Add under the container spec:

```yaml
containers:
- name: api
  image: <existing-image>
  ports:
  - containerPort: 8080
  readinessProbe:
    httpGet:
      path: /ready
      port: 8080
    initialDelaySeconds: 5
    periodSeconds: 10
```

Verify:

```bash
kubectl rollout status deployment/api-deploy
kubectl describe deployment api-deploy | grep -A5 Readiness
kubectl get pods -l app=api-deploy
# All pods should show READY 1/1
```

#### Points to Remember

- **Three probe types:** `httpGet` (HTTP GET request), `exec` (command execution), `tcpSocket` (TCP connection check).
- Readiness probes affect Service endpoint membership. Liveness probes trigger restarts.
- If the readiness probe path doesn't exist on the application, pods will never become Ready.
- `initialDelaySeconds` gives the application time to start up before probing begins.
- When editing a Deployment, the rolling update triggers automatically after saving.

#### Official Documentation

- [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Pod Lifecycle — Container Probes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes)

---


### Question 5.2 — Debug CrashLoopBackOff and Export Events to File

**Confirmed by:** CodeBob (Oct 2024), Umut (Sep 2025)

#### Question

Pods in the cluster are in `CrashLoopBackOff` state. Find the affected pods across all namespaces. For the crashing pod, export its events to `/root/error_events.txt`. Diagnose and fix the root cause.

#### Concept

`CrashLoopBackOff` means a container is repeatedly starting and crashing. Common causes include: wrong command/entrypoint, missing files, wrong ports, OOM kills (exit code 137), and application errors. The exam tests your ability to systematically diagnose the issue.

#### Solution

**Step 1: Find pods in CrashLoopBackOff across all namespaces**

```bash
kubectl get pods -A | grep CrashLoopBackOff
```

**Step 2: Check the pod's events and status**

```bash
kubectl describe pod <pod-name> -n <namespace>
```

Look for the `Events` section and the `Last State` with exit code.

**Step 3: Check container logs (including previous instance)**

```bash
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous
```

**Step 4: Export events to file**

```bash
kubectl get events -n <namespace> \
  --field-selector involvedObject.name=<pod-name> \
  -o wide > /root/error_events.txt
```

**Step 5: Fix the root cause**

Common fixes:
- Wrong image → `kubectl edit` or `kubectl set image`
- Wrong command → edit the pod/deployment YAML
- Wrong port → fix the containerPort
- OOM → increase memory limits
- Missing ConfigMap/Secret → create the missing resource

#### Points to Remember

- **Exit code 137** = OOMKilled (out of memory). Fix: increase memory limits.
- **Exit code 1** = application error. Check logs with `--previous` flag.
- `kubectl logs --previous` shows logs from the previous (crashed) container instance.
- `--field-selector involvedObject.name=<pod>` filters events for a specific pod.
- `-A` or `--all-namespaces` is essential for finding pods across the cluster.

#### Official Documentation

- [Debug Running Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/)
- [Application Introspection and Debugging](https://kubernetes.io/docs/tasks/debug/debug-application/)

---


---

## Quick Reference — Essential Exam Commands

```bash
# Generate YAML scaffolds (NEVER write from scratch)
kubectl run <pod> --image=<img> --dry-run=client -o yaml > pod.yaml
kubectl create deployment <dep> --image=<img> --replicas=3 --dry-run=client -o yaml > dep.yaml
kubectl create cronjob <cj> --image=<img> --schedule="*/5 * * * *" --dry-run=client -o yaml > cj.yaml
kubectl create job <job> --from=cronjob/<cj>
kubectl expose deployment <dep> --port=80 --target-port=8080 --type=NodePort

# Secrets and ConfigMaps
kubectl create secret generic <name> --from-literal=key=value
kubectl create secret generic <name> --from-file=<path>
kubectl create configmap <name> --from-file=<path>
kubectl create configmap <name> --from-literal=key=value

# RBAC
kubectl create serviceaccount <name> -n <ns>
kubectl create role <name> --verb=get,list,watch --resource=pods -n <ns>
kubectl create rolebinding <name> --role=<role> --serviceaccount=<ns>:<sa> -n <ns>

# Labels
kubectl label pod <pod> key=value --overwrite

# Rollouts
kubectl set image deployment/<dep> <container>=<image>
kubectl rollout status deployment/<dep>
kubectl rollout undo deployment/<dep>
kubectl rollout history deployment/<dep>

# Debugging
kubectl logs <pod> --previous
kubectl describe pod <pod>
kubectl get events --field-selector involvedObject.name=<pod>
kubectl get pods -A | grep CrashLoopBackOff
kubectl exec <pod> -- <command>

# Quick checks
kubectl explain <resource.field>
kubectl get all -n <namespace>
kubectl get endpoints <service>
kubectl get pods --show-labels
```

---

## Exam Strategy Summary

1. **Start with high-weight questions** — flag and skip anything that takes more than 8 minutes.
2. **Always use imperative commands first** — `kubectl run`, `kubectl create`, `kubectl expose` save minutes.
3. **Generate YAML with `--dry-run=client -o yaml`** — edit the output rather than writing from scratch.
4. **Verify every task** — `kubectl get`, `kubectl describe`, `kubectl exec`, `curl`.
5. **Remember the SSH format** — each question requires SSH to a specific node. Aliases don't persist.
6. **Use `kubectl explain`** — it shows the exact field names and types you need.
7. **Bookmark NetworkPolicy docs** — it's the one resource you can't create imperatively.

---

*Last updated: March 2026 | Based on 12+ verified candidate reports from 2025–2026 exam sittings*
