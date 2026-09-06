# Q13. Scan Images with Trivy and Remediate

Deployment `web` in namespace `trivy-lab` runs `nginx:1.18.0`.

1. Scan the running image with Trivy for HIGH and CRITICAL vulnerabilities and save the output to `/opt/course/13/report.txt` (the setup output prints the exact directory used on this host).
2. Update deployment `web` to the patched image `nginx:1.27.0`, which has no CRITICALs.
3. Confirm the rollout completes and the new pod is Running.
