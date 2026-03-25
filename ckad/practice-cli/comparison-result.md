# CKAD Questions Comparison Report — V1 vs V2

> **Generated:** March 2026
> **V1:** `ckad/practice-cli/ckad-exam-qa-guide.md` — 24 questions from 12+ verified candidate reports (Oct 2024–Jan 2026)
> **V2:** `cert-prep/ckad/08_Probable_Questions.md` — 50 probable questions from candidate reports, killer.sh simulator, blogs, and forums

---

## Analytics Summary

| Metric | Count |
|--------|-------|
| Total Questions in V1 | 24 |
| Total Questions in V2 | 50 |
| V2 Questions Overlapping with V1 | 20 |
| — Near-Verbatim (essentially same task) | 6 |
| — High Similarity (same core concept, minor differences) | 6 |
| — Partial Overlap (same topic area, different focus) | 8 |
| Unique V2 Questions (not in V1) | 30 |
| Unique V1 Questions (not in V2) | 5 |
| V1 Coverage by V2 | 79% (19 of 24 V1 questions have some V2 match) |
| V2 Coverage by V1 | 40% (20 of 50 V2 questions have some V1 match) |

---

## Section 1: Near-Verbatim Overlapping Questions (6)

These V2 questions are essentially the same task as their V1 counterpart, with only cosmetic differences (names, namespaces, images).

| V2 Question | V1 Question | Similarity | Key Difference |
|------------|------------|------------|----------------|
| PQ10 — Deployment Rolling Update and Rollback | Q2.2 — Perform a Rolling Update and Rollback | **Near-Verbatim** | PQ10 also creates the Deployment; V1 assumes it exists |
| PQ31 — Docker/Podman Image Build and Export | Q1.1 — Build Container Image with Podman and Save as Tarball | **Near-Verbatim** | PQ31 adds a `docker tag` step for registry |
| PQ34 — Create Job from Existing CronJob | Q1.3 — Create a One-Off Job from an Existing CronJob | **Near-Verbatim** | Different CronJob/Job names only |
| PQ36 — Canary Deployment via Replica Ratio | Q2.1 — Canary Deployment with Replica-Based Traffic Split | **Near-Verbatim** | V1 uses 8+2=10 (80/20); PQ36 uses 4+1=5 (80/20) |
| PQ40 — Fix a Broken Ingress Returning 404 | Q4.4 — Fix a Broken Ingress Returning 404 | **Near-Verbatim** | Identical task and troubleshooting approach |
| PQ41 — NetworkPolicy: Adjust Pod Labels to Match Policy | Q4.5 — Fix NetworkPolicy by Correcting Pod Labels | **Near-Verbatim** | Both emphasize "do NOT modify the NetworkPolicy" |

### Detailed Comparison

**PQ10 vs V1 Q2.2 — Rolling Update and Rollback**
- Both: update image → verify rollout → check history → rollback → verify rollback
- PQ10 starts from scratch (create Deployment first); V1 assumes Deployment exists
- Same `kubectl set image`, `rollout status`, `rollout undo` commands
- **Verdict:** Study either one; they test identical skills

**PQ31 vs V1 Q1.1 — Container Image Build and Export**
- Both: build from Dockerfile → save as tarball
- PQ31 adds `docker tag` for a local registry (extra step)
- V1 mentions OCI format variant (`--format oci-archive`)
- **Verdict:** V1 has better exam tips; PQ31 has the extra tagging step worth knowing

**PQ34 vs V1 Q1.3 — Job from CronJob**
- Identical core command: `kubectl create job <name> --from=cronjob/<cronjob-name>`
- Both verify completion with `kubectl get job` and `kubectl logs job/`
- **Verdict:** Redundant — one-liner task, study once

**PQ36 vs V1 Q2.1 — Canary Deployment**
- Both use replica-ratio traffic splitting via shared Service label
- V1 is more detailed: 8+2=10 pods, explicitly scales existing Deployment to 8
- PQ36 is simpler: 4+1=5 pods, existing Deployment stays at 4
- **Verdict:** V1 is the better reference (more complex variant covers edge cases)

