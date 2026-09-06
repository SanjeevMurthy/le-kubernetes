# Q13. Scan Images with Trivy and Remediate (solution)

**Concept & Explanation:**

Trivy scans container images for known CVEs in OS packages and language libraries. The exam pattern is: scan, identify the vulnerable image actually running, replace it with a clean tag, verify the rollout. Trivy docs are not allowed in the exam, so the flags have to be memorised.

**Solution — Step by Step:**

```bash
# 1. Find the image that is actually running
kubectl get deploy web -n trivy-lab -o jsonpath='{.spec.template.spec.containers[*].image}{"\n"}'

# 2. Scan it and save the report deliverable
trivy image --severity HIGH,CRITICAL nginx:1.18.0 > /opt/course/13/report.txt
grep -c CRITICAL /opt/course/13/report.txt

# 3. Confirm the replacement is clean of criticals
trivy image --severity CRITICAL nginx:1.27.0

# 4. Roll the deployment onto the patched image
kubectl set image deploy/web nginx=nginx:1.27.0 -n trivy-lab
kubectl rollout status deploy/web -n trivy-lab
```

**Key Points to Remember:**

- `--severity HIGH,CRITICAL` focuses the scan; `--ignore-unfixed` shows only the CVEs you can actually patch.
- `kubectl set image deploy/<name> <container>=<image>` needs the **container** name, which `kubectl create deployment` sets to the image's base name (`nginx` here).
- The deliverable is both the report file and a clean image **running**: check the new pod is Ready on the new tag.
- Audit every image in the cluster with
  `kubectl get pods -A -o custom-columns=NS:.metadata.namespace,IMG:.spec.containers[*].image`.

**Official Documentation:**
- https://aquasecurity.github.io/trivy/ (not allowed in-exam; memorise the flags)

---
