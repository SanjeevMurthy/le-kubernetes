# Q17. API Server Audit Logging Policy (solution)

**Concept & Explanation:**

An audit Policy lists rules evaluated **first-match-wins**, each with a `level`. You wire the policy and log path into the apiserver via flags plus hostPath volume mounts (the policy is file-backed and the log dir must be writable).

**Solution — Step by Step:**

```yaml
# /etc/kubernetes/audit/policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  resources: [{group: "", resources: ["secrets"]}]
- level: None
  verbs: ["get", "watch", "list"]
- level: Metadata
```
```yaml
# kube-apiserver.yaml (back up first) — flags + mounts:
    - --audit-policy-file=/etc/kubernetes/audit/policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit/audit.log
    - --audit-log-maxage=7
    volumeMounts:
    - {name: audit-policy, mountPath: /etc/kubernetes/audit, readOnly: true}
    - {name: audit-logs,   mountPath: /var/log/kubernetes/audit}
  volumes:
  - {name: audit-policy, hostPath: {path: /etc/kubernetes/audit, type: DirectoryOrCreate}}
  - {name: audit-logs,   hostPath: {path: /var/log/kubernetes/audit, type: DirectoryOrCreate}}
```
```bash
sudo crictl ps | grep apiserver
# no jq in the exam: grep the raw JSON lines instead
kubectl get secrets -A >/dev/null
sudo grep '"resource":"secrets"' /var/log/kubernetes/audit/audit.log | tail -1
```

**Key Points to Remember:**

- **First match wins** — the Secret `RequestResponse` rule and the `None` read rule must come **before** the catch-all `Metadata`.
- Forgetting the `volumes`/`volumeMounts` (or a wrong path) breaks the apiserver — back up and verify `/readyz`.
- Confirm the log file is actually growing.

**Official Documentation:**
- https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/

---