**PQ40 vs V1 Q4.4 — Fix Broken Ingress 404**
- Identical troubleshooting chain: Ingress → Service → Endpoints → Pods
- Same common causes: wrong service name, wrong port, invalid pathType, missing ingressClassName
- **Verdict:** Redundant — same diagnostic approach

**PQ41 vs V1 Q4.5 — Fix NetworkPolicy via Pod Labels**
- Both: read NetworkPolicy selectors → fix pod labels with `kubectl label --overwrite`
- Both emphasize: do NOT modify the NetworkPolicy itself
- PQ41 references a specific KodeKloud forum post with namespace `ckad00018`
- **Verdict:** PQ41 provides an additional real exam scenario name (`ckad00018`)

---

## Section 2: High Similarity Questions (6)

Same core concept tested, but with meaningful differences in scope, approach, or additional steps.

| V2 Question | V1 Question | Key Differences |
|------------|------------|-----------------|
| PQ8 — CronJob with Specific Schedule | Q1.2 — CronJob with Schedule, History Limits, and Deadline | V1 adds `activeDeadlineSeconds` + manual Job trigger; PQ8 adds `concurrencyPolicy: Forbid` |
| PQ4 — RBAC: ServiceAccount with Role | Q3.5 — Create SA, Role, RoleBinding from Pod Log Error | V1 requires diagnosing RBAC error from pod logs first; PQ4 is create-only |
| PQ13 — Ingress with Path-Based Routing | Q4.3 — Ingress with Host-Based Routing | PQ13 has 3 path rules under one host; V1 has single host/path |
| PQ17 — Liveness and Readiness Probes | Q5.1 — Add Readiness Probe to Existing Deployment | PQ17 creates both probes on new Deployment; V1 edits existing Deployment |
| PQ18 — Debugging a Failing Pod | Q5.2 — Debug CrashLoopBackOff and Export Events | V1 adds event export to file (`--field-selector involvedObject.name=`) |
| PQ48 — ConfigMap as Volume for Web Content | Q3.4 — ConfigMap from File and Mount at Specific Path | PQ48 uses `--from-file=index.html=<path>` (custom key); V1 uses `--from-file=<path>` (filename as key) |

### Detailed Comparison

**PQ8 vs V1 Q1.2 — CronJob Creation**
- V1 is more comprehensive: includes `activeDeadlineSeconds`, `successfulJobsHistoryLimit`, `failedJobsHistoryLimit`, AND manually triggering a Job from it
- PQ8 adds `concurrencyPolicy: Forbid` (not in V1)
- **Recommendation:** Study both — V1 for deadline/history, PQ8 for concurrency policy

**PQ4 vs V1 Q3.5 — RBAC**
- PQ4 is straightforward create: SA → Role → RoleBinding → verify with `auth can-i`
- V1 Q3.5 starts by reading pod logs to identify the missing permission, THEN creates RBAC
- V1 also requires updating the Pod's `serviceAccountName` (immutable — must delete/recreate)
- **Recommendation:** V1 is the harder, more exam-realistic variant. PQ4 covers multi-apiGroup Role creation

**PQ13 vs V1 Q4.3 — Ingress Creation**
- PQ13 has 3 paths (`/products`, `/orders`, `/`) under one host with `ingressClassName`
- V1 Q4.3 has single host/path routing
- PQ13 is the more exam-representative version (multiple paths are common)
- **Recommendation:** PQ13 is the better practice question

**PQ17 vs V1 Q5.1 — Probes**
- PQ17 creates a new Deployment with both liveness + readiness probes from scratch
- V1 Q5.1 edits an existing Deployment to add only a readiness probe
- V1 approach (`kubectl edit`) is more exam-realistic
- **Recommendation:** Study both for probe YAML syntax + edit workflow

