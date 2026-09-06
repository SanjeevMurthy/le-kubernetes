# Q15. Static Analysis & Manifest Hardening (kubesec)

The manifest `/opt/course/15/deploy.yaml` (the setup output prints the exact directory used on this host) defines Deployment `app` in namespace `appsec` and scores poorly on security. It is already applied to the cluster.

1. Run `kubesec` against the manifest and read the advice it reports.
2. Harden the manifest so its container runs with no privilege escalation, a read-only root filesystem, all capabilities dropped, and as a non-root user.
3. Reapply the hardened manifest, then re-scan it to confirm the score improved. Both the file and the live Deployment are graded.
