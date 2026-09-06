# Q13. Scan Images with Trivy and Remediate

Deployment `web` in namespace `prod` runs `nginx:1.18.0`. Use Trivy to confirm it has HIGH/CRITICAL vulnerabilities, then update the deployment to a patched image (`nginx:1.27.0`) that has no CRITICALs. Confirm the rollout.