**PQ18 vs V1 Q5.2 — Debug CrashLoopBackOff**
- V1 adds the critical event export step: `kubectl get events --field-selector involvedObject.name=<pod> > /root/error_events.txt`
- PQ18 provides a broader list of common fixes (wrong image, command, OOM, permissions)
- **Recommendation:** V1 is essential for the event export pattern; PQ18 for the diagnostic checklist

**PQ48 vs V1 Q3.4 — ConfigMap Volume Mount**
- PQ48 uses `--from-file=index.html=/path/to/file` (custom key name) — a killer.sh-specific pattern
- V1 uses `--from-file=/opt/index.html` (filename becomes key)
- PQ48 tests that existing Deployment auto-picks up ConfigMap changes
- **Recommendation:** PQ48 adds the custom-key technique worth learning

---

## Section 3: Partial Overlap Questions (8)

Same topic domain, but different enough that both are worth studying.

| V2 Question | V1 Question | Overlap Area | Why Both Matter |
|------------|------------|-------------|-----------------|
| PQ1 — ConfigMap with Env Vars and Volume Mount | Q3.4 — ConfigMap from File and Mount | ConfigMap usage | PQ1 teaches `configMapKeyRef` env injection; V1 teaches from-file creation |
| PQ2 — Secret with Volume Mount + Permissions | Q3.3 — Secret from File and Volume Mount | Secret volume mounts | PQ2 adds `defaultMode: 0400` permissions; V1 uses `--from-file` |
| PQ3 — SecurityContext with Non-Root User | Q3.7 — SecurityContext with Capabilities | SecurityContext | PQ3 is comprehensive (runAsUser/Group, fsGroup, readOnlyRootFilesystem, drop ALL + add); V1 focuses on pod vs container level capabilities |
| PQ5 — ResourceRequirements and LimitRange | Q3.8 — Resource Requests/Limits Under Quota | Resource management | PQ5 creates LimitRange; V1 works within existing ResourceQuota |
| PQ14 — NetworkPolicy: Allow Specific Pods | Q4.6 — NetworkPolicy with Pod-to-Pod Traffic | NetworkPolicy creation | PQ14 includes default-deny + allow; V1 combines podSelector + namespaceSelector (AND vs OR) |
| PQ15 — ClusterIP to NodePort Conversion | Q4.1 — Create a NodePort Service | NodePort Services | PQ15 adds `kubectl patch` to convert type; V1 uses `kubectl expose` |
| PQ32 — PV + PVC + Deployment Mount | Q1.4 — Create PVC and Mount in Pod | Persistent storage | PQ32 creates PV + PVC + Deployment; V1 creates PVC + Pod only |
| PQ38 — Fix Deprecated Ingress API Version | Q2.3 — Fix Deprecated Deployment API Version | API version migration | PQ38: `networking.k8s.io/v1beta1` → `v1` (Ingress); V1: `extensions/v1beta1` → `apps/v1` (Deployment) |

---

## Section 4: Unique V2 Questions NOT in V1 (30 Questions)

These questions cover topics, patterns, or task types that are completely absent from V1. **These represent gaps in V1's coverage.**

### Domain 1: Application Environment, Configuration and Security

| # | Question | Topic Gap in V1 |
|---|----------|----------------|
| PQ6 | ServiceAccount Token Automounting | `automountServiceAccountToken: false` pattern |
| PQ27 | Custom Resource Definitions — Create and Query CRs | CRD/CR usage (in CKAD syllabus but no V1 coverage) |
| PQ28 | ServiceAccount Token — Extract and Decode | `kubectl create token` and jsonpath token extraction |
| PQ29 | Convert Pod to Deployment with SecurityContext | Pod → Deployment conversion technique |
| PQ30 | ResourceQuota and LimitRange Interaction | Combined LimitRange + ResourceQuota + quota violation testing |
| PQ35 | Multi-Container Pod with Per-Container User IDs | Per-container `runAsUser` with shared `fsGroup` |

### Domain 2: Application Design and Build

