# CKS Study Notes — Supply Chain Security (20%)

> Part of the CKS study-notes set; order follows the official CKS curriculum (v1.34, Kubernetes 1.34).
> Goal: understand each topic well enough to do the task fast under exam time pressure — not exhaustively.

**What the examiner tests here:** Shrinking and hardening images, scanning for CVEs with Trivy and swapping bad images, static-analysis of manifests (kubesec), generating SBOMs, signing/verifying images, and admission-controlling which images may run. A 20% domain — Trivy is near-guaranteed.

---

## Minimize Base Image Footprint

**Why it matters:** Fewer packages = fewer CVEs and less attack surface. Tasks ask you to spot or fix a bloated/insecure Dockerfile.

**Concepts**
- Prefer `distroless`, `alpine`, or `scratch` bases.
- **Multi-stage builds**: compile in a fat builder, copy only the artifact into a tiny final image.
- Run as non-root (`USER`), pin tags (never `latest`), drop shells/package managers from the final stage.

**Commands & examples**

```dockerfile
# Multi-stage: build stage discarded, final image is tiny + non-root
FROM golang:1.22 AS build
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -o /app .

FROM gcr.io/distroless/static:nonroot   # no shell, no package manager
USER nonroot:nonroot
COPY --from=build /app /app
ENTRYPOINT ["/app"]
```

**⚠️ Exam tips:** Red flags to fix: `FROM ubuntu:latest`, `USER root` (or no USER), `apt-get` left in the final stage, secrets baked via `ENV`/`COPY`. Replacing the base with distroless + adding `USER` is often the whole fix.

---

## Scan Images with Trivy

**Why it matters:** Trivy finds OS/library CVEs in images and misconfigs in manifests. The classic task: scan, identify the vulnerable image running in the cluster, and replace it with a patched tag.

**Commands & examples**

```bash
# Scan an image for the high/critical CVEs that matter:
trivy image --severity HIGH,CRITICAL nginx:1.18.0
trivy image --severity CRITICAL --format json nginx:1.18.0 > scan.json
trivy image --ignore-unfixed --severity CRITICAL nginx:1.18.0   # only fixable

# Scan a filesystem or a manifest for misconfig:
trivy fs .
trivy config deployment.yaml

# Find which images run in the cluster, then fix the bad one:
kubectl get pods -A -o=custom-columns=\
'NS:.metadata.namespace,POD:.metadata.name,IMG:.spec.containers[*].image'
kubectl set image deploy/web web=nginx:1.27.0 -n prod
```

**⚠️ Exam tips:** Trivy docs are **not** on the allowed in-exam list — memorize the flags. Use `--severity` to cut noise and `--ignore-unfixed` when the task is "remediate fixable CVEs". The deliverable is usually a *clean image deployed*, so verify the new pod is Running on the patched tag.

---

## Static Analysis: kubesec & kube-linter

**Why it matters:** Catches insecure pod specs (privileged, no limits, writable root FS) before they ship — a quick, common task.

**Commands & examples**

```bash
# kubesec gives a score + specific advice:
kubesec scan pod.yaml
cat pod.yaml | kubesec scan /dev/stdin

# kube-linter checks against built-in best-practice rules:
kube-linter lint deployment.yaml
```
Typical fixes kubesec rewards: drop `securityContext.privileged`, set `readOnlyRootFilesystem: true`, `runAsNonRoot: true`, `capabilities.drop: [ALL]`, add resource limits, `allowPrivilegeEscalation: false`.

**⚠️ Exam tips:** Read kubesec's "advise" list and apply the highest-scoring items first. The task is graded on the *fixed manifest*, so re-scan to confirm the score went up / criticals cleared.

---

## SBOM Generation

**Why it matters:** A Software Bill of Materials inventories everything in an image so you can trace which artifacts are affected by a new CVE.

**Commands & examples**

```bash
# kubernetes-sigs/bom (bom docs ARE allowed in-exam):
bom generate -n -o sbom.spdx --image nginx:1.27.0
bom generate --image nginx:1.27.0 --format json -o sbom.json

# syft is the other common tool (SPDX or CycloneDX output):
syft nginx:1.27.0 -o spdx-json > sbom.json
```

**⚠️ Exam tips:** Two main formats — **SPDX** and **CycloneDX**. Match the format the task asks for (`-o`/`--format`). `bom` is the Kubernetes-native tool and its CLI reference is bookmarkable during the exam.

---

## Restrict Which Images Can Run

**Why it matters:** Stops untrusted/unsigned images from ever being admitted — enforced at the API server via admission control.

**Concepts & examples**
- **ImagePolicyWebhook**: apiserver calls an external service to allow/deny images.

```yaml
# AdmissionConfiguration referenced by --admission-control-config-file
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/admission/webhook.kubeconfig
      defaultAllow: false        # fail closed
```
Enable with `--enable-admission-plugins=ImagePolicyWebhook` (+ volumes/volumeMounts for the config files).

- **Allowed registries via Kyverno** (simpler, common):
```yaml
kind: ClusterPolicy
spec:
  validationFailureAction: Enforce
  rules:
  - name: allowed-registries
    match: {any: [{resources: {kinds: [Pod]}}]}
    validate:
      message: "images must come from registry.internal"
      pattern: {spec: {containers: [{image: "registry.internal/*"}]}}
```
- **Cosign + Kyverno `verifyImages`** enforces that only signed images run.

**⚠️ Exam tips:** ImagePolicyWebhook needs the apiserver flag + admission config + webhook kubeconfig + volume mounts — many moving parts; back up the manifest first. For "only allow registry X", a Kyverno `validate` pattern is the fast path.

---

## Quick command reference

```bash
trivy image --severity HIGH,CRITICAL IMG
trivy image --ignore-unfixed --severity CRITICAL IMG
trivy config MANIFEST.yaml ; trivy fs .
kubectl get pods -A -o=custom-columns='NS:.metadata.namespace,POD:.metadata.name,IMG:.spec.containers[*].image'
kubectl set image deploy/NAME C=IMG:TAG -n NS
kubesec scan pod.yaml ; kube-linter lint file.yaml
bom generate -n -o sbom.spdx --image IMG ; syft IMG -o spdx-json
# image admission: ImagePolicyWebhook (apiserver) or Kyverno allowed-registry pattern
```

## Docs to bookmark

- [Trivy](https://aquasecurity.github.io/trivy/) *(not allowed in-exam — memorize flags)*
- [kubesec](https://kubesec.io/) · [KubeLinter](https://docs.kubelinter.io/)
- [bom CLI reference](https://kubernetes-sigs.github.io/bom/cli-reference/) *(allowed in-exam)*
- [Sigstore Cosign](https://docs.sigstore.dev/cosign/overview/)
- [ImagePolicyWebhook admission controller](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#imagepolicywebhook)
- [Kyverno verifyImages / restrict registries](https://kyverno.io/policies/)
