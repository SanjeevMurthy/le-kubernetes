# Q15. Static Analysis & Manifest Hardening (kubesec)

A pod manifest `app.yaml` scores poorly on security. Run `kubesec` against it, then harden the manifest so it passes the major checks (no privilege escalation, read-only root FS, drop all capabilities, run as non-root). Re-scan to confirm improvement.