| # | Question | Topic Gap in V1 |
|---|----------|----------------|
| PQ7 | Sidecar Container for Log Shipping | Multi-container sidecar pattern with shared emptyDir |
| PQ9 | Init Container Waiting for Dependency | Init containers with DNS-based service dependency |
| PQ22 | Deployment with Recreate Strategy | `strategy.type: Recreate` (V1 only covers RollingUpdate) |
| PQ23 | Job with Specific Completions | Job with `completions`, `backoffLimit`, `activeDeadlineSeconds` |
| PQ33 | StorageClass Creation and PVC Pending Diagnosis | StorageClass + PVC pending diagnosis + write reason to file |
| PQ49 | Sidecar Container Added to Existing Deployment | Adding sidecar to existing Deployment via `kubectl edit` |

### Domain 3: Application Deployment

| # | Question | Topic Gap in V1 |
|---|----------|----------------|
| PQ11 | Deployment Scaling and HPA | `kubectl autoscale` / HorizontalPodAutoscaler |
| PQ12 | Helm Operations | Helm install/upgrade/rollback/uninstall lifecycle |
| PQ37 | Helm Multi-Operation Task | Advanced Helm: delete release, upgrade version, fix pending-install |
| PQ39 | Blue-Green Deployment via Service Selector Switch | Blue-green strategy with `kubectl patch svc` selector switch |
| PQ26 | Fix Broken Deployment Due to Incorrect Secret Reference | Debug `CreateContainerConfigError` from wrong Secret name |

### Domain 4: Services and Networking

| # | Question | Topic Gap in V1 |
|---|----------|----------------|
| PQ16 | NetworkPolicy with Namespace Selector | Cross-namespace NetworkPolicy with `namespaceSelector` + DNS egress |
| PQ24 | Ingress with Default Backend | `defaultBackend` configuration in Ingress |
| PQ42 | Service Creation with Verification and Output to File | End-to-end: create Pod → expose as Service → curl → save response/logs to file |
| PQ43 | Ingress with TLS Termination | TLS section in Ingress with `tls.secretName` |

### Domain 5: Application Observability and Maintenance

| # | Question | Topic Gap in V1 |
|---|----------|----------------|
| PQ19 | kubectl top and Resource Analysis | `kubectl top pods --sort-by=cpu/memory` + save to file |
| PQ20 | Exec Probe for Liveness | Exec-based liveness probe (`exec.command: ["cat", "/tmp/healthy"]`) |
| PQ21 | Multi-Container Pod Logging | `kubectl logs -c <container>`, `--tail`, `-f`, `--previous` |
| PQ25 | Labels, Selectors, and Filtering | Label operations: `-l`, `--show-labels`, `kubectl label -l`, remove label with `-` |
| PQ44 | Pod Running But Not Receiving Traffic | Readiness probe failure diagnosis (Running ≠ Ready) |
| PQ45 | Move Pod Between Namespaces | Export → clean metadata → change namespace → delete → recreate |
| PQ46 | JSONPath for Extracting Pod Information | `kubectl get -o jsonpath` extraction patterns |
| PQ47 | Startup Probe for Slow-Starting Application | `startupProbe` for slow-starting apps (disables liveness until startup succeeds) |
| PQ50 | Events Filtering and Sorting | `kubectl get events --sort-by`, `--field-selector type=Warning` |

---

## Section 5: Unique V1 Questions NOT in V2 (5 Questions)

These V1 questions cover patterns not represented in V2.

| V1 Question | Topic | Why It's Important |
|------------|-------|-------------------|
| Q3.1 — Extract Hardcoded Credentials into Secret via secretKeyRef | Refactoring env vars to use `valueFrom.secretKeyRef` | Very High exam frequency (4 sources); tests the specific edit-in-place pattern of replacing `value:` with `valueFrom:` |
| Q3.2 — Create Secret as Env Var in Named Container | Secret injection via env var into specifically named container | Tests attention to container name detail (`-c xy` flag) |
| Q3.6 — Fix Broken Pod by Finding Correct Existing ServiceAccount | Diagnostic RBAC: investigate existing RoleBindings to find correct SA among decoys | Tests investigation skills, not creation; uses `kubectl get rolebindings -o wide` |
| Q4.2 — Fix Service Selector Mismatch | Debug empty Service endpoints by fixing selector labels | Tests `kubectl get endpoints` diagnostic pattern |
| Q4.7 — NetworkPolicy with CIDR Exception | `ipBlock` with `cidr` + `except` in NetworkPolicy | Tests `ipBlock.except` list syntax |

