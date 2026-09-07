# CKS Study Notes: Supply Chain Security (20%)

> Exam environment: Kubernetes **v1.35**. The published curriculum document is versioned v1.34, the cluster you get is newer.
> This is the largest single domain at 20 percent, and it is also the domain with the least allowed documentation. Most of the tooling here has to come out of memory.

Trivy, kubesec and kube-linter documentation are **not** on the allowed list, so their flags have to be memorised and `trivy --help` on the task host is the only in-exam fallback. The bom CLI reference at https://kubernetes-sigs.github.io/bom/cli-reference/ **is** allowed, and so is kubernetes.io, which is where the ImagePolicyWebhook page lives. There is no `jq` on the task hosts, so every list of images is read with `-o custom-columns` or `-o jsonpath`, and JSON files are read with `yq -p json`. Do not assume a Docker CLI: build with `podman` and inspect running containers with `crictl`.

<!-- toc -->
## Table of Contents

- [What the exam asks](#what-the-exam-asks)
- [Recipe 1: Build a minimal, non-root image](#recipe-1-build-a-minimal-non-root-image)
- [Recipe 2: Find the issues in a Dockerfile and a manifest](#recipe-2-find-the-issues-in-a-dockerfile-and-a-manifest)
- [Recipe 3: Trivy scan of the images running in a namespace](#recipe-3-trivy-scan-of-the-images-running-in-a-namespace)
- [Recipe 4: kubesec and kube-linter on a manifest](#recipe-4-kubesec-and-kube-linter-on-a-manifest)
- [Recipe 5: Generate and query an SBOM with bom](#recipe-5-generate-and-query-an-sbom-with-bom)
- [Recipe 6: Sign, verify and pin images by digest](#recipe-6-sign-verify-and-pin-images-by-digest)
- [Recipe 7: ImagePolicyWebhook end to end](#recipe-7-imagepolicywebhook-end-to-end)
- [Recipe 8: Restrict which registries may run](#recipe-8-restrict-which-registries-may-run)
- [Quick reference](#quick-reference)
- [Memorise](#memorise)

<!-- toc stop -->

## What the exam asks

| Task type | Sources | Drill |
|---|---|---|
| ImagePolicyWebhook admission, end to end | 12 | Q14, Q21 |
| Trivy: scan the images used in a namespace, delete or report the vulnerable pods | 9 | Q13 |
| Dockerfile and manifest static analysis, "find the two issues" | 8 | Q15, Q27 |
| Permitted registries with Gatekeeper or Kyverno | 5 | Q11 |
| SBOM with bom, plus kubesec and kube-linter | 5 | Q15, Q38 |
| Cosign signing and digest pinning | 1 | Killercoda "Image Use Digest" |

Counts are distinct candidate sources reporting that task type in the exam research table, not a share of the exam. ImagePolicyWebhook at 12 sources sits in the top tier alongside Falco, audit logging, kube-bench, AppArmor, NetworkPolicy, RBAC and gVisor. It is also the single most reported way to kill the API server, so Recipe 7 is the one to rehearse until the recovery sequence is automatic.

## Recipe 1: Build a minimal, non-root image

**Goal.** A Dockerfile produces a small final image that runs as a non-root UID from a pinned base, with no build toolchain, no package manager and no secrets left in the layers.
**Frequency.** No source reports image building as a standalone task. It rides inside the static analysis family, 8 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md), and Killercoda ships it as "Container Image Footprint User". Drill: Q27.
**Commands.** The multi-stage shape the grader wants, where the build stage keeps the compiler and the final stage keeps only the binary:

```dockerfile
FROM golang:1.24.6 AS build
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -o /out/app .

FROM gcr.io/distroless/static:nonroot
USER 1001:1001
COPY --from=build /out/app /app
ENTRYPOINT ["/app"]
```

When distroless is unavailable, `alpine:3.20` with `RUN adduser -D -u 1001 app` and `USER 1001` is the same shape. Build and inspect it without Docker:

```bash
podman build -t app:1.0.0 . ; podman images ; podman history app:1.0.0
```
**Verify.**
```bash
podman run --rm app:1.0.0 id                 # uid=1001, not uid=0(root)
podman inspect app:1.0.0 --format '{{.Config.User}}'   # 1001:1001, never empty
podman run --rm app:1.0.0 sh                 # distroless: no shell, command fails
```
**Gotchas.**
- `USER` has to come after the last `RUN` that needs root. Putting it at the top makes `apt-get` or `adduser` fail and the build never finishes.
- A numeric UID is safer than a name. `runAsNonRoot: true` in a pod cannot tell that a named user is non-root, so it rejects the container unless the image sets a numeric UID.
- Pin the base tag to a version. `FROM ubuntu:latest` is the flagged line in almost every seeded Dockerfile.
- Deleting a secret in a later layer does not remove it. It is still in the earlier layer, and `podman history` shows the instruction that added it. Move secrets out of the Dockerfile rather than adding a cleanup `RUN`. `ADD` with a remote URL is the same class of problem: it fetches unverified content at build time, so use `COPY`.
- Docker is not assumed present on exam hosts. `podman` takes the same arguments for `build`, `run`, `images` and `inspect`.

**Docs.** None allowed: memorise. On the task host, `man podman-build` and `podman build --help`.

## Recipe 2: Find the issues in a Dockerfile and a manifest

**Goal.** Exactly the number of issues the task names are fixed in the given files, by changing existing settings, and nothing else in the files has moved.
**Frequency.** 8 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q15, Q27.
**Commands.**
```bash
cp -r /opt/course/27/files /opt/course/27/files.bak    # so a wrong edit is reversible
cat /opt/course/27/files/Dockerfile ; cat /opt/course/27/files/deployment.yaml

# fast sweep for the usual suspects
grep -nE 'FROM .*:latest|^USER +root|^ADD +https?://|ENV .*(PASS|SECRET|TOKEN|KEY)' /opt/course/27/files/Dockerfile
grep -nE 'privileged|hostNetwork|hostPID|hostIPC|allowPrivilegeEscalation|runAsUser: 0|hostPath' /opt/course/27/files/deployment.yaml
```

What to look for, and what the fix looks like:

| Where | Red flag | Fix |
|---|---|---|
| Dockerfile | `FROM ubuntu:latest` or an end-of-life base | pin a supported version tag |
| Dockerfile | `USER root`, or no `USER` at all | `USER 1001` after the last privileged `RUN` |
| Dockerfile | `ADD https://...` | `COPY` a local, verified file |
| Dockerfile | `apt-get install` with no `--no-install-recommends` | add the flag, `rm -rf /var/lib/apt/lists/*` in the same layer |
| Dockerfile | `ENV DB_PASSWORD=...`, `COPY id_rsa` | remove it, take the value from a Secret at runtime |
| Manifest | `privileged: true`, `allowPrivilegeEscalation: true` | `false` |
| Manifest | `hostNetwork: true`, `hostPID: true`, `hostIPC: true` | `false`, or delete the field |
| Manifest | missing `runAsNonRoot`, or `runAsUser: 0` | `runAsNonRoot: true` and a non-zero `runAsUser` |
| Manifest | `capabilities.add` with `SYS_ADMIN` or `NET_RAW` | drop it, keep only what the task allows |
| Manifest | plaintext credentials in `env[].value` | `valueFrom.secretKeyRef` |
| Manifest | `hostPath` mount of `/`, `/var/run/docker.sock` or `/etc` | remove the mount |
| Manifest | `image: nginx:latest` | pin a tag or a digest |

**The rule that decides the point: change only what the task asks.** The reported phrasing is "only modify existing configuration settings, not add or remove". If the task says two instructions in the Dockerfile and two fields in the manifest, make exactly four edits. Tidying the rest of the file loses marks even when the tidying is correct.
**Verify.**
```bash
diff -u /opt/course/27/files.bak/Dockerfile /opt/course/27/files/Dockerfile
diff -u /opt/course/27/files.bak/deployment.yaml /opt/course/27/files/deployment.yaml
yq '.spec.template.spec.containers[0].securityContext' /opt/course/27/files/deployment.yaml
kubectl apply --dry-run=server -f /opt/course/27/files/deployment.yaml
```
**Gotchas.**
- Count the diff hunks against the number of issues the task states. More hunks than issues means marks are being given away.
- Some tasks ask for the filenames that contain credential exposure to be written to a file rather than fixed. Read the deliverable sentence twice before editing anything.
- `privileged: true` overrides everything else, so a manifest that drops all capabilities but stays privileged is still wrong. It and `allowPrivilegeEscalation` are container level only: moving either to `spec.securityContext` makes the API server reject the manifest.
- Fixing the manifest on disk is not the same as fixing the cluster. If the task also says apply it, apply it, and confirm the new pod is Running.

**Docs.** kubernetes.io: "Configure a Security Context for a Pod or Container", "Pod Security Standards". For Dockerfile syntax, none allowed: memorise.

## Recipe 3: Trivy scan of the images running in a namespace

**Goal.** Every image used by pods in a named namespace has been scanned, and the pods on images with HIGH or CRITICAL findings have been dealt with exactly as the task words it.
**Frequency.** 9 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q13.
**Commands.**
```bash
# 1. list every image in the namespace, one line per pod, no jq needed
kubectl get pods -n kamino -o custom-columns='POD:.metadata.name,IMG:.spec.containers[*].image'

# init containers count too when the task says "all containers"
kubectl get pods -n kamino -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\t"}{.spec.initContainers[*].image}{"\n"}{end}'

# 2. scan. Start this in a second terminal, the first scan pulls the CVE database
trivy image --severity HIGH,CRITICAL nginx:1.19
trivy image --severity CRITICAL --ignore-unfixed nginx:1.19
trivy image -q --severity HIGH,CRITICAL -f json -o /opt/course/13/report.json nginx:1.19

# 3. act on the result, in the form the task asks for
kubectl delete pod web-1 -n kamino
kubectl scale deploy web -n kamino --replicas=0
kubectl set image deploy/web web=nginx:1.27.4 -n kamino
echo "nginx:1.19" >> /opt/course/13/vulnerable-images

# other scan targets that show up
trivy config /opt/course/13/deployment.yaml     # manifest misconfiguration
trivy fs --severity HIGH,CRITICAL /opt/course/13/app
trivy image --input /opt/course/13/app.tar      # image saved as a tar
```
**Verify.**
```bash
kubectl get pods -n kamino -o custom-columns='POD:.metadata.name,IMG:.spec.containers[*].image'
yq -p json '.Results[].Vulnerabilities[].VulnerabilityID' /opt/course/13/report.json | head
```
**Gotchas.**
- Scans are slow and the database download is slower. Start the scan in a second terminal and read the manifest while it runs.
- Read the deliverable. Delete the pod, scale the deployment to zero, replace the image and write the image name to a file are four different answers, and only one of them scores.
- Deleting a pod owned by a Deployment recreates it on the same bad image. Scale or patch the controller instead.
- `--severity` takes a comma list with no spaces, and the values are uppercase. `--ignore-unfixed` is only correct when the task says fixable or remediable.
- The `-o` flag writes to a file, the `-f` flag chooses the format. Both are needed for a JSON report at a required path, and there is no `jq` to read it back, so use `yq -p json`.
- Pods can carry more than one container plus init containers. A `custom-columns` on `.spec.containers[*].image` alone misses the init containers.

**Docs.** None allowed: memorise. Trivy documentation is outside the allowed set. On the task host, `trivy --help` and `trivy image --help`.

## Recipe 4: kubesec and kube-linter on a manifest

**Goal.** A pod or deployment manifest scores clean on the checks the task names, with the flagged securityContext fields corrected in the file.
**Frequency.** 5 candidate sources for the SBOM, kubesec and kube-linter family, 8 for manifest static analysis (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q15.
**Commands.**
```bash
# kubesec scores a single manifest and lists what would raise the score
kubesec scan /opt/course/15/pod.yaml
cat /opt/course/15/pod.yaml | kubesec scan /dev/stdin

# the output is JSON, and there is no jq
kubesec scan /opt/course/15/pod.yaml | yq -p json '.[0].score'
kubesec scan /opt/course/15/pod.yaml | yq -p json '.[0].scoring.advise[].selector'

# kube-linter checks against built-in best-practice rules
kube-linter lint /opt/course/15/deployment.yaml
kube-linter lint --include run-as-non-root,privileged-container /opt/course/15/deployment.yaml
```

The fields kubesec rewards, which are also the fields these tasks seed as wrong:

```yaml
spec:
  securityContext: {runAsNonRoot: true, runAsUser: 10001}
  containers:
  - name: c1
    image: nginx:1.27.4
    securityContext:
      privileged: false
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities: {drop: ["ALL"]}
    resources: {limits: {cpu: "500m", memory: "256Mi"}}
```
**Verify.**
```bash
kubesec scan /opt/course/15/pod.yaml | yq -p json '.[0].score'              # higher than before
kubesec scan /opt/course/15/pod.yaml | yq -p json '.[0].scoring.critical'   # null
kube-linter lint /opt/course/15/deployment.yaml                            # No lint errors found
```
**Gotchas.**
- kubesec returns a JSON array, so the score is at `.[0].score` and not at `.score`. Piping through `yq -p json` is the only way to read it cleanly without `jq`.
- A kubesec score can be positive while a critical item is still open. Clear `scoring.critical` first, then work down `scoring.advise`.
- kubesec scans one resource at a time, so a multi-document file needs splitting.
- `readOnlyRootFilesystem: true` breaks nginx until `/tmp`, `/var/cache/nginx` and `/var/run` have `emptyDir` mounts. Fix the manifest so the pod still runs, not just so the scanner is happy.
- Apply the same "change only what the task asks" rule from Recipe 2. A higher score on fields the task never mentioned is not the deliverable.

**Docs.** None allowed: memorise. Neither kubesec.io nor the KubeLinter documentation is on the allowed list.

## Recipe 5: Generate and query an SBOM with bom

**Goal.** An SPDX SBOM for a named image or directory exists at the path the task gives, in the format the task names, and a question about a specific package can be answered from it.
**Frequency.** 5 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q38.
**Commands.**
```bash
# image SBOM, SPDX tag-value by default, JSON when the task asks for it
bom generate --image registry.k8s.io/kube-apiserver:v1.35.0 -o /opt/course/38/sbom.spdx
bom generate --image registry.k8s.io/kube-apiserver:v1.35.0 \
  --format json -o /opt/course/38/sbom.json

# directory SBOM
bom generate -n https://example.com/app -d /opt/course/38/src -o /opt/course/38/src.spdx

# read it back
bom document outline /opt/course/38/sbom.json
bom document query /opt/course/38/sbom.json 'purl:pkg:apk/*'

# the other two tools, when they are installed
syft nginx:1.27.4 -o cyclonedx-json > /opt/course/38/sbom.cdx.json ; grype sbom:/opt/course/38/sbom.json
```
**Verify.**
```bash
head -20 /opt/course/38/sbom.spdx                     # SPDXVersion, DataLicense, DocumentName
yq -p json '.spdxVersion' /opt/course/38/sbom.json    # SPDX-2.3
yq -p json '.packages | length' /opt/course/38/sbom.json
```
**Gotchas.**
- Two formats show up in tasks, SPDX and CycloneDX. `bom` speaks SPDX only. If the task says CycloneDX, the tool is `syft` with `-o cyclonedx-json`.
- `bom generate` needs one of `--image`, `-d` for a directory or `-f` for a file. With none of them it prints help and writes nothing.
- The `-o` path is created, not appended. Check the exact filename the task gives, including the extension, because the grader looks for that path. Without `--format json` the output is SPDX tag-value text, which `yq` cannot parse.
- An SBOM is an inventory, not a vulnerability report. Feeding it to `grype sbom:<file>` is what turns it into findings.

**Docs.** https://kubernetes-sigs.github.io/bom/cli-reference/ is on the allowed list. Use it for `bom generate` and `bom document query` syntax. syft and grype documentation is not allowed.

## Recipe 6: Sign, verify and pin images by digest

**Goal.** An image reference in a running workload is pinned to an immutable digest, and a signed image can be verified against a public key.
**Frequency.** 1 candidate source (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Killercoda ships it as "Image Use Digest". The curriculum bullet says sign and validate artifacts, so learn the handful of commands and move on. Drill: Killercoda "Image Use Digest".
**Commands.**
```bash
# signing side
cosign generate-key-pair
cosign sign --key cosign.key registry.internal/app:1.0.0 ; cosign verify --key cosign.pub registry.internal/app:1.0.0

# find the digest of what is actually running
kubectl get pods -n prod -o custom-columns='POD:.metadata.name,IMGID:.status.containerStatuses[*].imageID'
crictl images --digests
podman inspect nginx:1.27.4 --format '{{index .RepoDigests 0}}'

# pin the workload to the digest
kubectl set image deploy/web -n prod \
  web=nginx@sha256:0f1e2d3c4b5a69788796a5b4c3d2e1f00112233445566778899aabbccddeeff00
```
**Verify.**
```bash
kubectl get deploy web -n prod -o jsonpath='{.spec.template.spec.containers[*].image}{"\n"}'
kubectl rollout status deploy/web -n prod
cosign verify --key cosign.pub registry.internal/app:1.0.0 && echo signature-ok
```
**Gotchas.**
- A digest reference drops the tag. Write `nginx@sha256:...`, not `nginx:1.27.4@sha256:...`, when the task asks for a digest only.
- `.spec.containers[].image` is what was requested, `.status.containerStatuses[].imageID` is what actually runs. Read the status field when asked what is running.
- `imageID` is often prefixed with the registry host and `docker-pullable://`. Compare the hex after `sha256:`, not the whole string.
- A digest pin makes `imagePullPolicy` almost irrelevant, since the digest cannot move. A tag pin does not, which is why the tag form usually also needs `imagePullPolicy: Always`.
- `cosign verify` needs the public key file, not the private one, and a failure prints a non-zero exit with no signature list. Sigstore documentation is not on the allowed list, and this is a one-source task type, so spend the memorisation budget on Recipe 7 instead.

**Docs.** None allowed: memorise. On the task host, `cosign --help`.

## Recipe 7: ImagePolicyWebhook end to end

**Goal.** The API server calls an existing webhook backend for every pod image, fails closed when the backend is unreachable, and a pod using a forbidden image is denied at admission while the cluster stays up.
**Frequency.** 12 candidate sources (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q14, Q21.

There are three moving parts and they point at each other in one chain. Break any link and the API server does not start.

```
--admission-control-config-file -> admission-config.yaml
  imagePolicy.kubeConfigFile    -> admission-kubeconfig.yaml
    clusters[0].cluster.server  -> the backend Service
```

**Commands.**
```bash
ssh cks-controlplane
sudo -i

# 0. BACK UP FIRST. This is the step that makes a mistake survivable.
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak
ls /etc/kubernetes/admission-controllers/   # skeletons are usually pre-created
```

Part 1, the admission configuration file:

```bash
cat > /etc/kubernetes/admission-controllers/admission-config.yaml <<'EOF'
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/admission-controllers/admission-kubeconfig.yaml
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: false
EOF
```

Part 2, the webhook kubeconfig. `clusters[0].cluster` needs **both** `certificate-authority` and `server`:

```bash
cat > /etc/kubernetes/admission-controllers/admission-kubeconfig.yaml <<'EOF'
apiVersion: v1
kind: Config
clusters:
- name: image-bouncer-webhook
  cluster:
    certificate-authority: /etc/kubernetes/admission-controllers/webhook.crt
    server: https://image-bouncer.default.svc:1323/image_policy
contexts:
- name: image-bouncer-webhook
  context: {cluster: image-bouncer-webhook, user: api-server}
current-context: image-bouncer-webhook
users:
- name: api-server
  user:
    client-certificate: /etc/kubernetes/admission-controllers/apiserver-client.crt
    client-key: /etc/kubernetes/admission-controllers/apiserver-client.key
EOF
```

Part 3, the API server manifest, edited in place with `vim`. Two flags, one volume, one volumeMount:

```yaml
spec:
  containers:
  - command:
    - kube-apiserver
    - --enable-admission-plugins=NodeRestriction,ImagePolicyWebhook
    - --admission-control-config-file=/etc/kubernetes/admission-controllers/admission-config.yaml
    volumeMounts:
    - name: admission-controllers
      mountPath: /etc/kubernetes/admission-controllers
      readOnly: true
  volumes:
  - name: admission-controllers
    hostPath:
      path: /etc/kubernetes/admission-controllers
      type: DirectoryOrCreate
```

Watch the restart from a second terminal the moment the file is saved:

```bash
watch crictl ps
```
**Verify.**
```bash
# the API server came back
crictl ps | grep kube-apiserver ; curl -m 3 -k https://127.0.0.1:6443/readyz
grep -E 'admission-control-config-file|enable-admission-plugins' /etc/kubernetes/manifests/kube-apiserver.yaml

# admission actually denies: expect "Forbidden: image policy webhook backend denied one or more images"
kubectl run test --image=nginx:latest
kubectl run allowed --image=nginx:1.27.4 && kubectl get pod allowed
```

Recovery when the API server does not come back:

```bash
crictl logs $(crictl ps -a --name kube-apiserver -q | head -1) 2>&1 | tail -30
ls -t /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/ | head -1   # then read that log
journalctl -fu kubelet | grep -i apiserver
cp /root/kube-apiserver.yaml.bak /etc/kubernetes/manifests/kube-apiserver.yaml   # last resort
```
**Gotchas.**
- **A missing `server:` line in the webhook kubeconfig is the reported cause of a failed exam.** The API server starts, cannot reach a backend it was never told about, and with `defaultAllow: false` it rejects everything, including its own bootstrapping traffic. Write `certificate-authority` and `server` together, every time.
- Misspelling the plugin name in `--enable-admission-plugins` is the second reported failure. The API server exits immediately with an unknown plugin error. The name is `ImagePolicyWebhook`, capital I, capital P, capital W.
- `--enable-admission-plugins` is a comma list. Append `ImagePolicyWebhook` to the plugins already listed rather than overwriting the line.
- Without the volume and volumeMount, the API server container cannot see the configuration file, and `--admission-control-config-file` points at a path that does not exist inside the container. Mount the directory, not the file, and keep the host path and the mount path identical so the paths inside both YAML files stay correct.
- `defaultAllow: false` fails closed. It is what the task asks for, and it is also what makes every mistake fatal. Set it last, after the chain has been proven with a reachable backend.
- Back up `/etc/kubernetes/manifests/kube-apiserver.yaml` before the first keystroke. The kubelet rescans the manifest directory roughly every 20 seconds, so a save is a restart with no confirmation prompt.
- Moving the manifest out of `/etc/kubernetes/manifests/` stops the API server. Edit it in place and keep the backup in `/root`, outside that directory.
- Indentation errors kill the API server just as effectively as a wrong flag. Set `sw=2 et ts=2` in vim before editing.
- The backend Service already exists in these tasks. Do not create or redeploy it, and do not change its port. The value belongs in the kubeconfig `server` URL, path included.

**Docs.** kubernetes.io: "Using Admission Controllers" (the ImagePolicyWebhook section carries the AdmissionConfiguration and kubeconfig examples), "Admission Control in Kubernetes".

## Recipe 8: Restrict which registries may run

**Goal.** Pods referencing an image outside the permitted registries are rejected at admission, and existing compliant workloads keep running.
**Frequency.** 5 candidate sources for Gatekeeper constraint edits (see ../practice-tests/exam-questions/cks-real-exam-questions.md). Drill: Q11.
**Commands.**
```bash
# what is installed decides the answer. Never install a policy engine in the exam.
kubectl get crd | grep -E 'gatekeeper|kyverno'
kubectl get constrainttemplates ; kubectl get constraints ; kubectl get clusterpolicy
```

Gatekeeper, when a ConstraintTemplate is already present, only the Constraint changes. Read it with `kubectl get constrainttemplate k8sallowedrepos -o yaml`, then `kubectl edit k8sallowedrepos allowed-repos`:

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: allowed-repos
spec:
  enforcementAction: deny
  match:
    kinds:
    - {apiGroups: [""], kinds: ["Pod"]}
    namespaces: ["prod"]
  parameters:
    repos: ["registry.internal/"]
```

Kyverno, when Kyverno is the engine present:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: allowed-registries
spec:
  validationFailureAction: Enforce
  rules:
  - name: only-internal-registry
    match:
      any:
      - resources: {kinds: ["Pod"]}
    validate:
      message: "images must come from registry.internal"
      pattern:
        spec:
          containers:
          - image: "registry.internal/*"
```

Tag-based pulls also need `imagePullPolicy: Always` on the container so a moved tag is refetched.
**Verify.**
```bash
kubectl run bad --image=docker.io/nginx:1.27.4       # expected: rejected at admission
kubectl run good --image=registry.internal/app:1.0.0 && kubectl get pod good
kubectl get k8sallowedrepos allowed-repos -o jsonpath='{.status.totalViolations}{"\n"}'
```
**Gotchas.**
- Find out which engine is installed before writing anything. Gatekeeper and Kyverno answer the same question with completely different YAML, and installing the other one is never the task.
- Gatekeeper needs a ConstraintTemplate and a Constraint. The template is pre-created in these tasks, so edit the Constraint only.
- `enforcementAction: dryrun` records violations without blocking. If a task says enforce, the value is `deny`. Kyverno's equivalent is `validationFailureAction: Enforce`, capitalised, against `Audit` for report only.
- Admission policies apply to new pods, so the verification step has to create a pod rather than list them. The repo prefix usually needs the trailing slash: `registry.internal` without it also matches `registry.internal.evil.com`.
- Pod Security Admission, Gatekeeper and Kyverno mechanics are covered in [04-microservice-vulnerabilities.md](04-microservice-vulnerabilities.md).

**Docs.** kubernetes.io: "Admission Control in Kubernetes", "Validating Admission Policy". Gatekeeper and Kyverno documentation is not allowed, so read the installed ConstraintTemplate or ClusterPolicy in the cluster instead.

## Quick reference

```bash
# images running in a namespace, no jq
kubectl get pods -n <ns> -o custom-columns='POD:.metadata.name,IMG:.spec.containers[*].image'
kubectl get pods -n <ns> -o jsonpath='{.items[*].status.containerStatuses[*].imageID}{"\n"}'

# trivy
trivy image --severity HIGH,CRITICAL <img> ; trivy image --severity CRITICAL --ignore-unfixed <img>
trivy image -q --severity HIGH,CRITICAL -f json -o /opt/course/<n>/report.json <img>
trivy config <manifest>.yaml ; trivy fs <dir> ; trivy image --input <img>.tar

# kubesec, kube-linter and sbom
kubesec scan pod.yaml | yq -p json '.[0].score'
kubesec scan pod.yaml | yq -p json '.[0].scoring.advise[].selector' ; kube-linter lint deployment.yaml
bom generate --image <img> --format json -o sbom.json
bom document outline sbom.json ; bom document query sbom.json 'purl:pkg:apk/*'
syft <img> -o cyclonedx-json > sbom.cdx.json ; grype sbom:sbom.json

# build, inspect and sign, no docker
podman build -t app:1.0.0 . ; podman run --rm app:1.0.0 id ; crictl images --digests
podman inspect app:1.0.0 --format '{{.Config.User}}'
cosign sign --key cosign.key <img> ; cosign verify --key cosign.pub <img>
kubectl set image deploy/<name> <c>=<repo>@sha256:<digest> -n <ns>

# imagepolicywebhook, the three pieces
/etc/kubernetes/admission-controllers/admission-config.yaml      # AdmissionConfiguration
/etc/kubernetes/admission-controllers/admission-kubeconfig.yaml  # certificate-authority AND server
/etc/kubernetes/manifests/kube-apiserver.yaml                    # 2 flags + volume + volumeMount
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver.yaml.bak
watch crictl ps ; curl -m 3 -k https://127.0.0.1:6443/readyz

# registry restriction
kubectl get crd | grep -E 'gatekeeper|kyverno' ; kubectl get constraints ; kubectl get clusterpolicy
```

## Memorise

- ImagePolicyWebhook is a chain of three files. The API server flag names the admission configuration, `imagePolicy.kubeConfigFile` names the webhook kubeconfig, and `clusters[0].cluster.server` names the backend. Every link has to be written by hand.
- The webhook kubeconfig needs **both** `certificate-authority` and `server` under `clusters[0].cluster`. A missing `server:` line is the single most reported way to kill the API server on this exam.
- The AdmissionConfiguration fields in order: `kubeConfigFile`, `allowTTL: 50`, `denyTTL: 50`, `retryBackoff: 500`, `defaultAllow: false`. `defaultAllow: false` fails closed and is what the task asks for.
- The API server needs two flags, `--admission-control-config-file=<path>` and `ImagePolicyWebhook` appended to `--enable-admission-plugins`, plus a hostPath volume and a volumeMount for the config directory. Four edits, not two.
- Back up `/etc/kubernetes/manifests/kube-apiserver.yaml` to `/root` before touching it, and keep `watch crictl ps` running in a second terminal. The kubelet rescans the directory roughly every 20 seconds.
- Trivy: `--severity HIGH,CRITICAL`, `--ignore-unfixed` for fixable only, `-f json -o <path>` for a report. Trivy, kubesec and kube-linter documentation is not allowed, so `trivy --help` is the only fallback. Read the deliverable before acting: delete the pod, scale the deployment, replace the image and write the image name to a file are four different answers.
- kubesec returns a JSON array. The score is at `.[0].score`, read it with `yq -p json` because there is no `jq`.
- `bom generate --image <img> --format json -o <path>` produces SPDX. CycloneDX needs syft. The bom CLI reference at kubernetes-sigs.github.io/bom is the only tooling page allowed for this domain.
- Static analysis rule: change exactly the number of things the task names, and nothing else, then `diff` the file against a copy before moving on.
- Dockerfile red flags: `:latest`, `USER root` or no `USER`, `ADD` of a remote URL, credentials in `ENV`, and a package manager left in the final stage. Manifest red flags: `privileged`, `hostNetwork`, `hostPID`, `allowPrivilegeEscalation`, missing `runAsNonRoot`, secrets in `env[].value`.
- A digest reference replaces the tag: `nginx@sha256:...`. `.spec.containers[].image` is what was requested, `.status.containerStatuses[].imageID` is what runs.
- Never install a policy engine. Check which CRDs exist, then edit the Gatekeeper Constraint or the Kyverno ClusterPolicy that is already there. Build with `podman` and inspect running containers with `crictl`, because a Docker CLI is not assumed present.
