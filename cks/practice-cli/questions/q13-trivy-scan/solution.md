# Q13. Scan Images with Trivy and Remediate (solution)

**Concept & Explanation:**

Trivy scans container images for known CVEs in OS packages and libraries. The exam pattern is: scan → identify the vulnerable image actually running → replace it with a clean tag → verify. Trivy docs are NOT allowed in-exam, so the flags must be memorized.

**Solution — Step by Step:**

```bash
# 1. Confirm the current image is vulnerable
trivy image --severity HIGH,CRITICAL nginx:1.18.0

# 2. Confirm the replacement is clean of criticals
trivy image --severity CRITICAL nginx:1.27.0

# 3. Find/replace the running image
kubectl get deploy web -n prod -o jsonpath='{.spec.template.spec.containers[*].image}'
kubectl set image deploy/web web=nginx:1.27.0 -n prod
kubectl rollout status deploy/web -n prod
```

**Key Points to Remember:**

- `--severity HIGH,CRITICAL` focuses the scan; `--ignore-unfixed` shows only patchable CVEs.
- The deliverable is a **clean image running** — verify the new pod is Ready on the new tag.
- Audit all cluster images: `kubectl get pods -A -o=custom-columns=NS:.metadata.namespace,IMG:.spec.containers[*].image`.

**Official Documentation:**
- https://aquasecurity.github.io/trivy/ (not allowed in-exam — memorize flags)

---
