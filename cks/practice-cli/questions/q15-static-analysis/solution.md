# Q15. Static Analysis & Manifest Hardening (kubesec) (solution)

## Steps

Both the file and the live Deployment are graded, so the last step is not optional.

**1. Scan the manifest as it stands.** kubesec reads a manifest and returns a score with the advice that would raise it.

```bash
cd /opt/course/15
kubesec scan deploy.yaml
```

```json
[
  {
    "object": "Deployment/app.appsec",
    "valid": true,
    "score": 0,
    "scoring": {
      "advise": [
        {"id": "ReadOnlyRootFilesystem", "points": 1},
        {"id": "RunAsNonRoot", "points": 1},
        {"id": "AllowPrivilegeEscalation", "points": 1},
        ...
      ]
    }
  }
]
```

The `advise` list is the task written out for you. Each `id` names the field to add, and the `score` is what moves when you add it. There is no `jq` in the exam, so if the JSON is hard to read:

```bash
kubesec scan deploy.yaml | yq -P '.[0].scoring.advise[].id'
kubesec scan deploy.yaml | yq -P '.[0].score'
```

**2. Harden the manifest.** The four fields the task names, in the two places they belong.

```bash
vi deploy.yaml
```

```yaml
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
      containers:
      - name: app
        image: ...
        securityContext:
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]
```

`runAsNonRoot` and `runAsUser` are Pod-level here; `readOnlyRootFilesystem`, `allowPrivilegeEscalation` and `capabilities` are container-level and have no Pod-level equivalent. That split is the single most useful thing to have memorised in this family of questions, because putting a container-level field under the Pod's `securityContext` is accepted by the API server and silently does nothing.

`runAsNonRoot: true` on its own makes the kubelet refuse to start a container whose image runs as UID 0; it does not change the user. Adding `runAsUser` is what actually picks one.

**3. Re-scan and confirm the score moved.**

```bash
kubesec scan deploy.yaml | yq -P '.[0].score'
```

**4. Reapply, and check the live object took it.** The file scoring well is half the answer.

```bash
kubectl apply -f deploy.yaml
kubectl -n appsec rollout status deployment/app --timeout=120s

kubectl -n appsec get deploy app -o jsonpath='{.spec.template.spec.containers[0].securityContext}{"\n"}'
```

**5. Watch for a Pod that will not start.** Hardening a workload that was not written for it is the usual outcome, and it is a real result rather than a mistake in your answer.

```bash
kubectl -n appsec get pods
kubectl -n appsec describe pod -l app=app | tail -20
```

`CreateContainerConfigError` with `container has runAsNonRoot and image will run as root` means the image genuinely needs a UID; `runAsUser` fixes it. A crash loop after `readOnlyRootFilesystem: true` means the process needs a writable path, which is Q18's territory: mount an `emptyDir` where it writes.

## Which field does what

| Field | Level | What it stops |
|---|---|---|
| `runAsNonRoot: true` | Pod or container | the container starting at all if the image is UID 0 |
| `runAsUser: <n>` | Pod or container | picks the UID rather than only refusing root |
| `readOnlyRootFilesystem: true` | container only | writes anywhere except mounted volumes |
| `allowPrivilegeEscalation: false` | container only | `setuid` binaries and `CAP_SYS_ADMIN` gaining more than the parent |
| `capabilities.drop: ["ALL"]` | container only | every Linux capability, added back one at a time with `add` |
| `privileged: true` | container only | (the opposite: this one grants everything, and is never a correct answer) |

These same four fields are what `restricted` Pod Security Admission demands, which is why Q9 and this question reinforce each other. Passing kubesec and passing PSA are largely the same exercise.

## Gotchas

- Container-level fields under the Pod's `securityContext` are accepted and ignored. Nothing warns you.
- `capabilities` has no Pod-level form at all.
- `drop: ["ALL"]` in capitals. `all` is not the same string.
- The graded artefacts are the file **and** the cluster. Hardening the file without reapplying it fails half the checks.
- kubesec reports on the manifest you give it. Scanning a file you have not saved reports the old score, which reads as the edit having no effect.
- kubesec's and kube-linter's documentation is **not** allowed in the exam. `kubesec scan <file>` and the `advise` list are memorise material, and the tool's own output is the only reference you get.
- There is no `jq` in the exam. `yq -P` reads JSON perfectly well and is present.

## Docs

`kubernetes.io/docs` is allowed and documents every field above, which is what you actually need; the tools themselves are not documented anywhere you can reach.

- https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
- https://kubernetes.io/docs/concepts/security/pod-security-standards/ for the same fields expressed as a standard
- `kubesec scan --help` on the exam host
