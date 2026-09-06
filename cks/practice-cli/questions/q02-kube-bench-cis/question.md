# Q2. CIS Benchmark Remediation with kube-bench

Run the CIS Kubernetes Benchmark against the control-plane node using `kube-bench`. Identify the FAIL items related to the API server and kubelet, and remediate at least the findings for `--anonymous-auth` and kubelet `--read-only-port`. Re-run to confirm the findings pass.
