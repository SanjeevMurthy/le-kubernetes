# Q13. Scan Images with Trivy and Remediate (solution)

## Steps

Trivy scans are slow, minutes rather than seconds on a first run while the vulnerability database downloads. Start the scan, and read the rest of the question while it runs.

**1. Find what is actually running.** Do not scan the image the question names; scan the image the workload uses. They can differ, and in questions that ask about a whole namespace this step is most of the work.

```bash
kubectl -n trivy-lab get deploy web \
  -o jsonpath='{.spec.template.spec.containers[*].image}{"\n"}'
```

For a whole namespace at once:

```bash
kubectl -n trivy-lab get pods \
  -o custom-columns='POD:.metadata.name,IMAGE:.spec.containers[*].image' --no-headers
```

**2. Scan, filtered to the severities asked for, and save the report.**

```bash
trivy image --severity HIGH,CRITICAL nginx:1.18.0 | tee /opt/course/13/report.txt
```

`--severity HIGH,CRITICAL` is comma-separated with no spaces, and the names are uppercase. Leaving it off produces thousands of lines of LOW and MEDIUM noise that buries the answer.

Two flags worth knowing when the clock is running:

```bash
trivy image --severity CRITICAL --quiet --scanners vuln nginx:1.18.0
```

`--quiet` drops the progress bar, and `--scanners vuln` skips the secret and misconfiguration scanners, which is a large speedup when the question only asks about CVEs.

**3. Confirm the report is not empty** before moving on. A scan that failed to pull the image writes a perfectly plausible empty file.

```bash
wc -l /opt/course/13/report.txt
grep -c CRITICAL /opt/course/13/report.txt
```

**4. Patch the deployment.**

```bash
kubectl -n trivy-lab set image deployment/web nginx=nginx:1.27.0
```

`set image` takes `<container-name>=<image>`. Get the container name from the output of step 1 rather than assuming it matches the deployment.

**5. Wait for the rollout, and confirm.** A `set image` that was accepted and a rollout that completed are different things; a bad image name gives you the first without the second.

```bash
kubectl -n trivy-lab rollout status deployment/web --timeout=120s
kubectl -n trivy-lab get pods -o wide
kubectl -n trivy-lab get deploy web -o jsonpath='{.spec.template.spec.containers[*].image}{"\n"}'
```

**6. Re-scan to show the remediation worked,** which is the half that makes it remediation rather than an upgrade.

```bash
trivy image --severity CRITICAL --quiet nginx:1.27.0
```

## When the question says "delete the vulnerable Pods"

A common variant scans every image in a namespace and asks you to remove the workloads using a bad one. The trap is what to delete: deleting a Pod owned by a Deployment achieves nothing, because the ReplicaSet recreates it within seconds.

```bash
# find the owner before deleting anything
kubectl -n <ns> get pod <pod> -o jsonpath='{.metadata.ownerReferences[*].kind}{"\n"}'
```

If it is owned, delete the Deployment. If it is a bare Pod, delete the Pod. And read the question once more: some versions want the image name written to a file and nothing deleted at all.

## Gotchas

- Scan the running image, not the one in the question text.
- `--severity` values are uppercase and comma-separated, no spaces.
- The first scan downloads a vulnerability database. On a slow link use `--offline-scan`, or accept the wait and do something else meanwhile.
- `trivy image` scans an image. `trivy fs` scans a directory and `trivy config` scans manifests; using the wrong subcommand produces a clean report that means nothing.
- `tee` rather than `>` if you also want to read the output. A silent redirect while you wait tells you nothing about whether it worked.
- Check the report is non-empty. An image that could not be pulled yields an empty report and no obvious error.
- Trivy's documentation is **not** on the exam's allowed list. `trivy image --help` on the host is the only reference you get, so the flags above are memorise material.

## Docs

No allowed domain covers Trivy. What is allowed covers the Kubernetes side of the remediation.

- `trivy image --help` and `trivy --help` on the exam host
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment for `set image` and `rollout status`