---

## Section 6: Domain Coverage Comparison

### V1 Question Distribution by Domain

| Domain | V1 Count | V1 % | CKAD Weight |
|--------|----------|-------|-------------|
| D1: Application Design and Build | 4 | 17% | 20% |
| D2: Application Deployment | 3 | 13% | 20% |
| D3: App Environment, Config & Security | 8 | 33% | 25% |
| D4: Services and Networking | 7 | 29% | 20% |
| D5: Observability and Maintenance | 2 | 8% | 15% |
| **Total** | **24** | **100%** | **100%** |

### V2 Question Distribution by Domain

| Domain | V2 Count | V2 % | CKAD Weight |
|--------|----------|-------|-------------|
| D1: App Environment, Config & Security | 12 | 24% | 25% |
| D2: Application Design and Build | 10 | 20% | 20% |
| D3: Application Deployment | 9 | 18% | 20% |
| D4: Services and Networking | 10 | 20% | 20% |
| D5: Observability and Maintenance | 9 | 18% | 15% |
| **Total** | **50** | **100%** | **100%** |

### Key Coverage Gaps in V1 (topics in V2 but not V1)

| Topic | V2 Questions | V1 Coverage |
|-------|-------------|-------------|
| Helm operations | PQ12, PQ37 | None |
| Init containers | PQ9 | None |
| Sidecar containers | PQ7, PQ49 | None |
| HPA / autoscaling | PQ11 | None |
| CRDs / Custom Resources | PQ27 | None |
| Blue-Green deployment | PQ39 | None |
| Recreate deployment strategy | PQ22 | None |
| Startup probes | PQ47 | None |
| JSONPath extraction | PQ46 | None |
| kubectl top / resource analysis | PQ19 | None |
| Move pod between namespaces | PQ45 | None |
| StorageClass creation | PQ33 | None |
| TLS Ingress | PQ43 | None |
| Labels & selectors operations | PQ25 | None |
| Events filtering/sorting | PQ50 | None |
| ServiceAccount token automounting | PQ6 | None |
| Job with completions/backoffLimit | PQ23 | None |

---

## Section 7: Recommendations

### For V1 Improvement

1. **Critical gaps to fill** (high exam frequency in V2):
   - Helm operations (PQ12, PQ37) — despite no 2025-2026 candidate reports, it's on the syllabus
   - Sidecar/init container patterns (PQ7, PQ9, PQ49) — heavily tested per V2 sources
   - Startup probes (PQ47) — fills the probe coverage gap
   - JSONPath extraction (PQ46) — common quick-win exam task

2. **Medium priority additions**:
   - HPA creation (PQ11)
   - Blue-green deployment (PQ39)
   - TLS Ingress (PQ43)
   - kubectl top (PQ19)
   - Move pod between namespaces (PQ45)

3. **V1 strengths to preserve** (unique content not in V2):
   - Q3.1's secretKeyRef refactoring pattern
   - Q3.6's diagnostic RBAC investigation with decoy SAs
   - Q4.2's Service endpoint debugging
   - Q4.7's CIDR exception syntax

### For Study Strategy

- **Start with V1**: It covers the most frequently confirmed exam questions with detailed solutions and exam tips
- **Supplement with unique V2 questions**: The 30 unique V2 questions fill important gaps, especially in Helm, multi-container patterns, and observability
- **Focus on killer.sh questions**: PQ28, PQ29, PQ32, PQ33, PQ37, PQ42, PQ45, PQ48, PQ49 are verbatim from the official CKAD simulator — high-value practice

---

*This comparison report was generated by analyzing all 24 V1 questions and all 50 V2 questions for topic overlap, task similarity, and verbatim matches.*
